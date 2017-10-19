### This script combines the covariate data from the raw to clean folders
## MV Evans October 14 2017

## List of Covariates:
  # Rainfall (mean)
  # NDVI
  # Temperature (mean)
  # Fire (density)
  # Non-Human Primate (proportion overlapping with agricultural land, total species richness per muni)

# All of the Data is wide, but needs to switch to long to match cases
# Merge columns are muni.no, muni.name, year(2001), cal.month (7), month.no (168)examples in parentheticals

library(tidyr)
library(plyr)
library(dplyr)
library(lubridate)
library(raster)

#Random functions
month.noFunc <- function(year, month, startYear, startMonth){
  yearsPast <- year-startYear
  monthsPast <- month-startMonth
  totalMonths <- 12*yearsPast + monthsPast + 1
  return(totalMonths)
}

jtoDate <- function(day, year){
  #' Convert day of year to Posix style date
  #' 
  #' @param day day of year (1-365)
  #' @param year ("2001")
  posixDate <- as.Date(paste(year, day), format="%Y %j", tz="")
  return(posixDate)
}

pintoArea <- 105.82 #km2, muni.no 431454
bentoArea <- 276.6845 #km2, muni.no 430210

#for spatial permutation
library(rgdal)
library(rgeos)
library(spdep)

brazil <- readOGR("../data_clean", "BRAZpolygons")

#neighbors for every polygon
row.names(brazil) <- as.character(brazil@data$muni_no)
neighbors <- poly2nb(brazil)
mat <- nb2mat(neighbors, zero.policy=T)
colnames(mat) <- as.character(brazil@data$muni_no)

####--------Rainfall ####
#rainfallMax <- read.csv("../data_raw/environmental/maxRFall.csv")
#rainfallMin <- read.csv("../data_raw/environmental/minRFall.csv")
rainfallMean <- read.csv("../data_raw/environmental/meanRFall.csv")

process_rainfall <- function(rainfallDF, type){
  #' Reformat rainfall for bagged logreg
  #' 
  #' @param rainfallDF the rainfall dataframe to process
  #' @param type whether it is the min, mean, or max (ex. "Min)
  require(dplyr)
  require(tidyr)
  newDF <- rainfallDF %>%
    #drop lagoons because no one lives there
    filter(muni.no!=430000) %>%
    #go from wide to long
    gather(date, measurement, X20010101:X20141201) %>%
    #get year column
    mutate(year= as.numeric(substr(date, 2,5))) %>%
    # get month column
    mutate(month=as.numeric(substr(date, 6,7))) %>%
    #drop date column
    dplyr::select(-date) %>%
    #calculate month.no
    mutate(month.no=month.noFunc(year=year, month=month, startYear=2001, startMonth=1))%>%
    #reorder columns to keep us sane
    dplyr::select(muni.no, muni.name, year, cal.month=month, month.no, measurement) 
  
  #rename measurement column
  measureLabel <- paste0("hourlyRainfall", type)
  colnames(newDF)[colnames(newDF)=="measurement"] <- measureLabel
  
  #switch muni name to character to avoid weird factors while merging
  newDF$muni.name <- as.character(newDF$muni.name)
  
  return(newDF)
}

#apply function to all rainfall dataframes
# newRFmin <- process_rainfall(rainfallDF=rainfallMin, type="Min")
# newRFmax <- process_rainfall(rainfallDF=rainfallMax, type="Max")
newRFmean <- process_rainfall(rainfallDF = rainfallMean, type="Mean")

# merge dataframes together into one
# RFall <- join_all(list(newRFmin, newRFmax, newRFmean), by=c("muni.no", "year", "cal.month"), type="full")

#adjust for muni corrections
inds2fix <- which(newRFmean$muni.no %in% c(431454,430210))
toAppend <- newRFmean[inds2fix,]
toAppend <- toAppend %>%
  #scale by area
  mutate(scaled=case_when(
    muni.no==431454 ~ hourlyRainfallMean*pintoArea,
    muni.no==430210 ~ hourlyRainfallMean*bentoArea
  )) %>%
  dplyr::select(-hourlyRainfallMean) %>%
  group_by(cal.month, year, month.no) %>%
  #take average of scaled values
  summarise(hourlyRainfallMean=sum(scaled)/(pintoArea+bentoArea)) %>%
  #add in appropriate muni name and number
  mutate(muni.no=430210) %>%
  mutate(muni.name="Bento Gonçalves") %>%
  #order columns appropriately to join
  dplyr::select(muni.no, muni.name, year, cal.month, month.no, hourlyRainfallMean) %>%
  ungroup()

