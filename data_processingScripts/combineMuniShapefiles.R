## This document combines all the municipality shapefiles that are currently by state, downloaded from IBGE, into one for Brazil.
# Michelle V Evans

library(rgdal)
library(raster)
library(rgeos)
library(maptools)

#get files
filesToMerge <- list.files("municipio_2001/", pattern=".shp")
layersMerge <- gsub(".shp", "", filesToMerge)

#set crs for the shapefiles
crs <- CRS("+init=epsg:4326")

first <- readOGR(dsn="municipio_2001", layersMerge[1])
colnames(first@data) <- toupper(colnames(first@data))
first <- first[,c('GEOCODIGO','NOME')]
proj4string(first) <- crs

for (i in 2:length(layersMerge)){
  toAdd <- readOGR(dsn="municipio_2001", layersMerge[i])
  colnames(toAdd@data) <- toupper(colnames(toAdd@data))
  toAdd <- toAdd[,c('GEOCODIGO','NOME')]
  proj4string(toAdd) <- crs
  first <- rbind(first, toAdd, makeUniqueIDs=T)
}
rm(toAdd,i)

#dissolve on GEOCODIGO to add islands to multipart polygons
brazDissolve <- unionSpatialPolygons(first, IDs=first$GEOCODIGO)
#add data back to this
brazData <- unique(first@data)
rownames(brazData) <- brazData$GEOCODIGO
newBrazil <- SpatialPolygonsDataFrame(brazDissolve, brazData)

#adjust small municode error (Pinto Bandeira is listed incorrectly as 431453, not 431454). See http://cidades.ibge.gov.br/xtras/perfil.php?codmun=431454
newBrazil@data$muni.no <- as.numeric(substr(as.character(newBrazil$GEOCODIGO),1,6))
newBrazil@data$muni.no[newBrazil@data$muni.no==431453] <- 431454

brazShapefile <- newBrazil[,c('muni.no', 'NOME')]
colnames(brazShapefile@data)[2] <- "muni.name"


writeOGR(brazShapefile, dsn=".", layer="BRAZpolygons", driver="ESRI Shapefile")


## Additional Correction (2018-05-31) ----

# Because we are using shapefiles that correspond to 2001 municipality boundaries, we must combine 
# Pinto Bandeira (431454) and Bento Goncalves (430210) into just Bento Goncalves.

# load incorrect shapefile 
braz.shape <- readOGR("../data_clean", "BRAZpolygons")

# adjust Pinto muni.no to equal Bento
braz.shape$muni_no[braz.shape$muni_no==431454] <- 430210

#dissolve
braz.Dissolve <- unionSpatialPolygons(braz.shape, IDs=braz.shape$muni_no)
# add muni nos in
dissolve.muni <- data.frame(muni.no = names(braz.Dissolve))
rownames(dissolve.muni) <- names(braz.Dissolve)
braz.diss <- SpatialPolygonsDataFrame(braz.Dissolve, dissolve.muni)

# check with model Munis
preds <- readRDS("../data_out/MS_results/OneModel/wholePredictions.rds")
modelMunis <- preds$muni.no
modelMunis[!(modelMunis %in% braz.diss$muni.no)]
braz.diss$muni.no[!(braz.diss$muni.no %in% modelMunis)]

#if good, then save (this replaces old one with Pinto Bandeira)
writeOGR(braz.diss, dsn = "../data_clean/", layer = "BRAZpolygons", driver = "ESRI Shapefile", overwrite_layer = T)
