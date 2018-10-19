# Code and Data for 'Spatio-temporal spillover risk of yellow fever in Brazil'

This repository contains the code and data necessary to reproduce the analysis from:

Kaul, RajReni B., Michelle V. Evans, Courtney C. Murdock, John M. Drake. 2018. Spatio-temporal spillover risk of yellow fever in Brazil. *Parasite & Vectors* 11, **488**. https://doi.org/10.1186/s13071-018-3063-6

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

- `data_clean/Mosi_Final/TrainingDataLowNHP.rds` : training data for LRR model
- `data_clean/Mosi_Final/TrainingDataHighNHP.rds` : training data for HRR model
- `data_clean/Mosi_Final/TrainingDataLowNHP.rds` : training data for National model

**Testing**:
- same as training but named Testing*
