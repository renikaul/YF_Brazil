## TRMM Download and Extract

#Data is downloaded via command line, using the trmmDownloadscript.txt 
#We want 3B43: monthly estimates at 0.25x0.25 degree

library(raster)
library(rgdal)
library(gdalUtils)
library(ncdf4)
library(doParallel)
library(foreach)

#load Brazil data
brazil <- readOGR(dsn="../data_clean", layer="BRAZpolygons")

####-------Min, Mean, and Max Rainfall-------###
#I do all of these at once because the time consuming part is also the reading and transposing of the raster
#parallel function
#read in files
files <- list.files("../../TRMM/rawData/past", full.names = T, pattern=".nc")
fileNames <- substr(list.files("../../TRMM/rawData/past", pattern=".nc"), 6, 13)

#set up workers
cl <- makeCluster(18)
registerDoParallel(cl)
#for each file turn it into an appropriate raster and calculate spatial min, mean, and max
system.time({
  foreach(i=1:length(files), .combine=cbind, .packages=c("raster", "rgdal", "gdalUtils", "ncdf4")) %dopar% {
    rast <- raster(files[i])
    #adjust and project
    rast <- t(rast)
    proj4string(rast) <- CRS("+init=epsg:4326 +proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +towgs84=0,0,0")
    rast <- flip(rast, direction="y") #flip around a bunch
    rast <- flip(rast, direction="x")
    #spatial minimum
    # minData <- extract(rast, brazil, fun=min, na.rm=T)
    # write.csv(minData, file=paste0("TRMM/CSVs/min/", fileNames[i],".csv"), row.names=F)
    #spatial mean
    meanData <- extract(rast, brazil, fun=mean, na.rm=T)
    write.csv(meanData, file=paste0("../../TRMM/CSVs/mean/", fileNames[i],".csv"), row.names=F)
    #spatial max
    # maxData <- extract(rast, brazil, fun=max, na.rm=T)
    # write.csv(maxData, file=paste0("TRMM/CSVs/max/", fileNames[i],".csv"), row.names=F)
  }
  stopCluster(cl)
}) 


#now read in CSVs and write to one large csv file
#minimum rainfall
files <- list.files("TRMM/CSVs/min", full.names=T)
minRF <- do.call("cbind", lapply(files, read.csv, header=T))
fileNames <- gsub(".csv","", list.files("TRMM/CSVs/min", full.names=F, pattern=".csv")) #csv read-in only
colnames(minRF) <- fileNames
minRF$IBGE_ID <- brazil@data$codigo_ibg
minRF$IBGE_Name <- brazil@data$nome
minRF <- minRF[,c(169,170, 1:168)]
write.csv(minRF, file="TRMM/CSVs/minRFall.csv", row.names=F)

#mean rainfall
files <- list.files("TRMM/CSVs/mean", full.names=T)
meanRF <- do.call("cbind", lapply(files, read.csv, header=T))
fileNames <- gsub(".csv","", list.files("TRMM/CSVs/mean", full.names=F, pattern=".csv")) #csv read-in only
colnames(meanRF) <- fileNames
meanRF$IBGE_ID <- brazil@data$codigo_ibg
meanRF$IBGE_Name <- brazil@data$nome
meanRF <- meanRF[,c(169,170, 1:168)]
write.csv(meanRF, file="TRMM/CSVs/meanRFall.csv", row.names=F)

#maximum rainfall
files <- list.files("TRMM/CSVs/max", full.names=T)
maxRF <- do.call("cbind", lapply(files, read.csv, header=T))
fileNames <- gsub(".csv","", list.files("TRMM/CSVs/max", full.names=F, pattern=".csv")) #csv read-in only
colnames(maxRF) <- fileNames
maxRF$IBGE_ID <- brazil@data$codigo_ibg
maxRF$IBGE_Name <- brazil@data$nome
maxRF <- maxRF[,c(169,170, 1:168)]
write.csv(maxRF, file="TRMM/CSVs/maxRFall.csv", row.names=F)
