# Livestock Behaviour & Spatial Analytics: GPS Telemetry for Conservation
### Stakeholder Collaboration | MSc Dissertation Project

[[Python]](https://python.org)
[[R]](https://r-project.org)
[[QGIS]](https://qgis.org)

---

## Project Overview
This repository contains the data science pipeline developed in partnership with the Norfolk Wildlife Trust. The project decodes raw GPS telemetry tracking data to identify hidden livestock behaviours and map fine-scale habitat selection patterns using these decoded livestock behaviours. 

The methodologies established here offer actionable geospatial information to land managers to mitigate land degradation, monitor grazing pressure hotspots, and safeguard fragile ecosystems.

> *Note: The core analytical frameworks built in this repository form the basis of a manuscript currently in preparation for submission to a peer-reviewed scientific journal.*

---

## Data Stack & Core Libraries

*   **R Ecosystem:** 
    *   `momentuHMM` – Multi-state Hidden Markov Modelling for time-series telemetry.
    *   `glmmTMB` – Generalised Linear Mixed-Effects Models (GLMMs).
    *   `tidyverse` – Data cleaning (`dplyr`), and graphics (`ggplot2`).
*   **Python Ecosystem:**
    *   `GeoPandas` & `Shapely` – Vector geometry processing, coordinate transformations, and spatial joins.
    *   `hmmlearn` – Preliminary Hidden Markov Model.
    *   `Folium` – Interactive HTML maps.
    *   `Pandas` & `NumPy` – Numerical transformations, feature engineering, and data wrangling.
*   **GIS Application:**
    *   `QGIS` – Raster overlays, and publication-grade cartography.

---

## Methodology & Architecture

### 1. Behavioural Classification (HMMs)
Raw time-series GPS datasets are filtered for step lengths and turning angles. We fit multi-state **Hidden Markov Models (HMMs)** using `momentuHMM` (R) and `hmmlearn` (Python) to classify latent, unobserved cattle states into discrete ecological categories.

A discrete-time Hidden Markov Model (HMM) pipeline was applied to isolate foraging states from resting and transit behaviours.

### 2. Environmental & Diurnal Drivers (GLMMs)
Classified behavioural metrics are evaluated against time-series covariates (temperature, time of day) and geospatial attributes. We deployed **Generalised Linear Mixed Models (GLMMs)** via `glmmTMB` to identify shifts in activity patterns, evaluating diagnostics with simulated residuals to ensure robust stakeholder reporting.

Generalised Linear Models (GLMs), Generalised Linear Mixed Models (GLMMs), and paddock-agnostic spatial grazing pressure metrics (metrics that do not account for variation in virtual fence structure), were used to map landscape usage across NVC communities.

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
*   **Interactive Spatial Mapping:** The `R_Scripts/04_Predictive_Modelling.ipynb` file generates statistical plots demonstrate how livestock behaviour patterns adapt to local National Vegetation Classification (NVC) cummunitylayouts.
*   **Stakeholder Analytics:** The `outputs/` directory provides localised map layouts detailing where livestock aggregate when exhibiting grazing behaviour.
