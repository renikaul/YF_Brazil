# Code and Data for 'Spatio-temporal spillover risk of yellow fever in Brazil'

This repository contains the code and data necessary to reproduce the analysis from:

Kaul, RajReni B., Michelle V. Evans, Courtney C. Murdock, John M. Drake. 2018. Spatio-temporal spillover risk of yellow fever in Brazil. *Journal* Issue, ppg.

## Dependencies

The majority of this code is to be run in `R`, and was initially run on the following version:

**Insert version from high mem machine here**

Some scripts to download data will need to run via the command line, and were initially run on Linux machines.

## Data Structure

Raw data is located in the `data_raw` folder. Meta-data on how they were downloaded and processed can be found in the files:

- `YF_metadata.txt`
- `demo_metadata.txt`
- `EnvCovar-metadata.md`

All scripts used to download raw data are in the `data_processingScripts` folder, and noted in the metatdata files. Most should be run in the following order: download, extract, process, combine.

Once each individual variables has been processed, it is saved in the `data_clean` folder. The final full datasets are created via the `GiantDataFrameMaker.R` file. This creates `TestingDataSpat2.rds` and `TrainingDataSpat2.rds`

## Notes on Column Names

In order to have some standardization across data and files, here are the column names we are using:

  - **muni.no**: the municipality number (like FIPS), six digits (num)
  - **muni.name**: the municipality name (chr)
  - **year**: the year (num)
  - **cal.month**: the month, 1 - 12 (num)
  - **month.no**: the month, out of the whole data set, 1-168 (num)
