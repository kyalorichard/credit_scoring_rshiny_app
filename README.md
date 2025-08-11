
# Credit Scoring Model with R and Shiny

## Overview
This project implements an **end-to-end credit scoring system** using **R** and **Shiny** with a user-friendly dashboard.
It allows you to:
- Upload a dataset (CSV format)
- Apply filters to select subsets of data
- Choose from multiple machine learning models (Logistic Regression, Random Forest, XGBoost, LightGBM)
- Train models and view performance metrics (AUC, KS, Accuracy, Confusion Matrix)
- Compare models via leaderboard
- Download trained models
- Score new datasets

The app is designed for financial institutions, microfinance organizations, or any organization that needs to assess creditworthiness.

---

## Features

### 1. Data Upload & Preprocessing
- Upload `.csv` files via the dashboard
- Automatic detection of categorical vs numeric columns
- Missing value handling via `recipes`
- Train/test split with stratification
- Scaling/encoding pipelines

### 2. Model Selection
- Logistic Regression (`glm`)
- Random Forest (`ranger`)
- XGBoost (`xgboost`)
- LightGBM (`lightgbm`)

### 3. Training & Tuning
- Cross-validation with `rsample`
- Hyperparameter tuning with `tune` + `dials`
- `yardstick` metrics (AUC, KS, Accuracy, Sensitivity, Specificity)

### 4. Evaluation
- ROC curves
- KS statistic plot
- Variable importance plots
- Calibration plot

### 5. Model Management
- Save trained models to `models/` folder
- Load and score new data
- Compare models in leaderboard

### 6. Dashboard (Shiny)
- Data upload
- Filtering panel
- Model selection dropdown
- Training progress bar
- Metrics display
- Download scored dataset

---

## Folder Structure

```
credit_scoring_rshiny_repo/
│
├── app.R                  # Main Shiny application
├── R/
│   ├── preprocessing.R    # Recipes and preprocessing functions
│   ├── modeling.R         # Model training and tuning
│   ├── evaluation.R       # Plots and metrics
│   └── utils.R            # Helper functions
├── data/
│   └── sample_data.csv    # Example dataset
├── models/                # Saved trained models
├── www/                   # Static assets (CSS, images, etc.)
├── Dockerfile             # For containerization
└── README.md              # Project documentation
```

---

## Installation

### 1. Clone the repository
```bash
git clone https://github.com/yourusername/credit_scoring_rshiny_repo.git
cd credit_scoring_rshiny_repo
```

### 2. Install R packages
Make sure you have R (≥ 4.1) and RStudio installed.

Install dependencies:
```r
install.packages(c(
  "shiny", "shinydashboard", "tidyverse", "tidymodels", "ranger",
  "xgboost", "lightgbm", "DT", "plotly", "shinyWidgets", "readr",
  "yardstick", "vip", "themis"
))
```

### 3. Run the app locally
```r
shiny::runApp()
```

---

## Running in Docker

### 1. Build image
```bash
docker build -t credit_scoring_rshiny .
```

### 2. Run container
```bash
docker run -p 8080:8080 credit_scoring_rshiny
```

The app will be available at `http://localhost:8080`.

---

## Usage
1. Launch the Shiny app
2. Upload your dataset (CSV)
3. Select target variable (binary classification)
4. Choose one or more models
5. Train models and review metrics
6. Download trained model or scored dataset

---

## Example Dataset
The included `data/sample_data.csv` contains sample credit scoring data with:
- `age`
- `income`
- `loan_amount`
- `loan_status` (target: 1 = default, 0 = no default)

---

## Roadmap
- [ ] Add SHAP explainability
- [ ] Add API endpoint with `plumber`
- [ ] Async training with `future`
- [ ] Model registry integration (MLflow)

---

## License
This project is licensed under the MIT License.

---

## Author
Developed by Richard Kyalo
