## Split municipalities into urban and rural
## MV Evans, December 2017
## This document assigns a %urban to each municipality based on landcover data from 2001.

library(SDMTools)
library(dplyr)

#read in landcover statistics spit out by ClassStats function
stats <- readRDS("../data_raw/environmental/landCover2001.rds")

#urban land class is 13, prop.landscape is % of landscape
urban <- stats %>%
  filter(class == 13) %>%
  mutate(muni.no = as.numeric(substr(ibgCode,1,6))) %>%
  select(muni.no, percUrban = prop.landscape)

#note that there are muni's missing values, these are ones that had no urban areas
# add in the other municipality numbers to fill these in
allMunis <- readRDS("../data_clean/YFcases/YFlong.rds")
allMunis <- data.frame(muni.no = unique(allMunis$muni.no))

#join together
urbanAll <- full_join(allMunis, urban, by = "muni.no")
#fill in for zeros
urbanAll$percUrban[is.na(urbanAll$percUrban)] <- 0
# correct municipalities that were emancipated during the time
muniCorr <- read.csv("../data_raw/demographic/muniCorrections.csv")

urbanAll$old.no <- urbanAll$muni.no #old.no is muni.no pre-2010

for (i in 1:nrow(muniCorr)){
  urbanAll$muni.no[urbanAll$old.no==muniCorr$muni.no[i]] <- muniCorr$mother[i]
}

#take mean for any that were combined
percUrban <- urbanAll %>%
  select(-old.no) %>%
  group_by(muni.no) %>%
  summarise_all(mean)

