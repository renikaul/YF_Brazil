#script reads in all the data, assembles it and removes everything but the final dataset
#Covarate information in comments of load data

#1. Load packages-------------------------

library(dplyr)
library(gplots)
library(ROCR)
library(pROC)

#2. Load data-----------------------------

## population---------------------------
    # pop
    # muniArea
    # densitypop
    # PopDenLog
pop <- readRDS("../data_clean/demographic/pop.rds")

#log transformed variables
# hist(rf$hourlyRainfallMean, main="hourly rainfall") #mean rainfall, exponential

pop <- pop %>%
    mutate(popLog10 = log(densitypop)) 
    
## rainfall------------------------------ 
    # RFsqrt: sqrt hourly rainfall mean
    # RFScaleMean: hourly mean rainfall divided by max value for muni 
rf <- readRDS("../data_clean/environmental/allRainfall.rds")

#sqrt transformed variables
  # hist(rf$hourlyRainfallMean, main="hourly rainfall") #mean rainfall, exponential
  # hist(sqrt(rf$hourlyRainfallMean), main="hourly rainfall") #mean rainfall, exponential

#scale to maximum value of muni
rf <- rf %>%
  mutate(RFsqrt=sqrt(hourlyRainfallMean)) %>%
  group_by(muni.no) %>%
  mutate(RFScale = hourlyRainfallMean/max(hourlyRainfallMean)) %>% #scale rainfall to muni
  ungroup()

## NDVI ------------------------------ 
    # NDVI: raw value between 0,1
    # NDVIScale: NDVI divided by max NDVI for muni and month

ndvi <- readRDS("../data_clean/environmental/allNDVI.rds")
  #hist(ndvi$NDVI) #normal

ndvi <- ndvi %>%
  group_by(muni.no, cal.month) %>%
  mutate(NDVIScale = NDVI/max(NDVI)) %>% #scale NDVI to muni and month
  ungroup()

## temperature------------------------------ 
    #tempMean:
    #tempScale
temp <- readRDS("../data_clean/environmental/meanTemperature.rds")
  #hist(temp$tempMean)

temp <- temp %>%
  group_by(muni.no, cal.month) %>%
  mutate(tempScale = tempMean/max(tempMean)) %>% #scale NDVI to muni and month
  ungroup()

## Non-human primates------------------------------ 
    #primProp
NHP <- readRDS("../data_clean/environmental/primProp.rds")
    #hist(sqrt(NHP$primProp))
      #transformations are ugly too 
## Fires ----------------------------------

fires <- readRDS("../data_clean/environmental/numFires.rds")
  #hist(fires$numFire) #super overdispersed, only about 20% muniXmonth have had a fire. 6% of muniXmonths have only had a single fire. The upper bound is >5000 per a muniXmonth. 
  #standard transformation really can correct for this extreme 

## YF cases------------------------------ 
cases <- readRDS("../data_clean/YFcases/YFlong.rds")

cases <- cases %>%
  #drop annual totals
  filter(cal.month<=12) %>%
  #drop unknown origin totals %>%
  filter(!grepl("ignorado", muni))


#3. Assemble data--------------------------

  #Put all the things together!  #Need to add fires after fix. 
all.data <- plyr::join_all(list(ndvi, pop, rf, temp, cases), by=c("muni.no", "month.no"), type="full") %>%
        select(muni.no, muni.name, year, cal.month, month.no, case, popLog10, NDVI,NDVIScale, RFsqrt,RFScale, tempMean, tempScale, muniArea) 

all.data <-  all.data %>%
              left_join(NHP, by=c("muni.no", "year")) %>% 
              mutate(muni.name= muni.name.x) %>%
              select(-c(muni.name.y, muni.name.x)) #drop second muni.name
    # #clean it up
    # all.data <- all.data %>%
    #   #drop if doesn't match envCovariates (these are all the ones that were emancipated in 2013)
    #   filter(!is.na(muni.name)) %>%
    #   #get only columns we need
    #   select(muni.no, muni.name, year, cal.month, month.no, case, popDensity, NDVI,scale.ndvi, log.mean.rf,scale.mean.rf, tempMax, tempMean)
    # 
    # #turn NA cases to 'true' zeros
    # all.data$case[is.na(all.data$case)] <- 0
    # #all positive cases to 1s
    # all.data$case[all.data$case>0] <- 1
    # 
    # #remove 291992 Madre de Deus; issues with NA in NDVI
    # all.data <- all.data[complete.cases(all.data),]



#4. Calculate additional covar-------------

#5. Rm everything but----------------------