#This document compiles the single year YF case by muni and month files into a single long format dataframe with muni coded using Brazilian gov coding. 

#Case counts

  library(tidyr)
  library(reshape2)
  years <- c("01","02","03","04","05","06","07","08","09","10","11","12","13","14")
  mon <- c(9,6,7,4,5,
           3,1,7,9,4,
           1,1,4,2)

    YF.long <- NULL #final data file
for (j in 1:length(years)){
  yr <- years[j]
#read in data
  d <- read.csv(paste("YF_20", yr,".txt", sep=""), sep=",", encoding="UTF-8",colClasses = c("character", rep("numeric",mon[j])))
  
  #d <- d[,-c(ncol(d))]   #drop total for that month
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
    d$year <- 2000+j 
  #3. Reshape table to long format
    tmp2 <- melt(d, id = c("Muni", "muni.no", "year"))
  #4. Save long format
    YF.long <- rbind(YF.long, tmp2)
}
    
  #5. Add year mon
      #build conversion table
    port.mon <- c('Jan','Fev','Mar',	'Abr',	'Mai','Jun', 'Jul', 'Ago', 'Set',	'Out',	'Nov',	'Dez')
    cal.month <- c(1:12) 
    years <- 2000+c(1:14)
    cont.mon.conversion <- as.data.frame(cbind(variable=c(rep(port.mon,14), rep('Total',14)), 
                                               cal.month=c(rep(cal.month,14), rep(13,14)), #cal month 13 are totals for that year * muni
                                               year=c(rep(years, each=12), 
                                               years)))
    cont.mon.conversion[,2] <- as.numeric(as.character(cont.mon.conversion[,2]))
      #count month 1 to n starting with Jan 2001
    cont.mon.conversion$month.no <- c(1:nrow(cont.mon.conversion))
      #month.no 169 to 182 are year totals
  
  #6. Add month.no to YF.long
    YF.long <- merge(YF.long, cont.mon.conversion, by=c("year", "variable"))
      #tidy it up by ordering by month.no
    YF <- YF.long[order(YF.long$month.no),]
    colnames(YF) <- c('year', 'month', 'muni', 'muni.no','case','cal.month', 'month.no') #clean up names
    
  # 7. Save the work
    saveRDS(YF, file="YFlong.rds")
    
    
    
    