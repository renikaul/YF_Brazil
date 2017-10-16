# MetaData for Environmental Covariates:

## NDVI

**Downloaded**: From MODIS, following `ModisDownload.R` script. Dataset is MOD13A3

**Spatial & Temporal Resolution**: Began as 1 km/month, processed into municipality/month via 'extract.R' script

**Filename**: NDVIall.csv

## Land Surface Temperature (LST)

**Downloaded**: From MODIS, following `ModisDownload.R` script. Dataset is MOD11C3

**Spatial & Temporal Resolution**: Began as 5 km/month days, processed into mean Temperature/municipality/month via 'extract.R' script

**Filename**: meanTall.csv

## Land Cover (no longer using)

**Downloaded**: From MODIS, following `ModisDownload.R` script. Dataset is MCD12Q1.

**Spatial & Temporal Resolution**: Began as 1 km/year, processed into municipality/year via `landCoverProcessing.R` script

**Sub-data?**: Statistics were calculated for each land type in each municipality/year. Column headers are from `ClassStat` function in `SDMTools` package

**Filename**: fragStatsyear.rds (i.e. fragStats2001.rds). Too much info to combine into one object and store on github

## Rainfall

**Downloaded**: From Tropical Rainfall Measuring Mission, downloaded via command line using `trmmDownload.sh` script (can run through R). Pay attention to notes in comments at top of script or it will not work.

**Spatial & Temporal Resolution**: Began as 4 km/month (recorded as average hourly rainfall in mm), recorded into spatial mean per municipality/month

**Filename**: meanRFall.csv

## Fire

**Downloaded**: Data is the LANCE Active Fire Dataset (MCD14ML). It is point data on fires (detected at the 1 km resolution), with date and time attributes. It was downloaded for 2001 - 2014 via https://earthdata.nasa.gov/earth-observation-data/near-real-time/firms/active-fire-data.

**Spatial and Temporal Resolution**: Vector data (i.e. points) by date and time. Combined into number of fires per municipality per month via `fireProcess.R`

**Filename**: fires.csv

## Primate Maps

**Downloaded**: Data is the IUCN Redlist of Terrestrial Mammal Shapefiles (http://www.iucnredlist.org/technical-documents/spatial-data). This was processed via 'primateProcessing.R'. 

**Spatial and Temporal Resolution**: 

*Primate Proportions:* km^2/year. 

This data is the sum of each municipalities relative area that is both agricultural and falls within a primate genus range. It is summed over all 9 genuses. For example, if a municipality was 50% agricultural land, but fell within the range of all 9 genera, its value would be 4.5. If a municipality was 10% agricultural land, with all of that 10% falling within the range of one genus, and then half of that (5%) falling within the range of another, its value would be 0.15. 

Filename: primateProp.csv

*Primate Richness*: This is equal to the original resolution of the shapefiles and is not temporal. It is the total number of NHP species (of the 9 genera) found in that municipality.
