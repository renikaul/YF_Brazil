#data and packages
muni.map<-readShapePoly("../data_clean/BRAZpolygons.shp") # @data has muni # and name
yf.long<-readRDS("../data_clean/YFcases/YFlong.rds")
library(maptools)
library(shapefiles)
library(rgeos)
library(geosphere)
library(surveillance)
library(plyr)
library(dplyr)
library(ggplot2)
library(magrittr)

###1. find centroids

cent<-gCentroid(muni.map, byid=TRUE) #find muni centroids
cent.df<-SpatialPointsDataFrame(cent, muni.map@data, match.ID=FALSE) #save in dataframe

###2. calculate distances between centroids

#use 'distm' with default distHaversine function
c.dist<-distm(cent.df) #output in meters

#check distances
max(c.dist) #4,559,347 m or 4559 km
  #Encyclopedia of the Nations (website) says longest distances across Brazil are ~4200 km
#there's also 'distGeo' but I think that would require a loop to take all differences

###3. statistics

#yf.long has 33 extra muni#s compared to shapefile, but they are otherwise the same
n<-unique(as.numeric(yf.long$muni.no)) #5597
m<-unique(as.numeric(as.character(cent.df@data$muni_no))) #5564
# sum(as.factor(n) %in% as.factor(m)) #shapefile contains 5564 of 5597 from yf.long
# sum(as.factor(m) %in% as.factor(n)) #yf.long contains 5564 of 5564 from shapefile

#so let's only consider yf.long muni#s with shapefile data
yf.long1<-yf.long[as.factor(as.numeric(yf.long$muni.no)) %in% m,]

#confirm that yf.long1 and shapefile now have the same muni#s
p<-unique(as.numeric(yf.long1$muni.no))
# sum(as.factor(p) %in% as.factor(m))
# sum(as.factor(m) %in% as.factor(p))

#########################
#find distance to nearest infected muni in the same month
#########################

#add dummy var for whether or not there is another infected muni
#if so, find distance
#if not, set distance to 0

dist.inf<-as.data.frame(matrix(nrow=nrow(yf.long1), ncol=7))
colnames(dist.inf)<-c("year", "month", "month.no", "focal.muni.no", "distance", "inf.muni.no", "cases.no")

month.index<-1

for (i in unique(yf.long1$month.no)) { #for each month.no
  #limit case data to month i
  yf<-yf.long1[as.numeric(yf.long1$month.no)==i,]
  
  #vectors for data
  focal.muni.no<-rep(NA,ncol(c.dist))
  distance<-rep(NA,ncol(c.dist))
  inf.muni.no<-rep(NA,ncol(c.dist))
  cases.no<-rep(NA,ncol(c.dist))
  
  for (j in 1:ncol(c.dist)) { #for each muni with distance data
    #attach muni#s to centroid distances for muni j
    dist<-as.data.frame(cbind(as.numeric(as.character(cent.df@data$muni_no)), as.numeric(c.dist[,j])))
    colnames(dist)<-c("muni.no", "dist")
    #combine spatial and case data
    dist.case<-join(as.data.frame(dist), yf, by="muni.no")
    #remove current focal muni and entries with NA cases
    dist.case1<-dist.case[dist.case$dist!=0 & !is.na(dist.case$case),]
    
    #find min dist to muni with cases (if there isn't one, insert NA)
    distance[j]<-ifelse(nrow(dist.case1)>0, min(dist.case1$dist), NA)
    #pull other relevant info
    inf.muni.no[j]<-ifelse(nrow(dist.case1)>0, dist.case1[dist.case1$dist==distance[j],1], NA)
    cases.no[j]<-ifelse(nrow(dist.case1)>0, dist.case1[dist.case1$dist==distance[j],6], NA)
    focal.muni.no[j]<-dist[j,1]
  }
  
  #save data
  row.start<-((month.index-1)*5564)+1
  row.end<-row.start+5563
  dist.inf$year[row.start:row.end]<-yf$year
  dist.inf$month[row.start:row.end]<-yf$month
  dist.inf$month.no[row.start:row.end]<-yf$month.no
  dist.inf$focal.muni.no[row.start:row.end]<-focal.muni.no
  dist.inf$distance[row.start:row.end]<-distance
  dist.inf$inf.muni.no[row.start:row.end]<-inf.muni.no
  dist.inf$cases.no[row.start:row.end]<-cases.no
  
  month.index<-month.index+1

}

#########################
#find distance to nearest infected muni in the previous month
#########################

#add dummy var for whether or not there is any infected muni in the previous month
#if so, find distance (including 0 for distance to self)
#if not, set distance to 0

dist.prev<-as.data.frame(matrix(nrow=nrow(yf.long1), ncol=7))
colnames(dist.prev)<-c("year", "month", "month.no", "focal.muni.no", "distance", "inf.muni.no", "cases.no")

month.index<-1

for (i in unique(yf.long1$month.no)) { #for each month.no
  #limit case data to month i
  yf<-yf.long1[as.numeric(yf.long1$month.no)==i,]
  
  #vectors for data
  focal.muni.no<-rep(NA,ncol(c.dist))
  distance<-rep(NA,ncol(c.dist))
  inf.muni.no<-rep(NA,ncol(c.dist))
  cases.no<-rep(NA,ncol(c.dist))
  
  for (j in 1:ncol(c.dist)) { #for each muni with distance data
    #attach muni#s to centroid distances for muni j
    dist<-as.data.frame(cbind(as.numeric(as.character(cent.df@data$muni_no)), as.numeric(c.dist[,j])))
    colnames(dist)<-c("muni.no", "dist")
    #combine spatial and case data
    dist.case<-join(as.data.frame(dist), yf, by="muni.no")
    #remove current focal muni and entries with NA cases
    dist.case1<-dist.case[dist.case$dist!=0 & !is.na(dist.case$case),]
    
    #find min dist to muni with cases (if there isn't one, insert NA)
    distance[j]<-ifelse(nrow(dist.case1)>0, min(dist.case1$dist), NA)
    #pull other relevant info
    inf.muni.no[j]<-ifelse(nrow(dist.case1)>0, dist.case1[dist.case1$dist==distance[j],1], NA)
    cases.no[j]<-ifelse(nrow(dist.case1)>0, dist.case1[dist.case1$dist==distance[j],6], NA)
    focal.muni.no[j]<-dist[j,1]
  }
  
  #save data
  row.start<-((month.index-1)*5564)+1
  row.end<-row.start+5563
  dist.prev$year[row.start:row.end]<-yf$year
  dist.prev$month[row.start:row.end]<-yf$month
  dist.prev$month.no[row.start:row.end]<-yf$month.no
  dist.prev$focal.muni.no[row.start:row.end]<-focal.muni.no
  dist.prev$distance[row.start:row.end]<-distance
  dist.prev$inf.muni.no[row.start:row.end]<-inf.muni.no
  dist.prev$cases.no[row.start:row.end]<-cases.no
  
  month.index<-month.index+1
  
}
