## This document combines all the municipality shapefiles that are currently by state, downloaded from IBGE, into one for Brazil.
# Michelle V Evans
library(rgdal)
library(raster)
library(rgeos)

## Important Note: This are municipalities as they were in 2001!

#get files
# files were downloaded from ftp://geoftp.ibge.gov.br/organizacao_do_territorio/malhas_territoriais/malhas_municipais/municipio_2001/
# files with mu code are municipalities
filesToMerge <- list.files("municipio_2001/", pattern=".shp")
layersMerge <- gsub(".shp", "", filesToMerge)

first <- readOGR(dsn="municipio_2001", layersMerge[1])
colnames(first@data) <- toupper(colnames(first@data))
first <- first[,'GEOCODIGO']


for (i in 2:length(layersMerge)){
  toAdd <- readOGR(dsn="municipio_2001", layersMerge[i])
  colnames(toAdd@data) <- toupper(colnames(toAdd@data))
  toAdd <- toAdd[,'GEOCODIGO']
  colnames(toAdd@data)[1] <- paste0("GEOCODIGO.",i)
  first <- union(first, toAdd)
}

plot(first)

newBrazil <- first
library(tidyr)
#combine all the columns into one
brazilData <- newBrazil@data
brazilData <- unite(brazilData, newCode, GEOCODIGO:GEOCODIGO.27, sep='')
brazilData$newCode <- gsub("NA", "", brazilData$newCode)

length(newBrazil)
newBrazil@data <- brazilData

#set projection (SIRGAS 2000, also known as WGS84)
proj4string(newBrazil) <- CRS('+proj=longlat +ellps=GRS80 +towgs84=0,0,0 +no_defs')

#adjust codes to match pop data
newBrazil@data$newCode <- substr(newBrazil@data$newCode,1,6)
newBrazil@data$muni.no <- as.numeric(newBrazil@data$newCode)
newBrazil <- newBrazil[,'muni.no']


writeOGR(newBrazil, dsn="../data_clean", layer="BRAZpolygons", driver="ESRI Shapefile")
