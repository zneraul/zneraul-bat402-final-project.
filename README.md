# BAT 402 Final Project — Forecasting Global PS4 Game Sales

Fundamentals of Analytics Modeling (BAT 402) Final Project
Batangas State University — College of Informatics and Computing Sciences

**Business goal:** Forecast a PS4 game's total global unit sales from its early
North American result plus factors known at launch, so a publisher can plan
manufacturing, marketing, and inventory while the game is still selling.

## Contents

| File | Description |
|---|---|
| `BAT402_FP_Surname1_Surname2_Surname3_Script.R` | Full R script (base R only, runs top-to-bottom in a fresh session) |
| `BAT402_FP_Surname1_Surname2_Surname3_Dataset.csv` | Prepared dataset: 710 rows × 12 columns, with 3 engineered features |
| `BAT402_FP_Surname1_Surname2_Surname3_Report.docx` | Written report (5 sections + appendices) |
| `BAT402_FP_Surname1_Surname2_Surname3_Slides.pptx` | 12 presentation slides with speaker notes |
| `PS4_GamesSales.csv` | Raw dataset (VGChartz scrape via Kaggle, SID_TWR) |
| `run_output.txt` | Console output of a full clean run of the script |
| `chart1_actual_vs_predicted.png` | Actual vs predicted, test set |
| `chart2_monte_carlo.png` | 5,000-run Monte Carlo of launch outcomes |
| `chart3_genre.png` | Median sales by genre |
| `chart4_lifecycle.png` | Mean sales by console lifecycle phase |

## How to reproduce

1. Download `PS4_GamesSales.csv` from the
   [Kaggle dataset page](https://www.kaggle.com/datasets/sidtwr/videogames-sales-dataset?select=PS4_GamesSales.csv)
   and place it in the same folder as the script.
2. Open `BAT402_FP_Surname1_Surname2_Surname3_Script.R` in RStudio and run all
   (or `Rscript BAT402_FP_Surname1_Surname2_Surname3_Script.R`).
3. The script regenerates the prepared dataset, all four charts, and every
   number in the report. `set.seed(42)` is set before every random operation.

## Key results

- Multiple linear regression: `Global ~ NorthAmerica + LifecyclePhase + GenreGroup + PublisherTier`
- Test R² = 0.80; typical miss for games under 1M units ≈ 164,000 copies
- Each 1M extra North American units ≈ 2.5M more global units
- 5-fold CV average RMSE 0.493 ≈ training RMSE 0.480 → no material overfitting
- Monte Carlo (5,000 runs): mean forecast 0.805M units; ~19% chance below 0.30M

## Notes

- Rename the files and fill in the `[Surname]`, `[DATE]`, and section
  placeholders before submitting (see the project handout's file-naming rule).
- Regional sales (Europe, Japan, Rest of World) are deliberately excluded as
  predictors: they become known at the same time as the global figure.
  North America is used because it is available weeks earlier.
