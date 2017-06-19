MetaData for Environmental Covariates:

*NDVI*:
**Downloaded**: From MODIS, following NAME R script
**Spatial & Temporal Resolution**: Began as 1 km/month, processed into municipality/month via 'extract.R' script
**Filename**: 'NDVIall.csv'

*Land Surface Temperature (LST)*:
**Downloaded**: From MODIS, following NAME R script
**Spatial & Temporal Resolution**: Began as 1 km/8 days, processed into municipality/month via 'extract.R' script
**Sub-data?**: Processed into min, mean, and max by first taking the min, mean and maximum temperatures per 1 km grid cell per month. Then spatially aggregated to municipality by min, mean and max.
**Filename**: 'maxTall.csv', 'minTall.csv', 'meanTall.csv'

*Land Cover*:
**Downloaded**: From MODIS, following NAME R script
**Spatial & Temporal REsolution**: Began as 1 km/year, processed into municipality/year via 'extract.R'script
**Filename**: 'not completed yet'
