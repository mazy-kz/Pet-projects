# ⚽ Moneyball-Like Soccer Recruitment Project

This project builds a multi-model scouting system to identify statistically similar player replacements, undervalued assets, and high-upside prospects across the top 5 European leagues using multi-season player-level data.

---

## 🚀 Project Overview

The objective is to move beyond raw output numbers and identify players based on **playing style**. By using position-specific modeling, the system ensures fair and actionable comparisons for modern football recruitment.

### Key Goals:
* **Lookalike Identification:** Find statistical replacements for target players.
* **Value Discovery:** Identify undervalued players relative to performance-based market value.
* **Future Signals:** Spot high-upside players likely to increase in value next season.

---

## 🛠️ Project Workflow

### Stage 1: Data Parsing (R-based)
* **Objective:** Automated collection of raw football intelligence.
* **Tools:** `worldfootballR` (R package).
* **Process:** Scraping player-level data from FBref and market valuation data from Transfermarkt.
* **Why:** Provides the high-fidelity, multi-season foundation required for longitudinal analysis.

### Stage 2: Data Processing & Feature Engineering (Python-based)
* **Notebook:** `data/Data processing.ipynb`
* **Objective:** Clean and prepare model-ready datasets.
* **Methods:** * **Normalization:** Per-90 normalization to remove minutes-played bias.
    * **Standardization:** Z-score scaling for distance-based algorithms.
    * **Segmentation:** Position-group splitting to ensure fair comparisons.
    * **Transformations:** Log transformation of market values and season alignment ($t \rightarrow t+1$ pairs).

### Stage 3: Modeling Architecture (Phase 1)
* **Notebook:** `modeling/sim engine/Similarity engine.ipynb`
* **Objective:** Implement Model A — The Similarity Engine.
* **Techniques:**
    * **Dimensionality Reduction:** Principal Component Analysis (PCA) to remove noise and handle correlated metrics.
    * **Clustering:** K-Means to group players into functional archetypes (e.g., "Deep-lying Playmaker").
    * **Similarity Search:** K-Nearest Neighbors (KNN) and Cosine Similarity to identify lookalikes in style space.
* **Validation:** Scree plots for PCA and silhouette/elbow plots for optimal clustering.

> **Note:** This is only the **1st model** of the system. Future stages will include Model B (Market Value Prediction) and Model C (High-Upside Signaling).

---

## 📂 Project Structure

```text
projects/moneyball-like/
├── data/                    # Stage 1 (R scripts) & Stage 2 (Processing)
├── modeling/
│   └── sim engine/          # Stage 3 (Similarity Engine logic)
├── outputs/                 # CSV exports: Top-K neighbors and archetypes
├── requirements.txt         # Python dependencies
└── README.md
