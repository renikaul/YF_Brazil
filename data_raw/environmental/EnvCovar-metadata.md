# MetaData for Environmental Covariates:

## NDVI

**Downloaded**: From MODIS, following `ModisDownload.R` script

**Spatial & Temporal Resolution**: Began as 1 km/month, processed into municipality/month via 'extract.R' script

**Filename**: NDVIall.csv

## Land Surface Temperature (LST)

**Downloaded**: From MODIS, following `ModisDownload.R` script

**Spatial & Temporal Resolution**: Began as 1 km/8 days, processed into municipality/month via 'extract.R' script

**Sub-data?**: Processed into min, mean, and max by first taking the min, mean and maximum temperatures per 1 km grid cell per month. Then spatially aggregated to municipality by min, mean and max.

**Filename**: maxTall.csv, minTall.csv, meanTall.csv

## Land Cover

**Downloaded**: From MODIS, following `ModisDownload.R` script

**Spatial & Temporal Resolution**: Began as 1 km/year, processed into municipality/year via `landCoverProcessing.R` script

**Sub-data?**: Statistics were calculated for each land type in each municipality/year. Column headers are from `ClassStat` function in `SDMTools` package

**Filename**: fragStatsyear.rds (i.e. fragStats2001.rds). Too much info to combine into one object and store on github

## Rainfall

**Downloaded**: From Tropical Rainfall Measuring Mission, downloaded via command line using `trmmDownload.sh` script (can run through R). Pay attention to notes in comments at top of script or it will not work.

**Spaital & Temporal Resolution**: Began as 4 km/month (recorded as average hourly rainfall in mm), recorded into spatial min. mean, and maximums per municipality/month

**Filename**: minRFall.csv, maxRFall.csv, meanRFall.csv
