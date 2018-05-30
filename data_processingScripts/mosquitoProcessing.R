## Mosquito Data Processing
## MV Evans May 29 2018

# This file extracts the MaxEnt probability of occurrence of mosquito species for each municipality 
# by taking the spatial mean. The highest value across all three species is then chosen to represent the 
# probability of a vector occuring there.


library(raster)
library(sp)
library(rgdal)
library(dplyr)
library(spdep)
library(rgeos)


#### Load Data ####

#downloaded from http://vectormap.si.edu/Mosquito_Metadata.htm

ha.janthin <- raster("../data_raw/environmental/mosiData/MaxEntModels/ha_janthin.tif")
ha.leuco <- raster("../data_raw/environmental/mosiData/MaxEntModels/ha_leuco.tif")
sa.chloro <- raster("../data_raw/environmental/mosiData/MaxEntModels/sa_chloro.tif")
#not using, but here it is anyways
# ae.aegypti <- raster("data_raw/environmental/mosiData/MaxEntModels/ae_aegypti.tif")

#shapefile of municipalities
brazil <- readOGR("../data_clean","BRAZpolygons")

#### Extract Species Level Values ####

# get mean per muni, dropping missing data
ha.leuco.prob <- extract(ha.leuco, brazil, fun = mean, na.rm = T)
ha.janthin.prob <- extract(ha.janthin, brazil, fun = mean, na.rm = T)
sa.chloro.prob <- extract(sa.chloro, brazil, fun = mean, na.rm = T)

mosi.prob <- data.frame(muni.no = brazil$muni_no, ha.leuco = ha.leuco.prob, ha.janthin = ha.janthin.prob,
                              sa.chloro = sa.chloro.prob)
# save as raw data
write.csv(mosi.prob, "../data_raw/environmental/mosquitoOccurence.csv", row.names = F)

# gather into long format & find maximum
mosi.occ <- mosi.prob %>%
  tidyr::gather(species, probability, ha.leuco:sa.chloro) %>%
  group_by(muni.no) %>%
  summarise(vector.prob = max(probability, na.rm = T))

### NEED TO PERMUTE FOR MISSING TWO MUNIS ###

# get neighbors
row.names(brazil) <- as.character(brazil@data$muni_no)
neighbors <- poly2nb(brazil)
mat <- nb2mat(neighbors, zero.policy=T)
colnames(mat) <- as.character(brazil@data$muni_no)

missInds <- which(mosi.occ$vector.prob==-Inf)

for (i in missInds){
  temp <- mat[rownames(mat)==mosi.occ$muni.no[i],]
  nbs <- names(temp[temp>0]) #get muni.no of neighbors
  nbValue <- mosi.occ %>%
    filter(muni.no %in% nbs) %>%
    summarise(perm.prob = mean(vector.prob, na.rm = T))
  mosi.occ$vector.prob[i] <- nbValue$perm.prob
}

# Fernando de Noronha (# 2605459) is an island w/ no neighbors
mosi.occ$vector.prob[mosi.occ$muni.no == 260545] <- 0 

# Fix Pinto Bandeira, which we are combining into Bento Concalves
pintoArea <- 105.82 #km2, muni.no 431454
bentoArea <- 276.6845 #km2, muni.no 430210

inds2fix <- which(mosi.occ$muni.no %in% c(431454,430210))
toAppend <- mosi.occ[inds2fix,]
toAppend <- toAppend %>%
  #scale by area
  mutate(scaled=case_when(
    muni.no==431454 ~ vector.prob*pintoArea,
    muni.no==430210 ~ vector.prob*bentoArea
  )) %>%
  dplyr::select(-vector.prob) %>%
  #take average of scaled values
  summarise(vector.prob=sum(scaled)/(pintoArea+bentoArea)) %>%
  #add in appropriate muni name and number
  mutate(muni.no=430210) %>%
  select(muni.no, vector.prob)

#drop fixed rows
mosi.occ <- mosi.occ[-inds2fix,]
#add new ones
mosi.occ <- as.data.frame(rbind(mosi.occ, toAppend))

# Save the data
saveRDS(mosi.occ, "../data_clean/environmental/mosiProb.rds")
