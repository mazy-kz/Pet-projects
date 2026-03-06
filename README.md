# Moneyball-Like Soccer Recruitment Project

Portfolio project that builds a player-similarity engine from Big-5 league data to support scouting and recruitment decisions.

## What This Project Does

- Collects and processes player-level football data (FBref + Transfermarkt-related pipelines).
- Builds model-ready datasets by position.
- Runs a similarity engine to find nearest-neighbor player matches and archetypes.
- Exports CSV outputs for analysis and presentation.

## Repository Structure

```text
.
├── data/
│   ├── Data processing.ipynb
│   ├── Untitled-1.ipynb
│   ├── all_columns.xlsx
│   ├── fbref/
│   │   ├── 01_download_fbref_top5_players.R
│   │   ├── 02_tm_league_team_urls.R
│   │   ├── 03_tm_big5_player_urls_2019_2024.R
│   │   ├── 04_tm_big5_market_values_2019_2024.R
│   │   └── ...
│   └── model_ready/
│       ├── model_ready_df_z.csv
│       ├── model_ready_fw_z.csv
│       ├── model_ready_gk_z.csv
│       ├── model_ready_mf_z.csv
│       └── model_ready_diagnostics.csv
├── modeling/
│   └── sim enngine/
│       ├── Similarity engine.ipynb
│       └── outputs/similarity_engine/
│           └── *.csv
├── requirements.txt
└── PUBLISHING.md
```

## Tech Stack

- Python (Pandas, NumPy, scikit-learn, Matplotlib)
- Jupyter Notebooks
- R scripts for data sourcing support

## Quick Start

1. Create and activate a virtual environment.
2. Install dependencies:

```bash
pip install -r requirements.txt
```

3. Run notebooks in this order:
- `data/Data processing.ipynb`
- `modeling/sim enngine/Similarity engine.ipynb`

## Data Notes

- The raw file `data/fbref_big5_players_2019_2025_all_stat_types.csv` is excluded from git because it is larger than GitHub's 100MB single-file limit.
- Model-ready data and modeling outputs are included for reproducibility and demonstration.

## Portfolio Highlights

- End-to-end analytics workflow from data sourcing to model outputs.
- Position-aware player profiling and nearest-neighbor retrieval.
- Export-ready tables for presenting recruitment insights.

## Author

Created by `User` as a sports analytics portfolio project.