#drop ones we needed to fix
RFmean <- newRFmean[-inds2fix,]
#add new ones
RFmean <- as.data.frame(rbind(RFmean, toAppend))

#save as R object
saveRDS(RFmean, "../data_clean/environmental/allRainfall.rds")

rm(toAppend)
####--------NDVI ####

ndvi <- read.csv("../data_raw/environmental/NDVIall.csv") #dates are julian (1-365)

ndviNew <- ndvi %>%
  #drop lagoons because no one lives there
  filter(muni.no!=430000) %>%
  #go from wide to long
  gather(date, NDVI, MOD13A3.A2001001:MOD13A3.A2014335) %>%
  #rescale NDVI
  mutate(NDVI=NDVI*0.0001) %>%
  #get year
  mutate(year=substr(date, 10,13)) %>%
  #get date
  mutate(day=substr(date, 14, 16)) %>%
  #convert date to month
  plyr::mutate(posixDate = jtoDate(day, year)) %>%
  plyr::mutate(month=month(posixDate)) %>%
  #calculate month
  mutate(month.no=month.noFunc(year=as.numeric(year), month=month, startYear=2001, startMonth=1)) %>%
  #reorganize columns
  dplyr::select(muni.no, muni.name, year, cal.month=month, month.no, NDVI)

#adjust muni name to a character
ndviNew$muni.name <- as.character(ndviNew$muni.name)

#make year numeric
ndviNew$year <- as.numeric(ndviNew$year)

### Need to fix the NAs by spatially permuted means

ndviAll <- ndviNew

spatialPermute <- function(missingMuni.no, missingMuni.name, missingMonth, missingYear, missingmonth.no, nbMat=mat){
  temp <- nbMat[rownames(nbMat)==missingMuni.no,]
  nbs <- names(temp[temp>0]) #get muni.no of neighbors
  nbValues <- ndviNew %>%
    dplyr::filter(year==missingYear) %>%
    dplyr::filter(cal.month==missingMonth) %>%
    dplyr::filter(muni.no %in% nbs) %>%
    dplyr::filter(!is.na(NDVI)) %>%
    dplyr::summarise(NDVI=mean(NDVI, na.rm=T))
  newValues <- data.frame(muni.no=missingMuni.no, muni.name=missingMuni.name, year=missingYear, cal.month=missingMonth, month.no=missingmonth.no, NDVI=nbValues[,c('NDVI')])
  #colnames(newValues) <- colnames(ndviAll)
  return(newValues)
}

#apply spatial permute to the missing rows
missInds <- which(is.na(ndviAll$NDVI))

for (i in missInds){
  newVals <- spatialPermute(missingMuni.no=ndviAll[i,1], missingMuni.name=ndviAll[i,2], missingYear=ndviAll[i,3],
                            missingMonth = ndviAll[i,4], missingmonth.no = ndviAll[i,5])
  ndviAll <- rbind(ndviAll, newVals) #append to end
}

#drop everything that we have fixed and is now appended to the end
ndviAll <- ndviAll[-missInds,]

#adjust for muni corrections
inds2fix <- which(ndviAll$muni.no %in% c(431454,430210))
toAppend <- ndviAll[inds2fix,]
toAppend <- toAppend %>%
  #scale by area
  mutate(scaled=case_when(
    muni.no==431454 ~ NDVI*pintoArea,
    muni.no==430210 ~ NDVI*bentoArea
  )) %>%
  dplyr::select(-NDVI) %>%
  group_by(cal.month, year, month.no) %>%
  #take average of scaled values
  summarise(NDVI=sum(scaled)/(pintoArea+bentoArea)) %>%
  #add in appropriate muni name and number
  mutate(muni.no=430210) %>%
  mutate(muni.name="Bento Gonçalves") %>%
  #order columns appropriately to join
  dplyr::select(muni.no, muni.name, year, cal.month, month.no, NDVI) %>%
  ungroup()

#drop ones we needed to fix
ndviAll <- ndviAll[-inds2fix,]
#add new ones
ndviAll <- as.data.frame(rbind(ndviAll, toAppend))

#save as RDS object
saveRDS(ndviAll, "../data_clean/environmental/allNDVI.rds") 
  
