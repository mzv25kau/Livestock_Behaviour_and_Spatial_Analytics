# Livestock Behaviour & Spatial Analytics: GPS Telemetry for Conservation
### Stakeholder Collaboration | MSc Dissertation Project

[[Python]](https://python.org)
[[R]](https://r-project.org)
[[QGIS]](https://qgis.org)

---

## Project Overview
This repository contains the data science pipeline developed in partnership with the Norfolk Wildlife Trust. The project decodes raw GPS telemetry tracking data to identify hidden livestock behaviours and map fine-scale habitat selection patterns using these decoded livestock behaviours. 

The methodologies established here offer actionable geospatial information to land managers to mitigate land degradation, monitor grazing pressure hotspots, and safeguard fragile ecosystems.

> *Note: The core analytical frameworks built in this repository form the basis of a manuscript currently in preparation for submission to a peer-reviewed scientific journal. Therefore, certain components of this repository (i.e. 'Outputs') are only to be uploaded post-publishing.*

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
    *   `QGIS` – Raster overlays, and publication-grade cartography outputs.

---

## Methodology & Architecture

### 1. Behavioural Classification (HMMs)
Raw time-series GPS datasets were cleaned and processed to extract cattle movement speeds and turning angles. Discrete-time **Hidden Markov Models (HMM)** pipelines were applied using `momentuHMM` (R) and `hmmlearn` (Python) to classify latent, unobserved cattle behaviour states into discrete ecological categories in order to isolate grazing behaviours.

### 2. Predictive Modelling of Landcape Usage (GLMMs)
Classified grazing behaviour metrics were evaluated against time-series covariates and geospatial attributes. We deployed **Generalised Linear Models (GLMs)**, and **Generalised Linear Mixed Models (GLMMs)** via `glmmTMB` to identify shifts in behaviour patterns across National Vegetation Classification (NVC) communities.

### 3. Spatial Pipeline & Custom Grazing Pressure Metrics
Behaviour state-labelled GPS points were transformed into custom grazing intensity metrics, used in tandem with predictive model outputs to highlight and map over/under-grazed areas contained within NVC communities.

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
*   **Interactive Spatial Mapping:** The `R_Scripts/04_Predictive_Modelling.ipynb` file generates statistical plots demonstrate how livestock behaviour patterns adapt to local NVC cummunity layouts.
*   **Stakeholder Analytics:** The `outputs/` directory provides localised map layouts detailing where livestock aggregate when exhibiting grazing behaviour.
