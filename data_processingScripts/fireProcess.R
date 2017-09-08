## This file processes the point fire data into data by muni and month
## MV Evans 2017-09-05

# Data was downloaded from LANCE Active Fire Data (https://earthdata.nasa.gov/earth-observation-data/near-real-time/firms/active-fire-data). The dataset is MCD14ML (scientific quality).
# Because the file was too large to load on most computers, it was subset into yearly data for later processing.
# Paper with lots of citations: http://amor.cms.hu-berlin.de/~muelleda/download/Mueller%20et%20al-2013-Satellite-Based%20Fire%20Data%20for%20MRV%20of%20REDD+%20in%20the%20Lao%20PDR.pdf
# This returns the number of files per municipality per month (will need to be rescaled to density at a later time)


#packages
library(sp)
library(raster)
library(rgeos)
library(rgdal)
library(gdalUtils)
library(doParallel)
library(foreach)
library(lubridate)

#load brazil shapefile
brazil <- readOGR(dsn="../data_clean", layer="BRAZpolygons")
#project properly (although it shouldn't matter)
brazil <- spTransform(brazil, CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"))

fireFiles <- list.files("../../fireSubsets", pattern=".shp", full.names=T)

#set up workers
cl <- makeCluster(18)
registerDoParallel(cl)
#read in each file and then get zonal statistics of sum of points within a municipality
system.time({
  fires <- foreach(i=1:length(fireFiles), .combine=cbind, .packages=c("lubridate","sp","raster", "rgdal", "gdalUtils", "rgeos")) %dopar% {
    fireSp <- readOGR(fireFiles[i])
    #only keep confident points >80, based on how MODIS calculates pixels (https://cdn.earthdata.nasa.gov/conduit/upload/3865/MODIS_C6_Fire_User_Guide_A.pdf)
    fireSp <- fireSp[fireSp@data$CONFIDENCE>=80,]
    fireSp <- spTransform(fireSp, CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"))
    fireSp@data$Date <- as.Date(as.character(fireSp@data$ACQ_DATE), format="%Y/%m/%d")
    fireSp@data$Year <- year(fireSp@data$Date)
    fireSp@data$Month <- month(fireSp@data$Date)
    #now loop over the month
    for (j in 1:12){
      monthFire <- fireSp[fireSp@data$Month==j,]
      #get number of fires per muni in that month
      monthTotal <- colSums(gContains(brazil, monthFire, byid = TRUE))
      if (j==1){
        yearFires <- monthTotal
      } else yearFires <- cbind(yearFires, monthTotal)
    }
    
    colnames(yearFires) <- paste0(2000+i, "month", 01:12)
    write.csv(yearFires, paste0("../../fireSubsets/CSVs/fire", 2000+i, ".csv"), row.names = F)
    return(yearFires)
  }
  stopCluster(cl)
})

#turn into big dataframe
firesDF <- as.data.frame(fires)
firesDF$muni.no <- brazil@data$muni_no
firesDF$muni.name <- brazil@data$muni_name
firesDF2 <- firesDF[,c(169, 1:168)]
write.csv(firesDF2, file="../data_raw/environmental/fires.csv")
