from __future__ import annotations

import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "src"))

from sleep_ml_project.data import SyntheticSleepConfig
from sleep_ml_project.experiments import run_all_experiments


class StudyInspiredClaimTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.report = run_all_experiments(
            SyntheticSleepConfig(
                epochs_per_hemisphere=300,
                random_seed=7,
            )
        )

    def test_dataset_has_expected_structure(self) -> None:
        dataset = self.report["dataset"]
        self.assertEqual(dataset["groups"], 10)
        self.assertEqual(dataset["epochs_per_group"], 300)

        stage_distribution = dataset["stage_distribution"]
        self.assertEqual(sorted(stage_distribution.keys()), ["N1", "N2", "N3", "REM", "Wake"])
        self.assertAlmostEqual(sum(stage_distribution.values()), 1.0, places=6)

    def test_spectral_outperforms_time_domain(self) -> None:
        modalities = self.report["five_stage_modalities"]
        spectral = modalities["spectral"]["mean_accuracy"]
        time_domain = modalities["time"]["mean_accuracy"]

        self.assertGreater(spectral, 0.84)
        self.assertGreater(spectral - time_domain, 0.15)

    def test_cortical_and_multi_stream_outperform_basal_ganglia(self) -> None:
        regions = self.report["five_stage_regions"]
        bg = regions["BG"]["mean_accuracy"]
        cs = regions["CS"]["mean_accuracy"]
        ctx_bg = regions["CTX_BG"]["mean_accuracy"]

        self.assertGreater(cs, bg + 0.08)
        self.assertGreaterEqual(ctx_bg, cs)

    def test_constrained_nrem_and_unsupervised_pipeline(self) -> None:
        constrained = self.report["constrained_nrem"]
        unsupervised = self.report["unsupervised_nrem"]

        constrained_ctx_bg = constrained["CTX_BG"]["mean_accuracy"]
        supervised = unsupervised["supervised"]["mean_accuracy"]
        unsup = unsupervised["unsupervised"]["mean_accuracy"]

        self.assertGreater(constrained_ctx_bg, 0.90)
        self.assertGreater(supervised, 0.92)
        self.assertGreater(unsup, 0.88)
        self.assertLess(supervised - unsup, 0.08)


if __name__ == "__main__":
    unittest.main()
