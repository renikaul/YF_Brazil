## This script extracts MODIS monthly covariate variables from rasters and attaches them to the 
#  Brazil municipalities. MODIS variables were downloaded in other script called MODISdownload.R.

library(raster)
library(rgdal)
library(doParallel)
library(foreach)
library(MODIS) #ignore these warnings

#load Brazil shapefile from IBGE site with municipality codes

brazil <- readOGR(dsn="../data_clean", layer="BRAZpolygons")
#reproject so it doesn't throw a strange error
brazil <- spTransform(brazil, CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"))

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

#
#
## ---------------------------------------------LST processing (w/ 8 day data MOD11A2)

# Step 1: Raster calculate to get the min, mean, and max value per month (each 168) 
# for every 1 km grid
lstFiles <- list.files("LST/LSTtifBrazil", full.names=T)
lstDates <- substr(list.files("LST/LSTtifBrazil"), 10,16) #in modis date form (YYYYDDD)
lstMonthsCode <- paste((strptime(lstDates, format="%Y%j")$year +1900), (strptime(lstDates, format="%Y%j")$mon+1), sep="-")
lstMonths <- unique(lstMonthsCode)

#calculate mean, min, and max for each grid and save three rasters per month
cl <- makeCluster(18)
registerDoParallel(cl)
system.time({
  foreach (i=1:length(lstMonths), .packages=c('raster', 'rgdal')) %dopar%{
    focalMonth <- lstMonths[i]
    inds <- which(lstMonthsCode==focalMonth)
    rastStack <- stack(lstFiles[inds])
    rastStack[rastStack<7500] <- -Inf
    calc(rastStack, fun=mean, na.rm=T, filename=paste0("LST/mean/", focalMonth), format="GTiff", overwrite=T)
    calc(rastStack, fun=min, na.rm=T, filename=paste0("LST/min/", focalMonth), format="GTiff", overwrite=T)
    calc(rastStack, fun=max, na.rm=T, filename=paste0("LST/max/", focalMonth), format="GTiff", overwrite=T)
  }
})
stopCluster(cl) 

#--------------2001-6 is for some reason not working. Troubleshooting here (files 20-22)
# test1 <- raster(lstFiles[20])
# test2 <- raster(lstFiles[21])
# test3 <- raster(lstFiles[22]) #this one is messed up, so will only combine 20 and 21
# rastStack <- stack(lstFiles[20:21])
# focalMonth="2001-6"
# calc(rastStack, fun=mean, na.rm=T, filename=paste0("LST/mean/", focalMonth), format="GTiff", overwrite=T)
# calc(rastStack, fun=min, na.rm=T, filename=paste0("LST/min/", focalMonth), format="GTiff", overwrite=T)
# calc(rastStack, fun=max, na.rm=T, filename=paste0("LST/max/", focalMonth), format="GTiff", overwrite=T)

# as of 2017-08-15, the temperature data is still wrong. It is either a recording error or aggregation error, but we are getting min/max temps that are crazy
# two options: download cleaned monthly data at 5 km resolution, or download the QA for this data and use it to sort out data (this may not work either)


#Step 2: spatially aggregate the mean, min and max to each municipality.

brazil <- readOGR(dsn=".", layer="municipios_2010") #this must be loaded

## Mean temperature ------------------------

#brazil must be loaded
files <- list.files("LST/mean", full.names = T, pattern=".tif")
fileNames <- gsub(".tif","", list.files("LST/mean", full.names=F, pattern=".tif"))
#parallelized for loop
cl <- makeCluster(18)
registerDoParallel(cl)
#getDoParWorkers()==length(cl)
system.time({ #11 hours
  meanT <- foreach(i=1:length(files), .combine=cbind, .packages=c('raster', 'rgdal')) %dopar% {
    rast <- raster(files[i])
    monthData <- extract(rast, brazil, fun=mean, na.rm=T)
    write.csv(monthData, file=paste0("LST/mean/CSVs/", fileNames[i],".csv"), row.names=F)
    return(monthData)
  }
}) #end system time
stopCluster(cl)
#now need to read in individual csvs and combine into one big one
files <- list.files("LST/mean/CSVs", full.names=T)
meanTDF <- do.call("cbind", lapply(files, read.csv, header=T))
fileNames <- gsub(".csv","", list.files("LST/mean/CSVs", full.names=F, pattern=".csv")) #csv read-in only
colnames(meanTDF) <- fileNames
meanTDF$IBGE_ID <- brazil@data$codigo_ibg
meanTDF$IBGE_Name <- brazil@data$nome
#meanTDF2 <- meanTDF[,c(169,170, 1:168)]
write.csv(meanTDF, file="LST/mean/CSVs/meanTall.csv", row.names=F)

##-------------- Min temperature-----------------------

#brazil must be loaded
files <- list.files("LST/min", full.names = T, pattern=".tif")
fileNames <- gsub(".tif","", list.files("LST/min", full.names=F, pattern=".tif"))
#parallelized for loop
cl <- makeCluster(18)
registerDoParallel(cl)
#getDoParWorkers()==length(cl)
system.time({ #11 hours
  minT <- foreach(i=1:length(files), .combine=cbind, .packages=c('raster', 'rgdal')) %dopar% {
    rast <- raster(files[i])
    monthData <- extract(rast, brazil, fun=min, na.rm=T)
    write.csv(monthData, file=paste0("LST/min/CSVs/", fileNames[i],".csv"), row.names=F)
    return(monthData)
  }
}) #end system time
stopCluster(cl)
#now need to read in individual csvs and combine into one big one
#minTDF <- as.data.frame(minT)
#Use the below if writing minT didn't work
files <- list.files("LST/min/CSVs", full.names=T)
minTDF <- do.call("cbind", lapply(files, read.csv, header=T))
fileNames <- gsub(".csv","", list.files("LST/min/CSVs", full.names=F, pattern=".csv")) #csv read-in only
colnames(minTDF) <- fileNames
minTDF$IBGE_ID <- brazil@data$codigo_ibg
minTDF$IBGE_Name <- brazil@data$nome
write.csv(minTDF, file="LST/min/CSVs/minTall.csv", row.names=F)

##-------------- Max temperature-----------------------

#brazil must be loaded
files <- list.files("LST/max", full.names = T, pattern=".tif")
fileNames <- gsub(".tif","", list.files("LST/max", full.names=F, pattern=".tif"))
#parallelized for loop
cl <- makeCluster(18)
registerDoParallel(cl)
#getDoParWorkers()==length(cl)
system.time({ 
  maxT <- foreach(i=1:length(files), .combine=cbind, .packages=c('raster', 'rgdal')) %dopar% {
    rast <- raster(files[i])
    monthData <- extract(rast, brazil, fun=max, na.rm=T)
    write.csv(monthData, file=paste0("LST/max/CSVs/", fileNames[i],".csv"), row.names=F)
    return(monthData)
  }
}) #end system time
stopCluster(cl)
#now need to read in individual csvs and combine into one big one
maxTDF <- as.data.frame(maxT)
#Below reads in individual month csvs
files <- list.files("LST/max/CSVs", full.names=T)
maxTDF <- do.call("cbind", lapply(files, read.csv, header=T))
fileNames <- gsub(".csv","", list.files("LST/max/CSVs", full.names=F, pattern=".csv")) #csv read-in only
colnames(maxTDF) <- fileNames
maxTDF$IBGE_ID <- brazil@data$codigo_ibg
maxTDF$IBGE_Name <- brazil@data$nome
write.csv(maxTDF, file="LST/max/CSVs/maxTall.csv", row.names=F)

###-------Land Surface Temperature (monthly data, MOD11C3)----------------------------------#####

brazil <- readOGR(dsn="../data_clean", layer="BRAZpolygons")#this must be loaded

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
    #minT <- extract(rast, brazil, fun=min, na.rm=T)
    #maxT <- extract(rast, brazil, fun=max, na.rm=T)
    write.csv(meanT, file=paste0("../../LST/monthly/CSVs/mean/month", i,".csv"), row.names=F)
    #write.csv(minT, file=paste0("../../LST/monthly/CSVs/min/month", i,".csv"), row.names=F)
    #write.csv(maxT, file=paste0("../../LST/monthly/CSVs/max/month", i,".csv"), row.names=F)
  }
}) #end system time
stopCluster(cl)