#####----------Temperature ####
# tempMax <- read.csv("../data_raw/environmental/maxTall.csv")
# tempMin <- read.csv("../data_raw/environmental/minTall.csv")
tempMean <- read.csv("../data_raw/environmental/meanTall.csv")

process_temp <- function(tempDF, type){
  #' Reformat temperature for bagged logreg
  #' 
  #' @param tempDF the temperature dataframe to process
  #' @param type whether it is the min, mean, or max (ex. "Min)
  require(dplyr)
  require(tidyr)
  newDF <- tempDF %>%
      #drop lagoons because no one lives there
      filter(muni.no!=430000) %>%
      #reorder columns
      dplyr::select(muni.no, muni.name, month100:month9) %>% #double check columns match when running
      #go from wide to long
      gather(date, measurement, month100:month9) %>%
      #rescale temperature and change to C
      mutate(measurement=(measurement*0.02)-273.15) %>%
      #get month.no
      mutate(month.no=as.numeric(gsub("month", "", date))) %>%
      #get year
      arrange(month.no) %>%
      mutate(year=rep(2001:2014, each=5561*12)) %>% #repeat each year number of munis *12
      #get month (remainder, then correct for 12)
      mutate(cal.month=case_when(
        (month.no %% 12) !=0 ~ month.no %% 12,
        (month.no %% 12) ==0 ~ 12
          )
        ) %>%
      #drop date
      dplyr::select(muni.no, muni.name, year, cal.month, month.no, measurement)
  

    #rename measurement column
    measureLabel <- paste0("temp", type)
    colnames(newDF)[colnames(newDF)=="measurement"] <- measureLabel
    
    #muni.name as character
    newDF$muni.name <- as.character(newDF$muni.name)
      
    return(newDF)
}      

#apply function to all temperature dataframes
# newTmin <- process_temp(tempDF=tempMin, type="Min")
# newTmax <- process_temp(tempDF=tempMax, type="Max")
newTmean <- process_temp(tempDF=tempMean, type="Mean")

#merge dataframes together into one
# tempAll <- join_all(list(newTmin, newTmax, newTmean), by=c("muni.no", "year", "cal.month", "month.no"), type="full")

tempAll <- newTmean

#---two muni x month have NA due to cloud cover

spatialPermute <- function(missingMuni.no, missingMuni.name, missingMonth, missingYear, missingmonth.no, nbMat=mat){
  temp <- nbMat[rownames(nbMat)==missingMuni.no,]
  nbs <- names(temp[temp>0]) #get muni.no of neighbors
  nbValues <- newTmean %>%
    dplyr::filter(year==missingYear) %>%
    dplyr::filter(cal.month==missingMonth) %>%
    dplyr::filter(muni.no %in% nbs) %>%
    dplyr::filter(!is.na(tempMean)) %>%
    dplyr::summarise(tempMean=mean(tempMean, na.rm=T))
  newValues <- data.frame(muni.no=missingMuni.no, muni.name=missingMuni.name, year=missingYear, cal.month=missingMonth, month.no=missingmonth.no, tempMean= nbValues[,c('tempMean')])
  return(newValues)
}

#apply spatial permute to the missing rows
missInds <- which(is.na(tempAll$tempMean))

for (i in missInds){
  newVals <- spatialPermute(missingMuni.no=tempAll[i,1], missingMuni.name=tempAll[i,2], missingYear=tempAll[i,3],
                 missingMonth = tempAll[i,4], missingmonth.no = tempAll[i,5])
  tempAll <- rbind(tempAll, newVals) #append to end
}

#drop everything that we have fixed and appended
tempAll <- tempAll[-missInds,]

#adjust for muni corrections
inds2fix <- which(tempAll$muni.no %in% c(431454,430210))
toAppend <- tempAll[inds2fix,]
toAppend <- toAppend %>%
  #scale by area
  mutate(scaled=case_when(
    muni.no==431454 ~ tempMean*pintoArea,
    muni.no==430210 ~ tempMean*bentoArea
  )) %>%
  dplyr::select(-tempMean) %>%
  group_by(cal.month, year, month.no) %>%
  #take average of scaled values
  summarise(tempMean=sum(scaled)/(pintoArea+bentoArea)) %>%
  #add in appropriate muni name and number
  mutate(muni.no=430210) %>%
  mutate(muni.name="Bento Gonçalves") %>%
  #order columns appropriately to join
  dplyr::select(muni.no, muni.name, year, cal.month, month.no, tempMean) %>%
  ungroup()

