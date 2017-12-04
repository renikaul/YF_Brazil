#script reads in all the data, assembles it and saves the final dataset in data_clean/FinalData.rds
#Covarate information 

# case :reporting of any YF cases (0,1)
# NumCase :number of reported YF cases 
# NDVI : NDVI for that month
# NDVIScale : NDVI rescaled to max value for that muni and calendar month
# muniArea : km2
# popLog10 : population density 
# RF : mean hourly rainfall
# RFsqrt : mean hourly rainfall sqrt transformed
# RFScale : mean hourly rainfall rescaled to max value for that muni and calendar month
# tempMean : mean monthly air temperature 
# tempScale : mean monthly air temperature rescaled to max value for that muni and calendar month
# fireNum : number of fires oberserved in month
# fireDen : number of fires oberserved in month divided by muniArea
# fireDenSqrt : number of fires oberserved in month divided by muniArea sqrt transformed
# firesDenScale : number of fires oberserved in month divided by muniArea rescaled to max value for that muni and calendar month. NA values converted to zero. 
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
NHPProp <- readRDS("../data_clean/environmental/primProp.rds") #changes every year, missing 2014
    #hist(sqrt(NHP$primProp))
      #transformations are ugly too 

NHPRichness <- readRDS("../data_clean/environmental/primRichness.rds") #doesn't change with time
## Fires ----------------------------------

fires <- readRDS("../data_clean/environmental/numFires.rds")
  #hist(fires$numFire) #super overdispersed, only about 20% muniXmonth have had a fire. 6% of muniXmonths have only had a single fire. The upper bound is >5000 per a muniXmonth. 
  #standard transformation really cannot correct for this extreme 
  
 fires <- fires %>%
   mutate(fireDenSqrt=sqrt(fireDens)) %>%
   mutate(fireNum=numFire) %>% #rename col
   mutate(fireDen=fireDens) %>% #remane col
   group_by(muni.no, cal.month) %>%
   mutate(fireDenScale = ifelse(max(fireDens)==0,0,fireDens/max(fireDens))) %>% #scale fire densities to muni and month
   ungroup() 
   
## YF cases------------------------------ 
cases <- readRDS("../data_clean/YFcases/YFlong.rds")
 #dimensions: Entries for all muni ONLY if a case reported in any muni that month
cases[is.na(cases)] <- 0 #replace NA with zero  

cases <- cases %>%
  #drop annual totals
  filter(cal.month<=12) %>%
  #drop unknown origin totals %>%
  filter(!grepl("ignorado", muni)) %>%
  mutate(NumCase=case) %>% 
  mutate(case=ifelse(NumCase==0,0,1))


#3. Assemble data--------------------------

  #Put all the things together!  
all.enviro <- plyr::join_all(list(ndvi, pop, rf, temp, fires), 
                           by=c("muni.no", "month.no"), type="full") %>%
              select(-c(muni))

# add in NHP for each year and muni
# all.data <-  all.data %>%
#               left_join(NHP, by=c("muni.no", "year")) %>% 
#               mutate(muni.name= muni.name.x) %>%
#               select(-c(muni.name.y, muni.name.x)) #drop second muni.name

#add in NHP Richness for each muni
NHPenviro <- NHPRichness %>%
             select(-c(muni.name)) %>%
            dplyr::right_join(all.enviro, by=c('muni.no'))

          
all.covar <- NHPProp %>%
             select(-c(muni.name)) %>%  
            dplyr::right_join(NHPenviro, by=c('muni.no','year'))

#add in cases
all.data <- cases %>%
            select(c(muni.no, month.no, case, NumCase)) %>%
            dplyr::right_join(all.covar, by=c('muni.no', 'month.no')) %>%
            mutate(case=ifelse(is.na(case),0,case)) %>% #replace NA with zero
            mutate(NumCase=ifelse(is.na(NumCase),0,NumCase)) #replace NA with zero

#4. Clean it up -------------

final.data <- all.data[c("case", "NumCase",
                 "NDVI","NDVIScale",
                 "popLog10",
                 "RF","RFsqrt","RFScale",
                 "tempMean","tempScale",
                 "fireNum", "fireDen", "fireDenSqrt","fireDenScale",
                 "spRich","primProp",
                 "muni.no", "month.no", "muni.name","muniArea", "cal.month","year")]


#5. Split the data ----------------------

all.data <- final.data[order(-final.data$case, final.data$month.no),] 

all.pres <- filter(all.data, case==1)
all.bg <- filter(all.data, case==0)

#Split infected municipalities
#test.pres.inds <- base::sample(nrow(all.pres), ceiling(nrow(all.pres)/3)) #without year stratification
test.pres.inds <- seq(1,nrow(all.pres), by=3) #with year stratification
test.pres <- all.pres[test.pres.inds,]
train.pres <- all.pres[-test.pres.inds,]

#Split background data
test.bg.inds <- base::sample(nrow(all.bg), ceiling(nrow(all.bg)/3))
test.bg <- all.bg[test.bg.inds,]
train.bg <- all.bg[-test.bg.inds,]

training <- rbind(train.pres, train.bg)
testing <- rbind(test.pres, test.bg)

#6. Save data ---------------------------
#individual training and testing data
saveRDS(training, file="../data_clean/TrainingData.rds")
saveRDS(testing, file="../data_clean/TestingData.rds")
saveRDS(final.data, file="../data_clean/FinalData.rds")

#index of data to create training and testing
save(test.pres.inds, test.bg.inds, file="IndexForDataSplit.RData")
