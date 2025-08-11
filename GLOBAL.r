packages <- c(
  "shiny", "shinyWidgets", "tidyverse", "DT",
  "randomForest", "xgboost", "lightgbm", "tidymodels"
)

to_install <- setdiff(packages, rownames(installed.packages()))
if (length(to_install)) {
  install.packages(to_install)
}

# Load them
lapply(packages, library, character.only = TRUE)

# Load example dataset (can be replaced with uploaded one)
data_path <- "data/sample_data.csv"
if (!file.exists(data_path)) {
  write_csv(mtcars, data_path)
}
sample_data <- read_csv(data_path)
