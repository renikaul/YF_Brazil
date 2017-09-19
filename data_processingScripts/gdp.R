#This script pulls in X (info about data format) and reshapes by 

#This code reshapes the 2001-2012 and 2010-2013 so that the overlapping values can be compared. 

#file paths writen from data_clean

#packages
library(tidyr)
library(reshape2)

#1. GDP for the years from 2000 to 2012
#read in slightly edited data
gdp<-read.csv("../data_raw/demographic/GDP01_12.txt", sep=";",  encoding="UTF-8", colClasses=c("character", rep("numeric",12)))

#drop last row, total country
gdp <-  gdp[-nrow(gdp),]
#split municipio # and name from extra gdp # in column 1 by spliting on first space
#a. Pull out muni no 
d.names <- strsplit(gdp$Muni, " " ) #return list of list where first entery is muni no.
#pull out first entry in the list and save
muni.no <- c()
for (i in 1:length(d.names)){
  tmp <- d.names[[i]] 
  muni.tmp <- tmp[1]
  muni.no <- c(muni.no, muni.tmp)
}
muni.no <- as.numeric(muni.no)
gdp$muni.no <- muni.no
#quick rename col
colnames(gdp) <-  c("Muni", "2001", "2002", "2003", "2004", "2005", "2006", "2007", "2008", "2009", "2010", "2011", "2012", "muni.no")
#reshape so easier to order and compare
gdp <- melt(gdp, id=c("Muni", "muni.no"), variable.name="year", value.name = "GDP")


#2. Repeat the process for second data file 2010-2013
gdp2<-read.csv("../data_raw/demographic/GDP10_13.txt", sep=";",  encoding="UTF-8", colClasses=c("character", rep("numeric",4)))

#drop last row, total country
gdp2 <-  gdp2[-nrow(gdp2),]
#split municipio # and name from extra gdp # in column 1 by spliting on first space
#a. Pull out muni no 
d.names <- strsplit(gdp2$Muni, " " ) #return list of list where first entery is muni no.
#pull out first entry in the list and save
muni.no <- c()
for (i in 1:length(d.names)){
  tmp <- d.names[[i]] 
  muni.tmp <- tmp[1]
  muni.no <- c(muni.no, muni.tmp)
}
muni.no <- as.numeric(muni.no)
gdp2$muni.no <- muni.no
#quick rename
colnames(gdp2) <- c("Muni", "2010","2011", "2012","2013", "muni.no")
#reshape so easier to order and compare
gdp2 <- melt(gdp2, id=c("Muni", "muni.no"), variable.name="year", value.name = "GDP")


#3. check to see if overlapping yrs: 10,11,and 12 is the same between the data sets
#based on https://stackoverflow.com/questions/15625511/comparing-two-dataframes-and-printing-specific-rows-in-matching-values-for-a-sin
library(data.table)

#convert year from factor to number
gdp$year <- as.numeric(as.character(gdp$year))
gdp2$year <- as.numeric(as.character(gdp2$year))

#pull out overlapping yrs
tmp <- gdp[which(gdp$year==2012),]
tmp <- tmp[,-1]

tmp2 <- gdp2[which(gdp2$year==2012),]
tmp2 <- tmp2[,-1]
#convert to tables 
tmp <- data.table::data.table(tmp, key=c('muni.no', 'year'))
tmp2 <- data.table::data.table(tmp2, key=c('muni.no', 'year'))

#return all the rows that don't match by GDP
gdp.diff <- tmp[tmp2, nomatch=0]







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
write.csv(gdp.long, "gdp1-long.csv")

