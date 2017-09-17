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

tmp <- pop[which(pop$muni.no %in% correctedMuni$muni.no),]

for( i in 1:nrow(correctedMuni)){
  pop$muni.no[correctedMuni$muni.no %in% pop$muni.no[i]] <- correctedMuni$mother
}
pop$muni.no[match(pop$muni.no, correctedMuni$muni.no)] <- correctedMuni$mother



#create dataframe with 12 rows per municipo - one for each month
pop.months<-do.call(rbind, replicate(12, pop[1,], simplify=FALSE))
for (i in 2:nrow(pop)) {
  tmp<-do.call(rbind, replicate(12, pop[i,], simplify=FALSE))
  pop.months<-rbind(pop.months,tmp)
}
#add numeric months to dataframe
month<-rep(1:12, nrow(pop))
pop.new<-cbind(pop.months[,1:2],month,pop.months[,3:16])
#name dataframe columns
colnames(pop.new)<-c("muni","muni.no","month",as.character(2001:2014))

