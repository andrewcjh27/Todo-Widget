from __future__ import annotations

from dataclasses import dataclass
from typing import Dict, Iterable, Tuple

import numpy as np
import pandas as pd

SLEEP_STAGES: Tuple[str, ...] = ("Wake", "N1", "N2", "N3", "REM")
NREM_STAGES = {"N1", "N2", "N3"}
REGIONS: Tuple[str, ...] = ("BG", "CS", "PG")
BANDS: Tuple[str, ...] = ("delta", "theta", "alpha", "beta", "gamma")

# Qualitative mapping to sleep physiology described in the paper:
# NREM (especially N3) tends toward higher delta and lower high-frequency activity.
STAGE_BAND_MEANS: Dict[str, np.ndarray] = {
    "Wake": np.array([0.55, 0.62, 0.56, 0.84, 0.80]),
    "N1": np.array([0.78, 0.76, 0.50, 0.56, 0.44]),
    "N2": np.array([1.20, 0.72, 0.52, 0.36, 0.28]),
    "N3": np.array([1.66, 0.60, 0.44, 0.24, 0.18]),
    "REM": np.array([0.66, 0.84, 0.62, 0.66, 0.58]),
}


@dataclass(frozen=True)
class SyntheticSleepConfig:
    participants: Tuple[str, ...] = ("PD02", "PD03", "PD07", "PD09", "DYS16")
    hemispheres: Tuple[str, ...] = ("L", "R")
    epochs_per_hemisphere: int = 450
    random_seed: int = 7


def _make_time_mixing_matrix() -> np.ndarray:
    # Fixed matrix keeps project deterministic and makes tests stable.
    return np.array(
        [
            [0.90, -0.15, 0.05, 0.10, -0.04],
            [0.20, 0.62, 0.10, -0.08, 0.20],
            [0.08, 0.10, 0.70, 0.05, 0.02],
            [-0.20, 0.06, -0.06, 0.92, 0.32],
            [-0.08, 0.03, -0.04, 0.28, 0.95],
            [0.44, 0.18, 0.08, 0.26, 0.15],
        ]
    )


def _stage_probabilities() -> np.ndarray:
    # Keeps N1 relatively rare like real sleep staging datasets.
    return np.array([0.22, 0.08, 0.30, 0.22, 0.18], dtype=float)


def _region_parameters(region: str) -> Tuple[float, float, float]:
    # (signal_scale, latent_noise, time_noise)
    if region == "BG":
        return 0.74, 0.20, 0.46
    if region == "CS":
        return 1.02, 0.12, 0.36
    if region == "PG":
        return 0.97, 0.13, 0.37
    raise ValueError(f"Unknown region: {region}")


def _psd_bins_from_latent(latent: np.ndarray, rng: np.random.Generator) -> np.ndarray:
    bins = []
    for value in latent:
        for _ in range(3):
            bins.append(np.log1p(max(value + rng.normal(0.0, 0.08), 0.001)))
    return np.array(bins)


def _time_features_from_latent(
    latent: np.ndarray,
    region: str,
    rng: np.random.Generator,
    mixing_matrix: np.ndarray,
) -> np.ndarray:
    _, _, time_noise = _region_parameters(region)
    return mixing_matrix @ latent + rng.normal(0.0, time_noise, size=mixing_matrix.shape[0])


def _band_features_from_latent(latent: np.ndarray) -> Dict[str, float]:
    # Constrained/embeddable-style band features.
    return {
        "delta": float(np.log1p(latent[0])),
        "theta_alpha": float(np.log1p(latent[1] + latent[2])),
        "beta": float(np.log1p(latent[3])),
        "low_gamma": float(np.log1p(latent[4])),
    }


def generate_synthetic_sleep_dataset(config: SyntheticSleepConfig | None = None) -> pd.DataFrame:
    config = config or SyntheticSleepConfig()
    rng = np.random.default_rng(config.random_seed)
    mix = _make_time_mixing_matrix()

    rows = []
    stage_probs = _stage_probabilities()

    for participant in config.participants:
        participant_shift = {
            region: rng.normal(0.0, 0.09, size=len(BANDS)) for region in REGIONS
        }

        for hemisphere in config.hemispheres:
            hemisphere_shift = {
                region: rng.normal(0.0, 0.04, size=len(BANDS)) for region in REGIONS
            }
            sampled_stages = rng.choice(SLEEP_STAGES, size=config.epochs_per_hemisphere, p=stage_probs)

            for epoch_idx, stage in enumerate(sampled_stages):
                row = {
                    "participant": participant,
                    "hemisphere": hemisphere,
                    "group_id": f"{participant}_{hemisphere}",
                    "epoch": epoch_idx,
                    "stage": stage,
                    "is_nrem": int(stage in NREM_STAGES),
                }

                for region in REGIONS:
                    signal_scale, latent_noise, _ = _region_parameters(region)
                    base = STAGE_BAND_MEANS[stage] * signal_scale
                    latent = base + participant_shift[region] + hemisphere_shift[region]
                    latent = latent + rng.normal(0.0, latent_noise, size=len(BANDS))
                    latent = np.clip(latent, 0.02, None)

                    # Fine-grained PSD-like bins (3 bins per canonical band = 15 features per region).
                    psd_bins = _psd_bins_from_latent(latent, rng)
                    for idx, value in enumerate(psd_bins):
                        row[f"psd_{region}_{idx:02d}"] = float(value)

                    # Constrained-band features.
                    band_features = _band_features_from_latent(latent)
                    for band_name, value in band_features.items():
                        row[f"band_{region}_{band_name}"] = value

                    # Coarser, noisier time-domain summary features.
                    time_features = _time_features_from_latent(latent, region, rng, mix)
                    for idx, value in enumerate(time_features):
                        row[f"time_{region}_{idx:02d}"] = float(value)

                rows.append(row)

    return pd.DataFrame.from_records(rows)


def iter_group_ids(df: pd.DataFrame) -> Iterable[str]:
    for group_id in sorted(df["group_id"].unique().tolist()):
        yield group_id
