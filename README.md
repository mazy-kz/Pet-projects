# 🧪 Pet Projects & Experiments

This repository is a collection of my independent research and data-driven side projects.
---

## 📂 Featured Project: Moneyball-Like Soccer Recruitment

A multi-model scouting system designed to identify statistically similar player replacements and high-upside prospects across the top 5 European leagues.

### 🛠️ Project Workflow
* **Stage 1: Data Parsing (R-based)** — Automated scraping of player-level intelligence via `worldfootballR`.
* **Stage 2: Data Processing (Python-based)** — Feature engineering, per-90 normalization, and position-specific segmentation.
* **Stage 3: Modeling Architecture** — A three-model system including:
    1. **Model A:** Similarity Engine (PCA + KNN) for style-based lookalike identification.
    2. **Model B:** Value Discovery relative to performance-based expected market value.
    3. **Model C:** High-upside signaling for future market value increases.

> **Note:** For deep technical details, methodology, and execution steps, please refer to the **README.md** inside the `/moneyball-like/` folder.

---

## ⚡ Quick Navigation
1. Navigate to the specific project folder.
2. Install dependencies: `pip install -r requirements.txt`.
3. Follow the numbered notebooks to reproduce the analysis.
