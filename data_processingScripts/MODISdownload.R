## MODIS Download Script

# This is the Script to download and process the MODIS Land Surface Temperature (LST) and NDVI data. 
# We are interested in data for all of Brazil from Jan 2001 - Dec 2014.

####_--------CHECK OUT MODISTools---------######


#install.packages("MODIS")
library(MODIS)
library(rgdal)
library(raster)
library(curl)
library(wget)
library(mapdata)
library(snow)
library(ptw)
library(XML)

#Make sure the paths are appropriate
MODISoptions(localArcPath="/media/drakelab/MVEVANS/Research/brazilYFGISData/MODIS/downloaded", 
             outDirPath="/media/drakelab/MVEVANS/Research/brazilYFGISData/MODIS/processed", dlmethod="wget", 
             MODISserverOrder="LPDAAC")
#MRT paths
print(Sys.setenv(MRT_HOME = "/home/drakelab/MRT", "A+C" = 123)) 
print(Sys.setenv(MRT_DATA_DIR = "home/drakelab/MRT/data", "A+C" = 123))
MODIS:::checkTools("MRT")

#you must have MRT installed and know its path. see here: https://lpdaac.usgs.gov/tools/modis_reprojection_tool
#add Earthdata login credentials
#lpdaacLogin(server="LPDAAC") #creates hidden file on home directory

products <- getProduct()
View(products) #look at all the available products

#We want MOD13A3 (NDVI monthly/ 1km) and MOD11A1 (LST 8 day/ 1km) and MOD12Q1 (land cover yearly/ 1km)
#LST can be used to get the minimum, maximum, and mean 
#(get daily spatial means for whole municipality, then calculate mean, min, and max, and range)
getProduct("MOD13A3") #NDVI
getCollection(product = "MOD13A3")
getProduct("MOD11A2") #LST in Kelvin with scale factor of 0.2
getCollection(product = "MOD11A2")
getProduct("MCD12Q1") #Land Cover
getCollection(product = "MCD12Q1") #SDS 1 is IGBP Land Cover #https://e4ftl01.cr.usgs.gov/MOTA/MCD12Q1.051/

#find Tile extent
brazTiles <- getTile(extent="Brazil")

#dateRange (Jan 2001 - Dec 2014)
dateRange <- transDate(begin="2001-01-01", end="2014-12-31")

####-----NDVI #done
#getSds("/media/drakelab/MVEVANS/Research/brazilYFGISData/MODIS/downloaded/MODIS/MOD13A3.005/2001.01.01/MOD13A3.A2001001.h10v08.005.2007112110242.hdf")
#Sds= "1 km monthly NDVI" 1
runGdal(product="MOD13A3", begin=dateRange$beginDOY, end=dateRange$endDOY, 
        extent="Brazil", 
        SDSstring="1",
        outProj="4326",
        wait=5
                ) #also reformats as a tiff and mosaics together #SWEEET #this took 18 hours


###-----Land Cover
runGdal(product="MCD12Q1", begin=dateRange$beginDOY, end=dateRange$endDOY, 
        extent="Brazil", 
        SDSstring="1",
        outProj="4326",
        wait=5)


###----LST
system.time( #45 hours
runGdal(product="MOD11A2", begin=dateRange$beginDOY, end=dateRange$endDOY, 
        extent="Brazil", 
        SDSstring="1",
        outProj="4326",
        wait=5)
)