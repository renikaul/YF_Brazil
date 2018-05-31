## This script extracts MODIS monthly covariate variables from rasters and attaches them to the 
#  Brazil municipalities. MODIS variables were downloaded in other script called MODISdownload.R.

library(raster)
library(rgdal)
library(doParallel)
library(foreach)
library(MODIS) #ignore these warnings

#load Brazil shapefile from IBGE site with municipality codes

brazil <- readOGR(dsn="../", layer = "BRAZpolygons") #this must be loaded

##---------------------------NDVI 

#files to loop over
files <- list.files("../../NDVI/tifBrazil", full.names = T)

#parallelized for loop
cl <- makeCluster(18)
registerDoParallel(cl)
#getDoParWorkers()==length(cl)
system.time({ #11 hours
  NDVI <- foreach(i=1:length(files), .combine=cbind, .packages=c('raster', 'rgdal')) %dopar% {
    rast <- raster(files[i])
    monthData <- extract(rast, brazil, fun=mean, na.rm=T)
    write.csv(monthData, file=paste0("../../NDVI/CSVs/month", i,".csv"), row.names=F)
    return(monthData)
}
}) #end system time
stopCluster(cl)
#now need to read in individual csvs and combine into one big one
NDVIdf <- as.data.frame(NDVI)
colnames(NDVIdf) <- substr(list.files("../../NDVI/tifBrazil"),0,16)
NDVIdf$muni.no <- brazil@data$muni_no
NDVIdf$muni.name <- brazil@data$muni_name
NDVIdf2 <- NDVIdf[,c(169, 170, 1:168)]
write.csv(NDVIdf2, file="../data_raw/environmental/NDVIall.csv", row.names=F)

###-------Land Surface Temperature (monthly data, MOD11C3)----------------------------------#####

brazil <- readOGR(dsn="../", layer = "BRAZpolygons") #this must be loaded

#files to loop over
files <- list.files("../../LST/monthly/LSTtifBrazil", full.names = T)

#parallelized for loop
cl <- makeCluster(18)
registerDoParallel(cl)
#getDoParWorkers()==length(cl)
system.time({ #11 hours
foreach(i=1:length(files), .combine=cbind, .packages=c('raster', 'rgdal')) %dopar% {
    rast <- raster(files[i])
    rast[rast<12000] <- NA #fix cloud errors and fill
    meanT <- extract(rast, brazil, fun=mean, na.rm=T)
    minT <- extract(rast, brazil, fun=min, na.rm=T)
    maxT <- extract(rast, brazil, fun=max, na.rm=T)
    write.csv(meanT, file=paste0("../../LST/monthly/CSVs-May2018/mean/month", i,".csv"), row.names=F)
    write.csv(minT, file=paste0("../../LST/monthly/CSVs-May2018/min/month", i,".csv"), row.names=F)
    write.csv(maxT, file=paste0("../../LST/monthly/CSVs-May2018/max/month", i,".csv"), row.names=F)
  }
}) #end system time
stopCluster(cl)

#now need to read in individual csvs and combine

#Mean Temperature
files <- list.files("../../LST/monthly/CSVs-May2018/mean", full.names=T)
meanTDF <- do.call("cbind", lapply(files, read.csv, header=T))
fileNames <- gsub(".csv","", list.files("../../LST/monthly/CSVs-May2018/mean", full.names=F, pattern=".csv")) #csv read-in only
colnames(meanTDF) <- fileNames
meanTDF$muni.no <- brazil@data$muni_no
write.csv(meanTDF, file="../raw-covars/meanTall.csv", row.names=F)

#Max Temperature
files <- list.files("../../LST/monthly/CSVs-May2018/max", full.names=T)
maxTDF <- do.call("cbind", lapply(files, read.csv, header=T))
fileNames <- gsub(".csv","", list.files("../../LST/monthly/CSVs-May2018/max", full.names=F, pattern=".csv")) #csv read-in only
colnames(maxTDF) <- fileNames
maxTDF$muni.no <- brazil@data$muni_no
write.csv(maxTDF, file="../raw-covars/maxTall.csv", row.names=F)

#Min Temperature
files <- list.files("../../LST/monthly/CSVs-May2018/min", full.names=T)
minTDF <- do.call("cbind", lapply(files, read.csv, header=T))
fileNames <- gsub(".csv","", list.files("../../LST/monthly/CSVs-May2018/min", full.names=F, pattern=".csv")) #csv read-in only
colnames(minTDF) <- fileNames
minTDF$muni.no <- brazil@data$muni_no
write.csv(minTDF, file="../raw-covars/minTall.csv", row.names=F)

