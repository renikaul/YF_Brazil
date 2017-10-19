## This file processes the shapefiles of IUCN Red List mammals to get the amount of overlap of NHP habitat 
# and cropland/agricultural land per muni per year (land use is yearly). It also calculates the species richness
# per municipality.

library(maptools)
library(rgdal)
library(sp)
library(sf)
library(raster)
library(rgeos)
library(doParallel)
library(foreach)

#load IUCN shapefile
iucn <- readOGR("../../TERRESTRIAL_MAMMALS", "TERRESTRIAL_MAMMALS")

# subset to brazil and genera of interest
# genera based on Bicca-Marques 2010 and Hamrick et al 2017
genera <- c("Ateles", "Aotus", "Alouatta", "Saimiri", "Cebus", "Callicebus", "Callithrix", "Saguinus", "Lagothrix")

primates <- iucn[iucn@data$genus_name %in% genera,]
writeOGR(primates, "../data_raw/environmental/NHPdata/", "primateSpecies", driver="ESRI Shapefile")

#load brazil shapefile
brazil <- readOGR("../data_clean","BRAZpolygons")

#### Proportion Cropland + NHP ####

# Steps
# Portion shapefiles into more manageable chunk (only the genera we want and brazil) (save this seperately)
# for each genus, calculate proportion of municipality area that is both cropland and falls within range map of genus
# sum these values up over all nine genera, resulting in value of 0 - 9

# seperate value: number of species that have a range within the municipality (static over time)

# group primates by genus
# primateDissolve <- unionSpatialPolygons(primates, IDs=primates$genus_name)
# primData <- data.frame(genus=unique(primates$genus_name))
# rownames(primData) <- primData$genus
# primateGenus <- SpatialPolygonsDataFrame(primateDissolve, primData) #note strange holes due to rivers

# primateGenus was then exported to ArcGIS to rasterize the polygons (r doesn't deal with holes properly)
# the rasterized polygons were then run through 'Cell Statistics' in Arc to get the sum per cell (ie number of species whose range inclues that cell)
# this was done with the landcover data as a template, so it all matches up
# results in primateRaster.tif

# stack all of the rasters and reclassify, then loop over the genera
#files <- c("../../envCovariates/2001landcoverTest.tif", "../../envCovariates/2002landcoverTest.tif")
files <- list.files("../../landCover/landCoverTIF", full.names=T)
primateRaster <- raster("../../landCover/primate/primateRaster.tif")

system.time({ #2 hours
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

#### Species Richness ####

#load species shapfile, created at beginning of md
primates <- readOGR("../data_raw/environmental/NHPdata/", "primateSpecies")
primates$value <- 1

#extracts all the polygons that fall within the municipality
test <-over(brazil, primates, returnList=T)
#get number of species within each municipality
spRich <- lapply(test, nrow)
spRich2 <- data.frame(spRich=do.call(c, spRich))
spRich2$muni.no <- brazil$muni_no
spRich2$muni.name <- brazil$muni_name
#drop Pinto Bandeira (431454)
speciesRichness <- spRich2[spRich2$muni.no!=431454,]

#write to csv
write.csv(speciesRichness, "../data_raw/environmental/primateRichness.csv", row.names = F)
