## This file processes the shapefiles of IUCN Red List mammals to get the amount of overlap of NHP habitat 
# and cropland/agricultural land per muni per year (land use is yearly).

# Steps
# Portion shapefiles into more manageable chunk (only the genera we want and brazil) (save this seperately)
# for each genus, calculate proportion of municipality area that is both cropland and falls within range map of genus
# sum these values up over all nine genera, resulting in value of 0 - 9

# seperate value: number of species that have a range within the municipality (static over time)
library(maptools)
library(rgdal)
library(sp)
library(raster)
library(rgeos)
library(doParallel)
library(foreach)

# #load IUCN shapefile
# iucn <- readOGR("../../TERRESTRIAL_MAMMALS", "TERRESTRIAL_MAMMALS")
# 
# # subset to brazil and genera of interest
# # genera based on Bicca-Marques 2010 and Hamrick et al 2017
# genera <- c("Ateles", "Aotus", "Alouatta", "Saimiri", "Cebus", "Callicebus", "Callithrix", "Saguinus", "Lagothrix")
# 
# primates <- iucn[iucn@data$genus_name %in% genera,]
# writeOGR(primates, "../data_raw/environmental/NHPdata", "primatePolygons", "ESRI Shapefile")

#now can just load this without reading in 900mb file above
primates <- readOGR("../data_raw/environmental/NHPdata", "primatePolygons")

#load brazil shapefile
brazil <- readOGR("../data_clean","BRAZpolygons")

#group primates by genus
primateDissolve <- unionSpatialPolygons(primates, IDs=primates$genus_name)
primData <- data.frame(genus=unique(primates$genus_name))
rownames(primData) <- primData$genus
primateGenus <- SpatialPolygonsDataFrame(primateDissolve, primData) #note strange holes due to rivers

## Fix holes
fix.holes<-function(poly.dat){
  n.poly.all<-numeric()
  for (k in 1:nrow(poly.dat@data)){
    n.poly.all[k]<-length(poly.dat@polygons[[k]]@Polygons)
  }
  has.hole<-which(n.poly.all>1)
  n.poly<-n.poly.all[has.hole]
  
  for (k in 1:length(has.hole)){
    for (m in 2:n.poly[k]){
      poly.dat@polygons[[has.hole[k]]]@Polygons[[m]]@hole<-T
    }
  }
  return(poly.dat)
}

primHole <- fix.holes(primateGenus)
primHole <- SpatialPolygons(primHole@polygons, proj4string = primHole@proj4string)


# stack all of the rasters and reclassify, then loop over the genera
#files <- c("../../envCovariates/2001landcoverTest.tif", "../../envCovariates/2002landcoverTest.tif")
files <- list.files("../../landCover/landCoverTIF", full.names=T)
#rasterTemplate <- raster(files[1]) #high mem
rasterTemplate <- raster("../../envCovariates/2001landcoverTest.tif") #desktop
primateRaster <- rasterize(primHole, rasterTemplate, fun='count') #values of 1 - 9
writeRaster(primateRaster, "../data_raw/environmental/NHPdata/primateRaster2.tif")
primateRaster <- raster("../data_raw/environmental/NHPdata/primateRaster.tif")

system.time({ #12 ish hours
  cl <- makeCluster(13)
  registerDoParallel(cl)
primateAll <- foreach(i=1:length(files), .combine=cbind, .packages=c("raster", "rgdal", "rgeos", "maptools", "sp")) %dopar% {
  landCover <- raster(files[i])
  #reclassify
  landCover[landCover<11.5] <- 0
  landCover[landCover>14.5] <- 0
  landCover[landCover!=0] <- 1
  primateHuman <- primateRaster * landCover
  #extract mean per municipality (giving proportion)
  primateProp <- extract(primateHuman, brazil, fun=mean, na.rm=T)
  write.csv(primateProp, paste0("../../landCover/primate/primateProp", (2000+i), ".csv"),
            row.names = F)
  return(primateProp)
  } #end foreach
stopCluster(cl)
})
#adjust for NaNs (which were not within any primate habitat and so are 0)
primateAll[is.na(primateAll)] <- 0
primateDF <- as.data.frame(primateAll)
colnames(primateDF) <- seq(2001,2013)
primateDF$muni.no <- brazil@data$muni_no
primateDF$muni.name <- brazil@data$muni_name

write.csv(primateDF, "../data_raw/environmental/primateProp.csv", row.names = F)
