### This script combines the covariate data into one giant dataframe to use in the bagging model
## MV Evans August 2 2017

## List of Covariates:
  # Rainfall
  # NDVI
  # Temperature

# All of the Data is wide, but needs to switch to long to match cases
# Merge columns are muni.no, year(2001), month (7), examples in parentheticals

library(tidyr)
library(plyr)
library(dplyr)
library(lubridate)

###--------Rainfall
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
    #go from wide to long
    gather(date, measurement, X20010101:X20141201) %>%
    #get year column
    mutate(year= as.numeric(substr(date, 2,5))) %>%
    # get month column
    mutate(month=as.numeric(substr(date, 6,7))) %>%
    #drop date column
    dplyr::select(-date) %>%
    #reorder columns to keep us sane
    dplyr::select(muni.no, year, cal.month=month, measurement)
  
  #rename measurement column
  measureLabel <- paste0("hourlyRainfall", type)
  colnames(newDF)[colnames(newDF)=="measurement"] <- measureLabel
  
  #switch muni name to character to avoid weird factors while merging
  # newDF$muni.name <- as.character(newDF$muni.name)
  
  return(newDF)
}

#apply function to all rainfall dataframes
# newRFmin <- process_rainfall(rainfallDF=rainfallMin, type="Min")
# newRFmax <- process_rainfall(rainfallDF=rainfallMax, type="Max")
newRFmean <- process_rainfall(rainfallDF = rainfallMean, type="Mean")

# merge dataframes together into one
# RFall <- join_all(list(newRFmin, newRFmax, newRFmean), by=c("muni.no", "year", "cal.month"), type="full")

RFall <- newRFmean
#add in month.no
month.noFunc <- function(year, month, startYear, startMonth){
  yearsPast <- year-startYear
  monthsPast <- month-startMonth
  totalMonths <- 12*yearsPast + monthsPast + 1
  return(totalMonths)
}

RFall <- mutate(RFall, month.no=month.noFunc(year=year, month=cal.month, startYear=2001, startMonth=1))

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
  #reorganize columns
  dplyr::select(muni.no, year, cal.month=month, NDVI) %>%
  mutate(month.no=month.noFunc(year=as.numeric(year), month=cal.month, startYear=2001, startMonth=1))

  
#adjust muni name to a character
# ndviNew$muni.name <- as.character(ndviNew$muni.name)

#make year numeric
ndviNew$year <- as.numeric(ndviNew$year)

#save as RDS object
saveRDS(ndviNew, "../data_clean/environmental/allNDVI.rds") #note that muni.no 291992 has an NA in 2011305 (need to spatially permute this)
  
#####----------Temperature
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
      #reorder columns
      dplyr::select(muni.no, month100:month9) %>% #double check columns match when running
      #go from wide to long
      gather(date, measurement, month100:month9) %>%
      #rescale temperature and change to C
      mutate(measurement=(measurement*0.02)-273.15) %>%
      #get month.no
      mutate(month.no=as.numeric(gsub("month", "", date))) %>%
      #get year
      arrange(month.no) %>%
      mutate(year=rep(2001:2014, each=length(unique(tempDF$muni.no))*12)) %>% #repeat each year number of munis *12
      #get month (remainder, then correct for 12)
      mutate(cal.month=case_when(
        (month.no %% 12) !=0 ~ month.no %% 12,
        (month.no %% 12) ==0 ~ 12
          )
        ) %>%
      #drop date
      dplyr::select(muni.no, year, cal.month, month.no, measurement)
  

    #rename measurement column
    measureLabel <- paste0("temp", type)
    colnames(newDF)[colnames(newDF)=="measurement"] <- measureLabel
      
    return(newDF)
}      

#apply function to all temperature dataframes
# newTmin <- process_temp(tempDF=tempMin, type="Min")
# newTmax <- process_temp(tempDF=tempMax, type="Max")
newTmean <- process_temp(tempDF=tempMean, type="Mean")

#merge dataframes together into one
# tempAll <- join_all(list(newTmin, newTmax, newTmean), by=c("muni.no", "year", "cal.month", "month.no"), type="full")

tempAll <- newTmean

#---three muni x month have NA/-Inf/Inf due to cloud cover
#toFix <- tempAll[(is.na(tempAll$tempMean) | tempAll$tempMax==-Inf | tempAll$tempMin==Inf),]

#get these values by spatial permutation of the values of their neighbors
#load brazil shapefile to find neighbors
library(rgdal)
library(rgeos)
library(spdep)

brazil <- readOGR("../data_clean", "BRAZpolygons")


#neighbors for every polygon
row.names(brazil) <- as.character(brazil@data$muni_no)
neighbors <- poly2nb(brazil)
mat <- nb2mat(neighbors, zero.policy=T)
colnames(mat) <- as.character(brazil@data$muni_no)

#then make a loop that gets the values from this matrix, and then takes the mean of those values from the temperature table above

spatialPermute <- function(missingMuni.no, missingMuni.name, missingMonth, missingYear, missingmonth.no, nbMat=mat){
  temp <- nbMat[rownames(nbMat)==missingMuni.no,]
  nbs <- names(temp[temp>0]) #get muni.no of neighbors
  nbValues <- tempAll %>%
    dplyr::filter(year==missingYear) %>%
    dplyr::filter(cal.month==missingMonth) %>%
    dplyr::filter(muni.no %in% nbs) %>%
    dplyr::filter(tempMin!=Inf & tempMax!=-Inf) %>%
    dplyr::summarise(tempMin=mean(tempMin, na.rm=T), tempMax=mean(tempMax, na.rm=T), tempMean=mean(tempMean, na.rm=T))
  newValues <- cbind(muni.no=missingMuni.no, muni.name=missingMuni.name, year=missingYear, cal.month=missingMonth, month.no=missingmonth.no, nbValues[,c('tempMin', 'tempMax', 'tempMean')])
  return(newValues)
}

#apply spatial permute to the missing rows
missInds <- which(is.na(tempAll$tempMean) | tempAll$tempMax==-Inf | tempAll$tempMin==Inf | tempAll$tempMin<0)

for (i in missInds){
  newVals <- spatialPermute(missingMuni.no=tempAll[i,1], missingMuni.name=tempAll[i,2], missingYear=tempAll[i,3],
                 missingMonth = tempAll[i,4], missingmonth.no = tempAll[i,5])
  tempAll <- rbind(tempAll, newVals) #append to end
}

#drop everything that we have fixed and appended
tempAll <- tempAll[-missInds,]

#save as R object
saveRDS(tempAll, "../data_clean/environmental/allTemperature.rds") 
