# MetaData for Environmental Covariates:

## NDVI

**Downloaded**: From MODIS, following `ModisDownload.R` script. Dataset is MOD13A3

**Spatial & Temporal Resolution**: Began as 1 km/month, processed into municipality/month via 'MODISextract.R' script

**Filename**: NDVIall.csv

## Land Surface Temperature (LST)

**Downloaded**: From MODIS, following `ModisDownload.R` script. Dataset is MOD11C3

**Spatial & Temporal Resolution**: Began as 5 km/month days, processed into mean Temperature/municipality/month via 'MODISextract.R' script

**Filename**: meanTall.csv

## NHP/Agricultural Overlap

**Downloaded**: From MODIS, following `ModisDownload.R` script. Dataset is MCD12Q1.

**Spatial & Temporal Resolution**: Began as 1 km/year, processed into proportion primate and agricultural overlap per year via `NHPprocessing.R` script

**Filename**: primateProp.csv

## Rainfall

**Downloaded**: From Tropical Rainfall Measuring Mission, downloaded via command line using `trmmDownload.sh` script (can run through R). Pay attention to notes in comments at top of script or it will not work.

**Spatial & Temporal Resolution**: Began as 4 km/month (recorded as average hourly rainfall in mm), recorded into spatial mean per municipality/month

**Filename**: meanRFall.csv

## Fire

**Downloaded**: Data is the LANCE Active Fire Dataset (MCD14ML). It is point data on fires (detected at the 1 km resolution), with date and time attributes. It was downloaded for 2001 - 2013 via https://earthdata.nasa.gov/earth-observation-data/near-real-time/firms/active-fire-data.

**Spatial and Temporal Resolution**: Vector data (i.e. points) by date and time. Combined into number of fires per municipality per month via `fireProcess.R`

**Filename**: fires.csv

## Primate Maps

**Downloaded**: Data is the IUCN Redlist of Terrestrial Mammal Shapefiles (http://www.iucnredlist.org/technical-documents/spatial-data). This was processed via 'primateProcessing.R'. 


*Primate Proportions:* km^2/year. 

This data is the sum of each municipalities relative area that is both agricultural and falls within a primate genus range. It is summed over all 9 genuses. For example, if a municipality was 50% agricultural land, but fell within the range of all 9 genera, its value would be 4.5. If a municipality was 10% agricultural land, with all of that 10% falling within the range of one genus, and then half of that (5%) falling within the range of another, its value would be 0.15. 

Filename: primateProp.csv

*Primate Richness*: This is equal to the original resolution of the shapefiles and is not temporal. It is the total number of NHP species (of the 9 genera) found in that municipality.

Filename: primateRichness.csv

## Mosquito Data

MaxEnt models of occurence of Ha. janthinomys, Ha. leucocelaneus, and Sa. chloropterus were downloaded from VectorMap. It was created in 2011, so is not temporal, and is at a 0.04 degree (~4km) resolution. The spatial mean of this data was taken per municipality and then the highest probability of occurence across species was chosen to represent the maximum probability of vector occurence.

Filename: mosquitoOccurence.csv (raw values per species)
