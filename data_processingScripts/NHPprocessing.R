## This file processes the shapefiles of IUCN Red List mammals to get the amount of overlap of NHP habitat 
# and cropland/agricultural land per muni per year (land use is yearly).

# Steps
# Portion shapefiles into more manageable chunk (only the genera we want and brazil) (save this seperately)
# for each genus, calculate proportion of municipality area that is both cropland and falls within range map of genus
# sum these values up over all nine genera, resulting in value of 0 - 9

# seperate value: number of species that have a range within the municipality (static over time)

library(rgdal)
library(sp)
library(raster)
library(rgeos)
library(maptools)

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

# stack all of the rasters and reclassify, then loop over the genera
files <- c("../../envCovariates/2001landcoverTest.tif", "../../envCovariates/2002landcoverTest.tif")

landcoverStack <- stack(files)


#mask to Brazil first to save time
humanBrazilStack <- crop(humanStack, brazil)
rasterTemplate <- humanBrazilStack[[1]]
#reclassify so human modified=1
humanStack <- landcoverStack
humanStack[humanStack<11.5] <- 0
humanStack[humanStack>14.5] <- 0
humanStack[humanStack!=0] <- 1

    #create raster whose values is sum of all genera present there
    primateRaster <- rasterize(primateGenus, rasterTemplate, fun=sum) 
    #multiply so 1-9 is primate and human, 0 is the rest
    primateHuman <- primateRaster * humanStack
    #extract mean per municipality (giving proportion)
    primateProp <- extract(primateHuman, brazil, fun=mean, na.rm=T)

