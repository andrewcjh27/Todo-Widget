from __future__ import annotations

from typing import Dict, List, Sequence

import pandas as pd
from sklearn.discriminant_analysis import LinearDiscriminantAnalysis
from sklearn.mixture import GaussianMixture
from sklearn.neighbors import NearestNeighbors

from .data import SyntheticSleepConfig, generate_synthetic_sleep_dataset
from .features import select_feature_columns
from .models import (
    evaluate_grouped_classifier,
    make_hist_gb_model,
    make_lda_model,
    mean_and_sem,
    split_group_frame,
)


def _summary_from_result_df(df: pd.DataFrame, metric_col: str = "accuracy") -> Dict[str, object]:
    mean, sem = mean_and_sem(df[metric_col].tolist())
    return {
        "mean_accuracy": mean,
        "sem": sem,
        "n_groups": int(len(df)),
        "per_group": df.to_dict(orient="records"),
    }


def _run_modality_experiments(df: pd.DataFrame, random_seed: int) -> Dict[str, object]:
    region_set = ["BG", "CS", "PG"]
    features_spectral = select_feature_columns(df, feature_family="psd", regions=region_set)
    features_time = select_feature_columns(df, feature_family="time", regions=region_set)

    spectral_df = evaluate_grouped_classifier(
        df=df,
        feature_columns=features_spectral,
        label_column="stage",
        model_factory=lambda: make_hist_gb_model(random_seed),
        random_seed=random_seed,
    )

    time_df = evaluate_grouped_classifier(
        df=df,
        feature_columns=features_time,
        label_column="stage",
        model_factory=lambda: make_hist_gb_model(random_seed),
        random_seed=random_seed,
    )

    return {
        "spectral": _summary_from_result_df(spectral_df),
        "time": _summary_from_result_df(time_df),
    }


def _run_region_experiments(df: pd.DataFrame, random_seed: int) -> Dict[str, object]:
    region_sets: Dict[str, Sequence[str]] = {
        "BG": ["BG"],
        "CS": ["CS"],
        "CTX_BG": ["BG", "CS", "PG"],
    }

    output = {}
    for region_name, regions in region_sets.items():
        result_df = evaluate_grouped_classifier(
            df=df,
            feature_columns=select_feature_columns(df, feature_family="psd", regions=regions),
            label_column="stage",
            model_factory=lambda: make_hist_gb_model(random_seed),
            random_seed=random_seed,
        )
        output[region_name] = _summary_from_result_df(result_df)

    return output


def _run_constrained_nrem_experiments(df: pd.DataFrame, random_seed: int) -> Dict[str, object]:
    region_sets: Dict[str, Sequence[str]] = {
        "BG": ["BG"],
        "CS": ["CS"],
        "CTX_BG": ["BG", "CS", "PG"],
    }

    output = {}
    for region_name, regions in region_sets.items():
        result_df = evaluate_grouped_classifier(
            df=df,
            feature_columns=select_feature_columns(df, feature_family="band", regions=regions),
            label_column="is_nrem",
            model_factory=make_lda_model,
            random_seed=random_seed,
        )
        output[region_name] = _summary_from_result_df(result_df)

    return output


def _outlier_mask(x_train, percentile: float = 97.5):
    # Matches the paper's spirit: remove a small fraction of outlier points before clustering.
    n_neighbors = min(16, len(x_train))
    nn = NearestNeighbors(n_neighbors=n_neighbors)
    nn.fit(x_train)
    distances, _ = nn.kneighbors(x_train)
    mean_distance = distances[:, 1:].mean(axis=1)
    threshold = float(pd.Series(mean_distance).quantile(percentile / 100.0))
    mask = mean_distance <= threshold
    return mask


