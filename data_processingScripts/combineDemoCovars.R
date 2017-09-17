# This script combines the demographic covariate data, converts to long form and corrected to 2001 boundries based on
# muniCoorections.R. The output is the final form for data exploration and model fitting
# RB Kaul September 17 2017

## List of Covariates:
  # Population Size
  # Muni Area
  # Population density (based on above)

#packages
library(tidyr)
library(reshape2)
library(dplyr)
library(mefa)

library(rgdal)
library(raster)
library(rgeos)
# Population ----------------------------------------

#read in slightly edited data
pop<-read.csv("../data_raw/demographic/population-edited.csv", sep=";", skip=4,
              header=F, nrows=5570, encoding="UTF-8", colClasses=c(rep("NULL",16), "character", rep("numeric",16)))
#cut out irrelevant years (2015, 2016)
pop<-pop[,1:15]

#split municipio # and name from extra pop'n # in column 1
col1<-strsplit(pop[,1], ",,,,,,,,,,," )
#save muni # and name
name.and.num<-list()
for (i in 1:length(col1)){
  tmp<-col1[[i]]
  name.and.num[[i]]<-tmp[2]
}
#save muni # and name as character
nn<-as.character(name.and.num)
#replace first col of pop dataframe
pop[,1]<-nn

#split again to separate muni #
split.nn<-strsplit(nn, " ")
#save muni #
muni.no <- c()
for (i in 1:length(split.nn)){
  tmp<-split.nn[[i]] 
  muni.tmp<-tmp[1]
  muni.no<-c(muni.no, muni.tmp)
}

#save muni # as numeric
muni.no<-as.numeric(muni.no)
#add muni # to dataframe
pop<-cbind(pop[,1],muni.no,pop[,2:15])
#name dataframe columns
colnames(pop)<-c("muni","muni.no",as.character(2001:2014))

#collapse emanicipated muni into mother muni based on muniCorrection
correctedMuni <- read.csv("../data_raw/demographic/muniCorrections.csv")

#replace muni.no with mother muni
  #pull out those needing to be replaced
tmp <- pop[which(pop$muni.no %in% correctedMuni$muni.no),]
  #replace them
tmp$muni.no[match(tmp$muni.no, correctedMuni$muni.no)] <- correctedMuni$mother
  #pull out mother muni too
tmp2 <- pop[which(pop$muni.no %in% correctedMuni$mother),]
  #combine emancipated and mother muni
tmp3 <- rbind(tmp, tmp2)
  #group by muni and add together
tmp4 <- tmp3[,-1] %>%
        group_by(muni.no) %>%
        summarise_each(funs(sum))
  #add the muni name back in
orderedMuni <- correctedMuni[order(correctedMuni$mother),]
muni2001 <- cbind(orderedMuni[-9,c(1)], tmp4)
colnames(muni2001) <- c("muni","muni.no",as.character(2001:2014))

#remove those replaced in pop
popLess <- pop[-which(pop$muni.no %in% correctedMuni$muni.no),]
#add the replaced ones back in
pop <- rbind(popLess, muni2001)

#Convert to long form
  #melt to long
pop <- reshape2::melt(pop, id=c("muni", "muni.no"),variable.name = "year", value.name = "pop")
pop$year <- as.numeric(as.character(pop$year))
  #rep each year 12 times
pop <- rep(pop, each=12)
  #add in cal.month
cal.month <- c(1:12)
pop <- cbind(pop, cal.month)
  #add in month.no
month.noFunc <- function(year, month, startYear, startMonth){
  yearsPast <- year-startYear
  monthsPast <- month-startMonth
  totalMonths <- 12*yearsPast + monthsPast + 1
  return(totalMonths)
}

pop$month.no <- month.noFunc(pop$year,pop$cal.month,2001,1)

# Muni Area -------------------------------------------
##Need to check this with rgdal and updated spatial data to 2001 boundary    
muniPoly <- readOGR("../data_clean", "BRAZpolygons") #read in spatial data (4 sperate files)

muniPoly <- spTransform(muniPoly, CRS("+proj=aea +lat_1=-5 +lat_2=-42 +lat_0=-32 +lon_0=-60 +x_0=0 +y_0=0 +ellps=aust_SA +units=m")) #change projection to special SAmerican thing, Albers Conic
muniArea <- gArea(muniPoly, byid=TRUE) #area for each muni
muniAreaKey<- cbind(muni.no=as.numeric(as.character(muniPoly@data$muni_no)), muniArea=(muniArea/1000^2))   #attach area to muniPoly@data
#row.names(muniAreaKey) <- NULL

#add area into pop 
pop<- pop %>%
  merge(muniAreaKey,by="muni.no")  %>%
  mutate(densitypop = totPop/muniArea)

