from __future__ import annotations

from dataclasses import dataclass
from typing import Callable, List, Sequence, Tuple

import os

import numpy as np
import pandas as pd
from sklearn.base import clone
from sklearn.discriminant_analysis import LinearDiscriminantAnalysis
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split

os.environ.setdefault("LOKY_MAX_CPU_COUNT", "1")


@dataclass(frozen=True)
class SplitData:
    train_df: pd.DataFrame
    test_df: pd.DataFrame


def mean_and_sem(values: Sequence[float]) -> Tuple[float, float]:
    arr = np.asarray(list(values), dtype=float)
    mean = float(np.mean(arr))
    sem = float(np.std(arr, ddof=1) / np.sqrt(len(arr))) if len(arr) > 1 else 0.0
    return mean, sem


def split_group_frame(
    group_df: pd.DataFrame,
    label_column: str,
    random_seed: int,
    test_size: float = 0.20,
) -> SplitData:
    train_idx, test_idx = train_test_split(
        group_df.index.to_numpy(),
        test_size=test_size,
        stratify=group_df[label_column],
        random_state=random_seed,
    )
    return SplitData(
        train_df=group_df.loc[train_idx].copy(),
        test_df=group_df.loc[test_idx].copy(),
    )


def make_hist_gb_model(random_seed: int) -> RandomForestClassifier:
    return RandomForestClassifier(
        n_estimators=180,
        max_depth=12,
        min_samples_leaf=2,
        random_state=random_seed,
        n_jobs=1,
    )


def make_lda_model() -> LinearDiscriminantAnalysis:
    return LinearDiscriminantAnalysis(solver="lsqr", shrinkage="auto")


def evaluate_grouped_classifier(
    df: pd.DataFrame,
    feature_columns: Sequence[str],
    label_column: str,
    model_factory: Callable[[], object],
    random_seed: int,
) -> pd.DataFrame:
    results: List[dict] = []

    for group_id in sorted(df["group_id"].unique().tolist()):
        group_df = df[df["group_id"] == group_id]
        split = split_group_frame(group_df, label_column=label_column, random_seed=random_seed)

        x_train = split.train_df[feature_columns].to_numpy()
        y_train = split.train_df[label_column].to_numpy()

        x_test = split.test_df[feature_columns].to_numpy()
        y_test = split.test_df[label_column].to_numpy()

        model = clone(model_factory())
        model.fit(x_train, y_train)
        accuracy = float(model.score(x_test, y_test))

        results.append(
            {
                "group_id": group_id,
                "n_train": len(split.train_df),
                "n_test": len(split.test_df),
                "accuracy": accuracy,
            }
        )

    return pd.DataFrame(results)
