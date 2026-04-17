from __future__ import annotations

from typing import Iterable, List, Sequence

import pandas as pd


def _prefixes(feature_family: str, regions: Sequence[str]) -> List[str]:
    return [f"{feature_family}_{region}_" for region in regions]


def select_feature_columns(
    df: pd.DataFrame,
    feature_family: str,
    regions: Sequence[str],
) -> List[str]:
    prefixes = _prefixes(feature_family, regions)
    selected = [col for col in df.columns if any(col.startswith(prefix) for prefix in prefixes)]
    if not selected:
        raise ValueError(
            f"No columns found for family={feature_family} and regions={list(regions)}"
        )
    return sorted(selected)


def count_features(df: pd.DataFrame, feature_family: str, regions: Sequence[str]) -> int:
    return len(select_feature_columns(df, feature_family, regions))


def available_feature_families(df: pd.DataFrame) -> Iterable[str]:
    families = set()
    for col in df.columns:
        if "_" in col:
            families.add(col.split("_", 1)[0])
    return sorted(families)
