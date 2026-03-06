# Moneyball-Like Soccer Recruitment Project

Project 1 inside the Portfolio repository.

## What This Project Does

- Collects and processes player-level football data (FBref + Transfermarkt-related pipelines).
- Builds model-ready datasets by position.
- Runs a similarity engine to find nearest-neighbor player matches and archetypes.
- Exports CSV outputs for analysis and presentation.

## Project Structure

```text
projects/moneyball-like/
├── data/
├── modeling/
│   └── sim enngine/
├── requirements.txt
└── README.md
```

## Quick Start

```bash
pip install -r requirements.txt
```

Then run notebooks in order:
- `data/Data processing.ipynb`
- `modeling/sim enngine/Similarity engine.ipynb`