#now need to read in individual csvs and combine

#Mean Temperature
files <- list.files("../../LST/monthly/CSVs/mean", full.names=T)
meanTDF <- do.call("cbind", lapply(files, read.csv, header=T))
fileNames <- gsub(".csv","", list.files("../../LST/monthly/CSVs/mean", full.names=F, pattern=".csv")) #csv read-in only
colnames(meanTDF) <- fileNames
meanTDF$muni.no <- brazil@data$muni_no
meanTDF$muni.name <- brazil@data$muni_name
meanTDF2 <- meanTDF[,c(169,170, 1:168)]
write.csv(meanTDF, file="../data_raw/environmental/meanTall.csv", row.names=F)

#Max Temperature
files <- list.files("../../LST/monthly/CSVs/max", full.names=T)
maxTDF <- do.call("cbind", lapply(files, read.csv, header=T))
fileNames <- gsub(".csv","", list.files("../../LST/monthly/CSVs/max", full.names=F, pattern=".csv")) #csv read-in only
colnames(maxTDF) <- fileNames
maxTDF$IBGE_ID <- brazil@data$muni_no
write.csv(maxTDF, file="../data_raw/environmental/maxTall.csv", row.names=F)

#Min Temperature
files <- list.files("../../LST/monthly/CSVs/min", full.names=T)
minTDF <- do.call("cbind", lapply(files, read.csv, header=T))
fileNames <- gsub(".csv","", list.files("../../LST/monthly/CSVs/min", full.names=F, pattern=".csv")) #csv read-in only
colnames(minTDF) <- fileNames
minTDF$IBGE_ID <- brazil@data$muni_no
write.csv(minTDF, file="../data_raw/environmental/minTall.csv", row.names=F)

