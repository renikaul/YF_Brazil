#packages
library(tidyr)
library(reshape2)

#read in slightly edited data
gdp<-read.csv("/Users/annakate/Desktop/YF_Brazil/data_raw/demographic/gdp1.csv", sep=";", skip=1,
              header=F, nrows=5565, encoding="UTF-8", colClasses=c(rep("NULL",9), "character", rep("numeric",9)))

#split municipo # and name from extra gdp # in column 1
col1<-strsplit(gdp[,1], "," )
#save muni # and name
name.and.num<-list()
for (i in 1:length(col1)){
  tmp<-col1[[i]]
  name.and.num[[i]]<-tmp[2]
}
#save muni # and name as character
nn<-as.character(name.and.num)
#replace first col of gdp dataframe
gdp[,1]<-nn

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
gdp<-cbind(gdp[,1],muni.no,gdp[,2:10])
#name dataframe columns
colnames(gdp)<-c("muni","muni.no",as.character(2001:2009))

#create dataframe with 12 rows per municipo - one for each month
gdp.months<-do.call(rbind, replicate(12, gdp[1,], simplify=FALSE))
for (i in 2:nrow(gdp)) {
  tmp<-do.call(rbind, replicate(12, gdp[i,], simplify=FALSE))
  gdp.months<-rbind(gdp.months,tmp)
}
#add numeric months to dataframe
month<-rep(1:12, nrow(gdp))
gdp.new<-cbind(gdp.months[,1:2],month,gdp.months[,3:11])
#name dataframe columns
colnames(gdp.new)<-c("muni","muni.no","month",as.character(2001:2009))

#convert dataframe to long format - one row per muni per month per year
gdp.long<-melt(gdp.new, id=c("muni", "muni.no","month"))
colnames(gdp.long)<-c("muni","muni.no","month","year","gdp")
#save
write.csv(gdp.long, "/Users/annakate/Desktop/YF_Brazil/data_clean/gdp1-long.csv")

