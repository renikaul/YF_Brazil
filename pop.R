pop<-read.csv("/Users/annakate/Desktop/YF_Brazil/data_raw/demographic/population-edited.csv", sep=";", skip=4,
              header=F, nrows=5570, encoding="UTF-8", colClasses=c(rep("NULL",16), "character", rep("numeric",16)))
#cut out irrelevant years (2015, 2016)
pop<-pop[,1:15]

#split municipo # and name from extra pop'n #
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

#create dataset with 12 rows per municipo - one for each month
pop.months<-do.call(rbind, replicate(12, pop[1,], simplify=FALSE))
for (i in 2:nrow(pop)) {
  tmp<-do.call(rbind, replicate(12, pop[i,], simplify=FALSE))
  pop.months<-rbind(pop.months,tmp)
}
#add numeric months
month<-rep(1:12, nrow(pop))
pop.new<-cbind(pop.months[,1:2],month,pop.months[,3:16])
#name dataframe columns
colnames(pop.new)<-c("muni","muni.no","month",as.character(2001:2014))

write.csv(pop.new, "/Users/annakate/Desktop/YF_Brazil/data_raw/demographic/population-new.csv")

