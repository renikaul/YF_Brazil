# Code and Data for 'Spatio-temporal spillover risk of yellow fever in Brazil'

This repository contains the code and data necessary to reproduce the analysis from:

Kaul, RajReni B., Michelle V. Evans, Courtney C. Murdock, John M. Drake. 2018. Spatio-temporal spillover risk of yellow fever in Brazil. *Journal* Issue, ppg.

## Dependencies

The majority of this code is to be run in `R`, and was initially run on the following version:

    R version 3.4.3 (2017-11-30)
    Platform: x86_64-pc-linux-gnu (64-bit)
    Running under: Ubuntu 14.04.5 LTS

Some scripts to download data will need to run via the command line, and were initially run on Linux machines.

## Overall File Structure

- `data_raw`: raw environmental, demographic, and case data. This includes remote sensed environmental data that has been extracted for each municipality
- `data_clean`: cleaned environmental data, processed via `R` scripts in `data_processingScripts`
- `data_processingScripts`: cleans data, moving it from raw to clean folder
- `code`: code to run analysis and create manuscript figures
- `data_out`: results of analysis, predictions by municipality x month and variable importance data

## Data

Raw data is located in the `data_raw` folder. Meta-data on how they were downloaded and processed can be found in the files:

- `YF_metadata.txt`
- `demo_metadata.txt`
- `EnvCovar-metadata.md`

All scripts used to download raw data are in the `data_processingScripts` folder, and noted in the metatdata files. Most should be run in the following order: download, extract, process, combine.

Once each individual variables has been processed, it is saved in the `data_clean` folder. The final full datasets are created via the `GiantDataFrameMaker.R` file. This creates `TestingDataSpat2.rds` and `TrainingDataSpat2.rds`. The data is further split into the National and Regional Models in the `nhpSplit.R` file in the `data_processingScripts` folder.

### Final datasets

There are six final datasets that are used in our analysis, three training and three testing:

**Training**:

- `data_clean/TrainingDataLowNHP2.rds` : training data for LRR model
- `data_clean/TrainingDataHighNHP2.rds` : training data for HRR model
- `data_clean/TrainingDataLowNHP2.rds` : training data for National model

**Testing**:

- `data_clean/TestingDataLowNHP2.rds` : testing data for LRR model
- `data_clean/TestingDataHighNHP2.rds` : testing data for HRR model
- `data_clean/TestingDataSpat2.rds` : testing data for National model


####  Column Names on Final Data

  - **case**: binary response variable representing spillover (num)
  - **NumCase**: raw number of YF cases (num)
  - **popLog10**: population density log10 transformed (num)
  - **NDVI**: NDVI value (num)
  - **NDVIScale**: NDVI anomaly variable (num)
  - **RFSqrt**: rainfall (mm/hr, average monthly), square-root transformed (num)
  - **RFScale**: rainfall anomaly variable (num)
  - **tempMean**: temperature (C, monthly) (num)
  - **tempScale**: temperature anomaly variable (num)
  - **fireDenSqrt**: density of fires, square-root transformed (num)
  - **fireDenScale**: fire density anomaly variable (num)
  - **spRich**: non-human primate species richness (int)
  - **primProp**: proportion of municipality area consisting of agricultural land overlapping a primate range, summed across 9 genera (num)
  - **muni.no**: the unique municipality number, six digits (num)
  - **muni.name**: the municipality name, note some are the same so do not sort by this (chr)
  - **year**: the year (num)
  - **cal.month**: the month, 1 - 12 (num)
  - **month.no**: the month, out of the whole data set, 1-156 (num)

## Analysis

All analyses, including visualizations, are in the `code` folder.

Source files for bagged logistic regression are in the `code/functions` folder.

`MSanalysis.R` runs the whole analysis, including training the model, assessing model performance on the testing data, combining predictions for the full dataset, and calculating variable importance via permutations. **BEWARE** This script is extremely memory intensive and is meant to be run in parallel on a HPC. Results are stored by model in the `data_out`folder

`MSFigures.Rmd` creates all the figures in the manuscript.

## Results

Result are stored in the `data_out` folder. Each model's result are stored in a seperate folder (OneModel = National, LowModel = LRR, HighModel = HRR). Within each folder are the following files:

- `Perm100Model500TryCatch.rds`: results of permuting data 100 times on variable importance using 500 bags per model
- `testingPredictions.rds` : predictions on the testing data
- `wholePredictions.rds`: predictions over the whole data

In the inital folder there is also a summary csv file of the AUC values per model and dataset.

## Issues and Questions

Please contact Reni Kaul (reni [at] uga.edu) or Michelle Evans (mvevans [at] uga.edu) with any comments or questions.
