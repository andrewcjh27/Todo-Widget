# Sleep ML Practice Project (Study-Inspired)

This project helps you practice machine learning by recreating the **logic** of the paper in your PDF:

- `Personalized supervised and unsupervised intracranial sleep decoding during deep brain stimulation` (npj Digital Medicine, 2026)

Because the original patient dataset is not public, this project generates a **study-shaped synthetic dataset** and tests the same style of claims.

## What You Practice

- Personalized (per-participant/per-hemisphere) train/test splits
- 5-stage sleep classification (`Wake`, `N1`, `N2`, `N3`, `REM`)
- Modality comparison: spectral features vs time-domain features
- Region comparison: `BG` vs `CS` vs `CTX+BG`
- Constrained model: binary `NREM` decoding with LDA
- Unsupervised surrogate labels: GMM clusters + LDA

## Project Layout

- `run_project.py`: run all experiments and print a report
- `src/sleep_ml_project/data.py`: synthetic data generator
- `src/sleep_ml_project/features.py`: feature-family selectors
- `src/sleep_ml_project/models.py`: model/split helpers
- `src/sleep_ml_project/experiments.py`: full experiment pipeline
- `tests/test_study_claims.py`: tests for study-inspired claims

## Run It

From the repository root:

```bash
python3 ml_sleep_project/run_project.py
```

Optional:

```bash
python3 ml_sleep_project/run_project.py --epochs-per-hemisphere 300 --json
```

Run tests:

```bash
python3 -m unittest discover -s ml_sleep_project/tests -v
```

## Suggested Practice Workflow

1. Run the baseline project and read the printed report.
2. Open `experiments.py` and modify one thing at a time:
   - swap classifier,
   - change features,
   - change split strategy,
   - adjust unsupervised mapping.
3. Re-run tests and see which claims still hold.
4. Add a new hypothesis test in `tests/test_study_claims.py`.

## Next Up (Good Extensions)

- Add confusion matrices by stage and participant
- Add per-stage recall/F1 (especially for `N1`)
- Try hold-out by night (instead of random epoch split)
- Add a notebook that visualizes band distributions and model errors
