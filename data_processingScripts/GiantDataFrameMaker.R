#script reads in all the data, assembles it and removes everything but the final dataset

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
    mutate(PopDenLog= log(pop$densitypop)) 

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
  mutate(RFScaleMean = hourlyRainfallMean/max(hourlyRainfallMean)) %>% #scale rainfall to muni
  ungroup()




#3. Assemble data--------------------------


#4. Calculate additional covar-------------


#5. Transform covar as needed--------------

#6. Rm everything but----------------------