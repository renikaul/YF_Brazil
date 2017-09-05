# MetaData for Environmental Covariates:

## NDVI

**Downloaded**: From MODIS, following `ModisDownload.R` script

**Spatial & Temporal Resolution**: Began as 1 km/month, processed into municipality/month via 'extract.R' script

**Filename**: NDVIall.csv

## Land Surface Temperature (LST)

**Downloaded**: From MODIS, following `ModisDownload.R` script

**Spatial & Temporal Resolution**: Began as 5 km/month days, processed into mean Temperature/municipality/month via 'extract.R' script

**Filename**: meanTall.csv

## Land Cover

**Downloaded**: From MODIS, following `ModisDownload.R` script

**Spatial & Temporal Resolution**: Began as 1 km/year, processed into municipality/year via `landCoverProcessing.R` script

**Sub-data?**: Statistics were calculated for each land type in each municipality/year. Column headers are from `ClassStat` function in `SDMTools` package

**Filename**: fragStatsyear.rds (i.e. fragStats2001.rds). Too much info to combine into one object and store on github

## Rainfall

**Downloaded**: From Tropical Rainfall Measuring Mission, downloaded via command line using `trmmDownload.sh` script (can run through R). Pay attention to notes in comments at top of script or it will not work.

**Spatial & Temporal Resolution**: Began as 4 km/month (recorded as average hourly rainfall in mm), recorded into spatial min. mean, and maximums per municipality/month

**Filename**: meanRFall.csv

## Fire

**Downloaded**:

**Spatial and Temporal Resolution**: Vector data (i.e. points) by date and time. Combined into number of fires per municipality per month via `fireProcess.R`

**Filename**:
