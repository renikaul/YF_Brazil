##LandCover Processing

#This script reads in the MODIS tiffs downloaded in MODISdownload.R and processes them into our variables for the model
library(raster)
library(rgdal)
library(SDMTools)
library(foreach)
library(doParallel)

brazil <- readOGR(dsn=".", layer="municipios_2010")
brazilData <- brazil@data #to use for muni codes

# See https://lpdaac.usgs.gov/dataset_discovery/modis/modis_products_table/mcd12q1
# for how classification works. This layer is the IBP (Type 1) classification

# 0     : water
# 1 - 5 : forest
# 6 - 7 : shrublands
# 8 - 10: savannas/grasslands
# 11    : wetlands
# 12    : croplands
# 13    : urban and built-up
# 14    : cropland/natural vegetation mosaic
# 15    : snow and ice

files <- list.files("landCover/landCoverTIF", full.names=T)

#nested for-loop because I'm a monster
system.time({ #11 hours
  for (f in 1:length(files)){
    tempRast <- raster(files[f])
    year <- as.character(2000+f) #land cover year
    #start parallel
    cl <- makeCluster(18)
    registerDoParallel(cl)
    #this will do fragstats for each municipality per year and rbind them together
    yearlyStats <- foreach(i=1:length(brazil), .combine=rbind, .packages=c('raster', 'rgdal', 'SDMTools')) %dopar% { #loop over each muni
      focalMuni <- brazil[brazil@data$codigo_ibg==brazilData$codigo_ibg[i],]
      cropRast <- crop(tempRast, focalMuni) #crop to focal muni
      cropRast <- mask(cropRast, focalMuni) #mask so those outside are NAs
      fragStats <- ClassStat(cropRast, cellsize=1000, bkgd=NA, latlon=T)
      fragStats$ibgCode <- brazilData$codigo_ibg[i] #add identifying code
      fragStats$year <- year
      fragStats <- fragStats[,c(39,40, 1:38)] #move code to the front
      return(fragStats)
    } #ends foreach
    #save yearly csv
    write.csv(yearlyStats, file=paste0("landCover/fragStats/fragStats", year), row.names=F)
    stopCluster(cl)
  }
})
