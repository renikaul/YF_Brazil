#This document compiles the single year YF case by muni and month files into a single long format dataframe with muni coded using Brazilian gov coding. 
#Updated to 2001 muni boundaries Sept 19, 2017 RK
#file paths writen from data_processingScripts

#Case counts

  library(tidyr)
  library(reshape2)
  years <- c("01","02","03","04","05","06","08","09","10","13")
  mon <- c(9,6,7,4,5,
           3,7,9,4,
           4)

    YF.long <- NULL #final data file
for (j in 1:length(years)){
  yr <- years[j]
#read in data
  d <- read.csv(paste("../data_raw/YF_infection/YF_20", yr,".txt", sep=""), sep=",", encoding="UTF-8",colClasses = c("numeric","character", rep("numeric",mon[j])))
  
  #d <- d[,-c(ncol(d))]   #drop total for that month
  #2. Add year ----
    d$year <- 2000+j 
  #3. Reshape table to long format ----
    tmp2 <- reshape2::melt(d, id = c("Muni", "muni.no", "year"))
  #4. Save long format
    YF.long <- rbind(YF.long, tmp2)
}

    
  #5. check for cases in any of the emancipated muni ----
    correctedMuni <- read.csv("../data_raw/demographic/muniCorrections.csv")
    
    #pull out those created post 2001
    YF.long[which(YF.long$muni.no %in% correctedMuni$muni.no),]
    # none
    
  #6. Add year mon ----
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
    cont.mon.conversion$year <-  as.numeric(as.character(cont.mon.conversion$year))
    cont.mon.conversion$year <-  as.numeric(as.character(cont.mon.conversion$year))
    
  #7. Add month.no to YF.long ----
    YF <- left_join(YF.long, cont.mon.conversion, by=c("year", "variable"))
      #tidy it up by ordering by month.no
    YF <- YF[order(YF$month.no),]
    colnames(YF) <- c('muni','muni.no','year', 'month', 'case','cal.month', 'month.no') #clean up names
  #8. drop yearly totals, add zero, and case ----
    YF$case[is.na(YF$case)] <- 0
    
    YF <- YF %>%
      filter(cal.month < 13) %>%
      mutate(numCase = case) %>%
      mutate(case = ifelse(numCase ==0,0,1))
      
     #final data set has entries for all muni for each month that a case was reported    
  # 9. Save the work ----
    saveRDS(YF, file="../data_clean/YFcases/YFlong_infection.rds")
    write.csv(YF, "../data_clean/YFcases/YFlong_infection.csv")
  

    
    
    
