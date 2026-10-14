# Livestock Behaviour & Spatial Analytics: GPS Telemetry for Conservation
### Stakeholder Collaboration | MSc Dissertation Project

[[Python]](https://python.org)
[[R]](https://r-project.org)
[[QGIS]](https://qgis.org)

---

## Project Overview
This repository contains the end-to-end data science pipeline developed in partnership with the **Norfolk Wildlife Trust**. The project decodes raw, unstructured GPS telemetry tracking data to identify latent livestock behaviours and map fine-scale habitat selection patterns. 

The methodologies established here deliver actionable geospatial intelligence to Trust land managers to mitigate land degradation, monitor grazing pressure hotspots, and safeguard fragile nature reserve biodiversity.

> *Note: The core analytical frameworks built in this repository form the basis of a manuscript currently in preparation for submission to a peer-reviewed scientific journal.*

---

## Data Stack & Core Libraries

This project bridges the gap between R's advanced ecological statistical suites and Python's scalable geospatial processing pipelines:

*   **R Ecosystem:** 
    *   `momentuHMM` – Multi-state Hidden Markov Modelling for time-series telemetry.
    *   `glmmTMB` – Generalised Linear Mixed-Effects Models (GLMMs) handling zero-inflation.
    *   `tidyverse` – Declarative data cleaning (`dplyr`), piping, and graphics (`ggplot2`).
*   **Python Ecosystem:**
    *   `GeoPandas` & `Shapely` – Vector geometry processing, coordinate transformations, and spatial joins.
    *   `hmmlearn` – Custom sequence validation and behavioural state checking.
    *   `Folium` – Interactive HTML leaf maps for field exploration.
    *   `Pandas` & `NumPy` – Numerical transformations, feature engineering, and data wrangling.
*   **GIS Application:**
    *   `QGIS` – Spatial metric verification, raster extraction overlays, and publication-grade cartography.

---

## Methodology & Architecture

### 1. Behavioural Classification (HMMs)
Raw time-series GPS datasets are filtered for step lengths and turning angles. We fit multi-state **Hidden Markov Models (HMMs)** using `momentuHMM` (R) and `hmmlearn` (Python) to classify latent, unobserved cattle states into three discrete ecological categories:
*   **Transit:** High step length, low turning angle.
*   **Foraging:** Moderate step length, high turning angle.
*   **Resting:** Low step length, random turning angle.

### 2. Environmental & Diurnal Drivers (GLMMs)
Classified behavioural metrics are evaluated against time-series covariates (temperature, time of day) and geospatial attributes. We deployed **Generalised Linear Mixed Models (GLMMs)** via `glmmTMB` to identify shifts in activity patterns, evaluating diagnostics with simulated residuals to ensure robust stakeholder reporting.

### 3. Spatial Pipeline & Grazing Pressure Metrics
Using `GeoPandas`, raw points are transformed into density matrices. Custom spatial aggregation functions isolate foraging-state locations to extract, calculate, and map spatial hotspots of high-intensity grazing pressure.

---

## Repository Structure

```text
├── notebooks/
│   ├── 01_EDA_&_Cleaning.ipynb                    # Exploratory Data Analysis (EDA) and initial data cleaning steps
│   ├── 02_Preprocessing_&_Preliminary_HMM.ipynb   # Python preprocessing
│   └── 05_Additional_Figures.ipynb                # Additional publication figures and QGIS file preparation
├── scripts/
│   ├── 03_Final_HMM.R                             # R script executing momentuHMM pipeline
│   └── 04_Predictive_models.R                     # R script executing predictive models (including glmmTMB mixed models)
├── outputs/                                       # Exported publication maps and graphics
│   └── ...                                        # Outputs to be uploaded after publishing
└── README.md                                      # Project documentation
```

---

## Key Insights & Visualisations
*   **Interactive Spatial Mapping:** The `notebooks/02_spatial_mapping.ipynb` file generates localised map layouts detailing exactly where livestock aggregate during critical foraging windows.
*   **Stakeholder Analytics:** The `outputs/` directory provides pre-rendered statistical plots demonstrating how biological activity patterns adapt to local thermal conditions and vegetation density layouts.