#drop ones we needed to fix
tempAll <- tempAll[-inds2fix,]
#add new ones
tempAll <- as.data.frame(rbind(tempAll, toAppend))

#save as R object
saveRDS(tempAll, "../data_clean/environmental/meanTemperature.rds") 


####--------fire####

fire <- read.csv("../data_raw/environmental/fires.csv")[,-1] #drop extra row names

fireNew <- fire %>%
  #drop lagoons because no one lives there
  filter(muni.no!=430000) %>%
  #go from wide to long
  gather(date, numFire, X2001month1:X2014month12) %>%
  #get year
  mutate(year=as.numeric(substr(date, 2,5))) %>%
  #get month
  mutate(cal.month=as.numeric(substr(date, 11, length(date)))) %>%
  #calculate month
  mutate(month.no=month.noFunc(year=as.numeric(year), month=cal.month, startYear=2001, startMonth=1)) %>%
  #reorganize columns
  dplyr::select(muni.no, muni.name, year, cal.month, month.no, numFire)

#fix muni issue by summing fires across 431454 and 430210 (no fires in either so not super important, but still)
fireNew$fixID <- fireNew$muni.no
fireNew$fixID[fireNew$muni.no==431454] <- 430210
fireNew$muni.name[fireNew$muni.no==431454] <- unique(fireNew$muni.name[fireNew$muni.no==430210])
  
fireNew2 <- fireNew %>%
  group_by(fixID, muni.name, year, cal.month, month.no) %>%
  summarise_at(c("numFire"), sum) %>%
  ungroup() %>%
  rename(muni.no=fixID)

#add in area and fire density
brazilProj <- spTransform(brazil, CRS("+proj=aea +lat_1=-5 +lat_2=-42 +lat_0=-32 +lon_0=-60 +x_0=0 +y_0=0 +ellps=aust_SA +units=km")) #change projection to special SAmerican thing, Albers Conic
brazilArea <- data.frame(cbind(muni.no=brazil@data$muni_no, area=gArea(brazilProj, byid=T)))
#bento area is actually pento + bento
brazilArea$area[brazilArea$muni.no==430210] <- sum(brazilArea$area[brazilArea$muni.no==430210], brazilArea$area[brazilArea$muni.no==431454])

#add to fire dataframe and get density
fireDens <- fireNew2 %>%
  left_join(brazilArea, by="muni.no") %>%
  mutate(fireDens=numFire/area)

#save as R object
saveRDS(fireDens, "../data_clean/environmental/numFires.rds")

####--------Primate####
primate <- read.csv("../data_raw/environmental/primateProp.csv")

primNew <- primate %>%
  #drop lagoons because no one lives there
  filter(muni.no!=430000) %>%
  #go from wide to long
  gather(date, primProp, X2001:X2013) %>%
  #get year
  mutate(year=as.numeric(substr(date, 2,5))) %>%
  #reorganize columns
  dplyr::select(muni.no, muni.name, year, primProp)

#adjust for muni corrections
inds2fix <- which(primNew$muni.no %in% c(431454,430210))
toAppend <- primNew[inds2fix,]
toAppend <- toAppend %>%
  #scale by area
  mutate(scaled=case_when(
    muni.no==431454 ~ primProp*pintoArea,
    muni.no==430210 ~ primProp*bentoArea
  )) %>%
  dplyr::select(-primProp) %>%
  group_by(year) %>%
  #take average of scaled values
  summarise(primProp=sum(scaled)/(pintoArea+bentoArea)) %>%
  #add in appropriate muni name and number
  mutate(muni.no=430210) %>%
  mutate(muni.name="Bento Gonçalves") %>%
  #order columns appropriately to join
  dplyr::select(muni.no, muni.name, year, primProp) %>%
  ungroup()

#drop ones we needed to fix
primateFix<- primNew[-inds2fix,]
#add new ones
primateFix <- as.data.frame(rbind(primateFix, toAppend))

#save as R object
saveRDS(primateFix, "../data_clean/environmental/primProp.rds")

# PRIMATE SPECIES RICHNESS
primateSpRich <- read.csv("../data_raw/environmental/primateRichness.csv", stringsAsFactors = F)

#This data is only one point in time so just needs to be saved as an rds

saveRDS(primateSpRich, "../data_clean/environmental/primRichness.rds")
