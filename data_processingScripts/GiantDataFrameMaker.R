#script reads in all the data, assembles it and saves the final dataset in data_clean/FinalData.rds
#Covarate information 

# case : number of reported YF cases
# NDVI : NDVI for that month
# NDVIScale : NDVI rescaled to max value for that muni and calendar month
# muniArea : km2
# popLog10 : population density 
# RF : mean hourly rainfall
# RFsqrt : mean hourly rainfall sqrt transformed
# RFScale : mean hourly rainfall rescaled to max value for that muni and calendar month
# tempMean : mean monthly air temperature 
# tempScale : mean monthly air temperature rescaled to max value for that muni and calendar month
# numFire : number of fires oberserved in month
# fireDens : number of fires oberserved in month divided by muniArea
# spRich : number of non-human primates by species with ranges based on IUCN {0-22}
# primProp : sum of each municipalities relative area that is both agricultural and falls within a primate genus range. {0,9} Missing for 2014
# muni.no : unique number to identify municipality
# month.no : numbered month of observation {1,168}
# muni.name : character string name
# month : abbrevated calendar month name
# cal.month : calendar month {1,12}
# year : year {2001,2014}

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
  mutate(RF=hourlyRainfallMean) %>%
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
NHPProp <- readRDS("../data_clean/environmental/primProp.rds") 
    #hist(sqrt(NHP$primProp))
      #transformations are ugly too 

NHPRichness <- readRDS("../data_clean/environmental/primRichness.rds")
## Fires ----------------------------------

fires <- readRDS("../data_clean/environmental/numFires.rds")
  #hist(fires$numFire) #super overdispersed, only about 20% muniXmonth have had a fire. 6% of muniXmonths have only had a single fire. The upper bound is >5000 per a muniXmonth. 
  #standard transformation really can correct for this extreme 
  
# fires <- fires %>%
#   mutate(firesDenLog=log(fireDens)) %>%
#   group_by(muni.no, cal.month) %>%
#   mutate(firesDenScale = fireDens/max(fireDens)) %>% #scale fire densities to muni and month
#   ungroup()

## YF cases------------------------------ 
cases <- readRDS("../data_clean/YFcases/YFlong.rds")

cases[is.na(cases)] <- 0 #replace NA with zero  

cases <- cases %>%
  #drop annual totals
  filter(cal.month<=12) %>%
  #drop unknown origin totals %>%
  filter(!grepl("ignorado", muni)) 


#3. Assemble data--------------------------

  #Put all the things together!  #Need to add fires after fix. 
all.data <- plyr::join_all(list(ndvi, pop, rf, temp, cases, fires), by=c("muni.no", "month.no"), type="full") 

# add in NHP for each year and muni
# all.data <-  all.data %>%
#               left_join(NHP, by=c("muni.no", "year")) %>% 
#               mutate(muni.name= muni.name.x) %>%
#               select(-c(muni.name.y, muni.name.x)) #drop second muni.name

#add in NHP Richness for each muni
all.data2 <- all.data %>%
            dplyr::left_join(NHPRichness)

all.data2 <- all.data2 %>%
            plyr::join(NHPProp)


#4. Clean it up -------------

final.data <- all.data2[c("case",
                 "NDVI","NDVIScale",
                 "muniArea","popLog10",
                 "RF","RFsqrt","RFScale",
                 "tempMean","tempScale",
                 "numFire","fireDens",
                 "spRich","primProp",
                 "muni.no", "month.no", "muni.name", "month", "cal.month","year")]


#5. Save the data ----------------------

saveRDS(final.data, file="../data_clean/FinalData.rds")