def _run_unsupervised_nrem_experiment(df: pd.DataFrame, random_seed: int) -> Dict[str, object]:
    feature_columns = select_feature_columns(df, feature_family="band", regions=["BG", "CS", "PG"])
    delta_columns = [col for col in feature_columns if col.endswith("_delta")]
    delta_indices = [feature_columns.index(col) for col in delta_columns]

    rows: List[dict] = []

    for group_id in sorted(df["group_id"].unique().tolist()):
        group_df = df[df["group_id"] == group_id]
        split = split_group_frame(group_df, label_column="is_nrem", random_seed=random_seed)

        x_train = split.train_df[feature_columns].to_numpy()
        y_train = split.train_df["is_nrem"].to_numpy()
        x_test = split.test_df[feature_columns].to_numpy()
        y_test = split.test_df["is_nrem"].to_numpy()

        supervised = LinearDiscriminantAnalysis(solver="lsqr", shrinkage="auto")
        supervised.fit(x_train, y_train)
        supervised_acc = float(supervised.score(x_test, y_test))

        mask = _outlier_mask(x_train)
        x_filtered = x_train[mask]

        gmm = GaussianMixture(n_components=2, random_state=random_seed)
        cluster_ids = gmm.fit_predict(x_filtered)

        # Cluster with higher average delta power is mapped to NREM.
        cluster_zero_delta = x_filtered[cluster_ids == 0][:, delta_indices].mean()
        cluster_one_delta = x_filtered[cluster_ids == 1][:, delta_indices].mean()
        nrem_cluster = 0 if cluster_zero_delta >= cluster_one_delta else 1

        pseudo_labels = (cluster_ids == nrem_cluster).astype(int)
        unsupervised = LinearDiscriminantAnalysis(solver="svd", tol=1e-4)
        unsupervised.fit(x_filtered, pseudo_labels)
        unsupervised_acc = float(unsupervised.score(x_test, y_test))

        rows.append(
            {
                "group_id": group_id,
                "supervised_accuracy": supervised_acc,
                "unsupervised_accuracy": unsupervised_acc,
                "n_train": len(split.train_df),
                "n_test": len(split.test_df),
            }
        )

    result_df = pd.DataFrame(rows)
    supervised_mean, supervised_sem = mean_and_sem(result_df["supervised_accuracy"].tolist())
    unsupervised_mean, unsupervised_sem = mean_and_sem(result_df["unsupervised_accuracy"].tolist())

    return {
        "supervised": {
            "mean_accuracy": supervised_mean,
            "sem": supervised_sem,
        },
        "unsupervised": {
            "mean_accuracy": unsupervised_mean,
            "sem": unsupervised_sem,
        },
        "per_group": result_df.to_dict(orient="records"),
    }


def run_all_experiments(config: SyntheticSleepConfig | None = None) -> Dict[str, object]:
    config = config or SyntheticSleepConfig()
    df = generate_synthetic_sleep_dataset(config)

    report = {
        "dataset": {
            "rows": int(len(df)),
            "groups": int(df["group_id"].nunique()),
            "epochs_per_group": int(config.epochs_per_hemisphere),
            "participants": list(config.participants),
            "hemispheres": list(config.hemispheres),
            "stage_distribution": {
                key: float(value)
                for key, value in df["stage"].value_counts(normalize=True).sort_index().to_dict().items()
            },
        },
        "five_stage_modalities": _run_modality_experiments(df, random_seed=config.random_seed),
        "five_stage_regions": _run_region_experiments(df, random_seed=config.random_seed),
        "constrained_nrem": _run_constrained_nrem_experiments(df, random_seed=config.random_seed),
        "unsupervised_nrem": _run_unsupervised_nrem_experiment(df, random_seed=config.random_seed),
    }
    return report


def _pct(x: float) -> str:
    return f"{x * 100:.1f}%"


def pretty_report(report: Dict[str, object]) -> str:
    ds = report["dataset"]
    m = report["five_stage_modalities"]
    r = report["five_stage_regions"]
    c = report["constrained_nrem"]
    u = report["unsupervised_nrem"]

    lines = [
        "Sleep ML Practice Report",
        "========================",
        f"Rows: {ds['rows']} | Groups: {ds['groups']} | Epochs/group: {ds['epochs_per_group']}",
        "",
        "5-stage modality comparison:",
        f"- Spectral: {_pct(m['spectral']['mean_accuracy'])} (+/- {_pct(m['spectral']['sem'])})",
        f"- Time-domain: {_pct(m['time']['mean_accuracy'])} (+/- {_pct(m['time']['sem'])})",
        "",
        "5-stage region comparison:",
        f"- BG: {_pct(r['BG']['mean_accuracy'])} (+/- {_pct(r['BG']['sem'])})",
        f"- CS: {_pct(r['CS']['mean_accuracy'])} (+/- {_pct(r['CS']['sem'])})",
        f"- CTX+BG: {_pct(r['CTX_BG']['mean_accuracy'])} (+/- {_pct(r['CTX_BG']['sem'])})",
        "",
        "Constrained binary NREM LDA:",
        f"- BG: {_pct(c['BG']['mean_accuracy'])} (+/- {_pct(c['BG']['sem'])})",
        f"- CS: {_pct(c['CS']['mean_accuracy'])} (+/- {_pct(c['CS']['sem'])})",
        f"- CTX+BG: {_pct(c['CTX_BG']['mean_accuracy'])} (+/- {_pct(c['CTX_BG']['sem'])})",
        "",
        "Unsupervised surrogate-label experiment (binary NREM):",
        f"- Supervised LDA: {_pct(u['supervised']['mean_accuracy'])} (+/- {_pct(u['supervised']['sem'])})",
        f"- Unsupervised GMM->LDA: {_pct(u['unsupervised']['mean_accuracy'])} (+/- {_pct(u['unsupervised']['sem'])})",
    ]

    return "\n".join(lines)
