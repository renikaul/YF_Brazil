### This script combines the covariate data into one giant dataframe to use in the bagging model
## MV Evans July 11 2017

## List of Covariates:
  # Rainfall
  # NDVI
  # Land Use (this will be a huge pain)
  # Temperature

# All of the Data is wide, but needs to switch to long to match cases
# Merge columns are muni.no, year(2001), month (7), examples in parentheticals

library(tidyr)
library(plyr)
library(dplyr)
library(lubridate)

###--------Rainfall
rainfallMax <- read.csv("../data_raw/environmental/maxRFall.csv")
rainfallMin <- read.csv("../data_raw/environmental/minRFall.csv")
rainfallMean <- read.csv("../data_raw/environmental/meanRFall.csv")

process_rainfall <- function(rainfallDF, type){
  #' Reformat rainfall for bagged logreg
  #' 
  #' @param rainfallDF the rainfall dataframe to process
  #' @param type whether it is the min, mean, or max (ex. "Min)
  require(dplyr)
  require(tidyr)
  newDF <- rainfallDF %>%
    #subset IBGE_ID to get muni.no
    mutate(muni.no = as.numeric(as.character(substr(IBGE_ID,1,6)))) %>%
    #go from wide to long
    gather(date, measurement, X20010101:X20141201) %>%
    #drop old muni code
    dplyr::select(-IBGE_ID) %>%
    #get year column
    mutate(year= as.numeric(substr(date, 2,5))) %>%
    # get month column
    mutate(month=as.numeric(substr(date, 6,7))) %>%
    #drop date column
    dplyr::select(-date) %>%
    #reorder columns to keep us sane
    dplyr::select(muni.no, muni.name=IBGE_Name, year, month, measurement)
  
  #rename measurement column
  measureLabel <- paste0("hourlyRainfall", type)
  colnames(newDF)[colnames(newDF)=="measurement"] <- measureLabel
  
  #switch muni name to character to avoid weird factors while merging
  newDF$muni.name <- as.character(newDF$muni.name)
  
  return(newDF)
}

#apply function to all rainfall dataframes
newRFmin <- process_rainfall(rainfallDF=rainfallMin, type="Min")
newRFmax <- process_rainfall(rainfallDF=rainfallMax, type="Max")
newRFmean <- process_rainfall(rainfallDF = rainfallMean, type="Mean")

#merge dataframes together into one
RFall <- join_all(list(newRFmin, newRFmax, newRFmean), by=c("muni.no", "year", "month"), type="full")

#save as R object
saveRDS(RFall, "../data_clean/environmental/allRainfall.rds")

####--------NDVI

ndvi <- read.csv("../data_raw/environmental/NDVIall.csv")
#dates are julian (1-365)

jtoDate <- function(day, year){
  #' Convert day of year to Posix style date
  #' 
  #' @param day day of year (1-365)
  #' @param year ("2001")
  posixDate <- strptime(paste(year, day), format="%Y %j")
  return(posixDate)
}

ndviNew <- ndvi %>%
  mutate(muni.no = as.numeric(as.character(substr(IBGE_ID,1,6)))) %>%
  #go from wide to long
  gather(date, NDVI, MOD13A3.A2001001:MOD13A3.A2014335) %>%
  #rescale NDVI
  mutate(NDVI=NDVI*0.0001) %>%
  #drop old muni code
  dplyr::select(-IBGE_ID) %>%
  #get year
  mutate(year=substr(date, 10,13)) %>%
  #get date
  mutate(day=substr(date, 14, 16)) %>%
  #convert date to month
  mutate(posixDate = jtoDate(day, year)) %>%
  mutate(month=month(posixDate)) %>%
  #reorganize columns
  dplyr::select(muni.no, muni.name=IBGE_Name, year, month, NDVI)

#adjust muni name to a character
ndviNew$muni.name <- as.character(ndviNew$muni.name)

#make year numeric
ndviNew$year <- as.numeric(ndviNew$year)

#save as RDS object
saveRDS(ndviNew, "../data_clean/environmental/allNDVI.rds")
  
#####----------Temperature
tempMax <- read.csv("../data_raw/environmental/maxTall.csv")
tempMin <- read.csv("../data_raw/environmental/minTall.csv")
tempMean <- read.csv("../data_raw/environmental/meanTall.csv")

process_temp <- function(tempDF, type){
  #' Reformat temperature for bagged logreg
  #' 
  #' @param tempDF the temperature dataframe to process
  #' @param type whether it is the min, mean, or max (ex. "Min)
  require(dplyr)
  require(tidyr)
  newDF <- tempDF %>%
      #subset IBGE_ID to get muni.no
      mutate(muni.no = as.numeric(as.character(substr(IBGE_ID,1,6)))) %>%
      #reorder columns
      dplyr::select(muni.no, muni.name=IBGE_Name, X2001.10:X2014.9) %>%
      #go from wide to long
      gather(date, measurement, X2001.10:X2014.9) %>%
      #rescale temperature and change to C
      mutate(measurement=(measurement*0.02)-273.15) %>%
      #get year
      mutate(year=substr(date,2,5)) %>%
      #get month
      mutate(month=substr(date,7, length(date))) %>%
      #drop date
      dplyr::select(muni.no, muni.name, year, month, measurement)

    #rename measurement column
    measureLabel <- paste0("temp", type)
    colnames(newDF)[colnames(newDF)=="measurement"] <- measureLabel
      
    #switch muni name to character to avoid weird factors while merging
    newDF$muni.name <- as.character(newDF$muni.name)
      
    return(newDF)
}      

#apply function to all rainfall dataframes
newTmin <- process_temp(tempDF=tempMin, type="Min")
newTmax <- process_temp(tempDF=tempMax, type="Max")
newTmean <- process_temp(tempDF=tempMean, type="Mean")

#merge dataframes together into one
tempAll <- join_all(list(newTmin, newTmax, newTmean), by=c("muni.no", "year", "month"), type="full")

#save as R object
saveRDS(tempAll, "../data_clean/environmental/allTemperature.rds") #missing 2001.06 
