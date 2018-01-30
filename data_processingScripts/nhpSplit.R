## Non-human primate split
## MV Evans, Jan 3 2017
## This document splits the municipalities based on the range of non-human primates. This will result in two 
## contiguous geographic areas that we will model seperately to examine if different processes are at work.

# We chose to split based on species richness becuase we noticed that the initial predictions had seasonality in the SE
# corner of the country, but not in the NW corner. The only static (i.e. non-seasonal) variable in the model was species
# richness, which was also the second most important variable. We then chose to split the municipalities spatially
# based on the species richness, following natural breaks in the data.

## 1. Load Packages --------
# set wd to source file
library(rgdal)
library(dplyr)
library(ggplot2)
library(viridis)
library(rgeos)
library(sf)

## 2. Load Data ------------

# we will load the data that has already been split into training and testing so that it can
# easily be compared to the one-model method

test.data <- readRDS("../data_clean/TestingDataSpat2.rds")
train.data <- readRDS("../data_clean/TrainingDataSpat2.rds")

#municipality shapefile
munis <- st_read("../data_clean", "BRAZpolygons")

#primateRichness by municipality
primRichness <- readRDS("../data_clean/environmental/primRichness.rds")

## 3. Maps of Species Richness ------

primateMap <- munis %>%
  dplyr::select(muni.no = muni_no) %>%
  left_join(primRichness, by = "muni.no") #NA is pinto bandiera that doesn't exist

ggplot() +
  # municipality polygons
  geom_sf(data = primateMap, aes(fill = spRich), color = NA) +
  #color those with 6 or more species orange
  geom_sf(data = primateMap[primateMap$spRich>=6,], fill = "orange", color = NA) +
  scale_fill_viridis()

# 4. Get nhp split index -----

# add splitting variable to initial map
primateMap$primSplit <- "less"
primateMap$primSplit[primateMap$spRich>=6] <- "above5"


# create dissolved polygon
manySpecies <- primateMap %>%
  group_by(primSplit) %>%
  summarize() %>%
  filter(primSplit == "above5") %>%
  ungroup() %>%
  st_cast("POLYGON") %>%
  #select contiguous polygon only
  slice(3)


#buffer the manySpecies polygon to get rid of holes
speciesBuffer <- st_buffer(manySpecies, dist = units::set_units(0.001, degree))

#need to buffer again as a polygons object
speciesBuffer2 <- as(speciesBuffer, 'Spatial')
speciesNoHole <- SpatialPolygons(list(Polygons(list(speciesBuffer2@polygons[[1]]@Polygons[[1]]),ID=1)))
proj4string(speciesNoHole) <- CRS("+init=epsg:4326")
speciesBuffer <- as(speciesNoHole, "sf")
#holes may be okay, trying to see what falls in it
within <- munis[st_contains(speciesBuffer, munis)[[1]],]

#create index of the split
primateMap$trueSplit <- "less"
primateMap$trueSplit[primateMap$muni.no %in% within$muni_no] <- "above5"
#manually fix those along the coast that aren't included but are true holes
manualFix <- c(140070, 140060, 140050, 140045, 140040, 140023, 110007, 110006, 110005, 110003)
primateMap$trueSplit[primateMap$muni.no %in% manualFix] <- "above5"


ggplot() +
  # municipality polygons
  geom_sf(data = primateMap, aes(fill = trueSplit), color = NA) 

#save index
indexSplit <- primateMap %>%
  select(muni.no, above5split = trueSplit) %>%
  st_set_geometry(NULL)

saveRDS(indexSplit, "../data_clean/environmental/twoModelSplit.rds")
#also, you can just load this file becuase it doesn't change with new training and testing data
#indexSplit <- readRDS("../data_clean/environmental/twoModelSplit.rds")

# 5. Split training and testing data -----

highNHP <- filter(indexSplit, above5split == "above5")
test.data.lowNHP <- filter(test.data, !(muni.no %in% highNHP$muni.no)) #28 cases
test.data.highNHP <- filter(test.data, (muni.no %in% highNHP$muni.no)) #7 cases

train.data.lowNHP <- filter(train.data, !(muni.no %in% highNHP$muni.no))  #67 cases
train.data.highNHP <- filter(train.data, (muni.no %in% highNHP$muni.no)) #only 14 cases

#70/30 split seems to be kept relatively well

# save new datasets

saveRDS(test.data.lowNHP, "../data_clean/TestingDataLowNHP2.rds")
saveRDS(test.data.highNHP, "../data_clean/TestingDataHighNHP2.rds")

saveRDS(train.data.lowNHP, "../data_clean/TrainingDataLowNHP2.rds")
saveRDS(train.data.highNHP, "../data_clean/TrainingDataHighNHP2.rds")
