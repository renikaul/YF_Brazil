## Non-human primate split
## MV Evans, Jan 3 2017
## This document splits the municipalities based on the range of non-human primates. This will result in two 
## contiguous geographic areas that we will model seperately to examine if different processes are at work.


## 1. Load Packages --------
# set wd to source file
library(rgdal)
library(dplyr)
library(ggplot2)
library(viridis)

## 2. Load Data ------------

# we will load the data that has already been split into training and testing so that it can
# easily be compared to the one-model method

test.data <- readRDS("../data_clean/TestingDataSpat.rds")
train.data <- readRDS("../data_clean/TrainingDataSpat.rds")

#nhp maps
primates <- readOGR("../data_raw/environmental/NHPdata", "primateSpecies")
primGenus <- readOGR("../data_raw/environmental/NHPdata", "primateGenus")
#municipality shapefile
munis <- readOGR("../data_clean", "BRAZpolygons")
#fortify for ggplot2
brazFortified <- fortify(munis, region = "muni_no") %>% 
  mutate(muni.no = as.numeric(id))
#primateRichness by municipality
primRichness <- readRDS("../data_clean/environmental/primRichness.rds")

#all data
all.data <- readRDS("../data_clean/FinalData.rds")
pop2001 <- all.data %>%
  filter(year==2001) %>%
  select(popLog10, muni.no) %>%
  group_by(muni.no) %>%
  slice(1) %>%
  ungroup()

## 3. Maps of Species Richness ------

primateMap <- left_join(brazFortified, primRichness, by = "muni.no")
popMap <- left_join(brazFortified, pop2001, by = "muni.no")

ggplot() +
  geom_polygon(data = popMap, aes(fill = popLog10,
                                  x = long,
                                  y = lat,
                                  group = group)) +
  scale_fill_viridis()

ggplot() +
  # municipality polygons
  geom_polygon(data = primateMap, aes(fill = spRich, 
                                    x = long, 
                                    y = lat, 
                                    group = group)) +
  geom_polygon(data = primateMap[primateMap$spRich>=6,], aes(
                                                           x = long, 
                                                           y = lat, 
                                                           group = group),
fill = "orange") +
  scale_fill_viridis()

