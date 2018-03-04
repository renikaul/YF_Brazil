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
library(dplyr)

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
test <- over(brazil, primates, returnList=T)
#get number of species within each municipality
spRich <- lapply(test, nrow)
spRich2 <- data.frame(spRich=do.call(c, spRich))
spRich2$muni.no <- brazil$muni_no
spRich2$muni.name <- brazil$muni_name
#drop Pinto Bandeira (431454)
speciesRichness <- spRich2[spRich2$muni.no!=431454,]

#write to csv
write.csv(speciesRichness, "../data_raw/environmental/primateRichness.csv", row.names = F)

#save the names of species found in each municipality

#use a for loop to extract the species names in each muni
species.matrix <- matrix(nrow=5561, ncol = 93) #row = muni, col = species
colnames(species.matrix) <- levels(primates$binomial)
rownames(species.matrix) <- brazil$muni_no
for (i in 1:5561){ #loop over munis
  tmp.species <- test[[i]]$binomial
  #fill in a one for all species found in that muni
  species.matrix[i,colnames(species.matrix) %in% tmp.species] <- 1
}
  
# save
write.csv(species.matrix, "../data_raw/environmental/primateSpeciesIDmuni.csv", row.names=T)
  
#get species ID for LRR and HRR
species.matrix <- read.csv("../data_raw/environmental/primateSpeciesIDmuni.csv")
colnames(species.matrix)[1] <- "muni.no"

#switch to longform
species.id <- tidyr::gather(species.matrix, species, present, Alouatta.arctoidea:Saimiri.vanzolinii)

#combine with data on nhp split
nhp.split <- readRDS("../data_clean/environmental/twoModelSplit.rds")

#get list of species per split
species.split <- species.id %>%
  left_join(nhp.split, by = "muni.no") %>%
  group_by(above5split, species) %>%
  #get total number of munis with that species per split
  summarise(presence = sum(present, na.rm = T)) %>%
  tidyr::spread(above5split, presence) %>%
  #drop species found in neither 
  filter(!(above5 == 0 & less == 0))

#number of munis is uninformative because LRR has so many small ones
#change to 1 or 0
species.split$above5[species.split$above5>0] <- 1
species.split$less[species.split$less>0] <- 1

#chagne column names to match LRR and HRR
colnames(species.split)[2:3] <- c("HRR", "LRR")

#save
write.csv(species.split, "../data_clean/environmental/speciesByModel.csv", row.names = F)
