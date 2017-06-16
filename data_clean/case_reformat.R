#Case counts

setwd("/Users/renikaul/Documents/Brazil_YF/")

d <- read.csv("./data_clean/YF_2001.txt", sep=",", encoding="UTF-8",colClasses = c("character", rep("numeric",5)))

#1. Pull out muni no 
d.names <- strsplit(d$Muni, " " ) #return list of list where first entery is muni no.

#pull out first entry in the list and save
muni.no <- c()

for (i in 1:length(d.names)){
  tmp <- d.names[[i]] 
  muni.tmp <- tmp[1]
  muni.no <- c(muni.no, muni.tmp)
}

muni.no <- as.numeric(muni.no)
d$muni.no <- muni.no
#2. Add year
d$year <- 





#2. convert month name to month no
port.mon <- c('Jan','Fev','Mar',	'Abr',	'Mai','Jun', 'Jul', 'Ago', 'Set',	'Out',	'Nov',	'Dez')


substring(d$Muni, seq(1,nchar(d$Muni),2), seq(2,nchar(x),2))
