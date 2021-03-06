#script reads in all the data, assembles it and saves the final dataset in data_clean/FinalData.rds
#Covarate information 

# case :reporting of any YF cases (0,1)
# NumCase :number of reported YF cases

# NDVI : NDVI for that month
# NDVIScale : NDVI rescaled to max value for that muni and calendar month

# popLog10 : population density

# RF : mean hourly rainfall
# RFScale : mean hourly rainfall rescaled to max value for that muni and calendar month

# tempMean : mean monthly air temperature
# tempScale : mean monthly air temperature rescaled to max value for that muni and calendar month

# fireDenSqrt : number of fires oberserved in month divided by muniArea sqrt transformed
# firesDenScale : number of fires oberserved in month divided by muniArea rescaled to max value for that muni and calendar month. NA values converted to zero. 

# spRich : number of non-human primates by species with ranges based on IUCN {0-22}

# primProp : sum of each municipalities relative area that is both agricultural and falls within a primate genus range. {0,9} Missing for 2014

# vectorOcc : maximum probability of a known spillover vector occuring within that municipality

# muni.no : unique number to identify municipality
# month.no : numbered month of observation {1,168}
# muni.name : character string name
# month : abbrevated calendar month name
# cal.month : calendar month {1,12}
# year : year {2001,2014}

#1. Load packages-------------------------

library(dplyr)
library(gplots)
library(ROCR)
library(pROC)
library(rgdal)
library(rgeos)
library(BalancedSampling)
library(scatterplot3d)

#2. Load data-----------------------------

## population---------------------------
    # pop
    # muniArea
    # densitypop
    # PopDenLog
pop <- readRDS("../data_clean/demographic/pop.rds") 

#log transformed variables
# hist(rf$hourlyRainfallMean, main="hourly rainfall") #mean rainfall, exponential

pop <- pop %>%
    filter(year<2014) %>%
    mutate(popLog10 = log(densitypop)) 
    
## rainfall------------------------------ 
    # RFsqrt: sqrt hourly rainfall mean
    # RFScaleMean: hourly mean rainfall divided by max value for muni 
rf <- readRDS("../data_clean/environmental/allRainfall.rds")

#sqrt transformed variables
  # hist(rf$hourlyRainfallMean, main="hourly rainfall") #mean rainfall, exponential
  # hist(sqrt(rf$hourlyRainfallMean), main="hourly rainfall") #mean rainfall, exponential

#scale to maximum value of muni
rf <- rf %>%
  filter(year<2014) %>%
  mutate(RF=hourlyRainfallMean) %>%
  mutate(RFsqrt=sqrt(hourlyRainfallMean)) %>%
  group_by(muni.no, cal.month) %>%
  mutate(RFScale = hourlyRainfallMean/max(hourlyRainfallMean)) %>% #scale rainfall to muni and month
  ungroup()

## NDVI ------------------------------ 
    # NDVI: raw value between 0,1
    # NDVIScale: NDVI divided by max NDVI for muni and month

ndvi <- readRDS("../data_clean/environmental/allNDVI.rds")
  #hist(ndvi$NDVI) #normal

ndvi <- ndvi %>%
  filter(year<2014) %>%
  group_by(muni.no, cal.month) %>%
  mutate(NDVIScale = NDVI/max(NDVI)) %>% #scale NDVI to muni and month
  ungroup()

## temperature------------------------------ 
    #tempMean:
    #tempScale
temp <- readRDS("../data_clean/environmental/meanTemperature.rds")
  #hist(temp$tempMean)

temp <- temp %>%
  filter(year<2014) %>%
  group_by(muni.no, cal.month) %>%
  mutate(tempScale = tempMean/max(tempMean)) %>% #scale NDVI to muni and month
  ungroup()

## Non-human primates------------------------------ 
    #primProp
NHPProp <- readRDS("../data_clean/environmental/primProp.rds") #changes every year, missing 2014
    #hist(sqrt(NHP$primProp))
      #transformations are ugly too 

NHPRichness <- readRDS("../data_clean/environmental/primRichness.rds") #doesn't change with time
## Fires ----------------------------------

fires <- readRDS("../data_clean/environmental/nuvectoremFires.rds")
  #hist(fires$numFire) #super overdispersed, only about 20% muniXmonth have had a fire. 6% of muniXmonths have only had a single fire. The upper bound is >5000 per a muniXmonth. 
  #standard transformation really cannot correct for this extreme 
  
 fires <- fires %>%
   filter(year<2014) %>%
   mutate(fireDenSqrt=sqrt(fireDens)) %>%
   mutate(fireNum=numFire) %>% #rename col
   mutate(fireDen=fireDens) %>% #remane col
   group_by(muni.no, cal.month) %>%
   mutate(fireDenScale = ifelse(max(fireDens)==0,0,fireDens/max(fireDens))) %>% #scale fire densities to muni and month
   ungroup() 
 
 ## Mosquito Occurrence -----------------
 
 mosq.occurence <- readRDS("../data_clean/environmental/mosiProb.rds")
   
## YF cases------------------------------ 
cases <- readRDS("../data_clean/YFcases/YFlong.rds")
 #dimensions: Entries for all muni ONLY if a case reported in any muni that month
cases[is.na(cases)] <- 0 #replace NA with zero  

cases <- cases %>%
  filter(year<2014) %>%
  #drop annual totals
  filter(cal.month<=12) %>%
  #drop unknown origin totals %>%
  filter(!grepl("ignorado", muni)) %>%
  mutate(NumCase=case) %>% 
  mutate(case=ifelse(NumCase==0,0,1))


#3. Assemble data--------------------------

  #Put all the things together!  
all.enviro <- plyr::join_all(list(ndvi, pop, rf, temp, fires), 
                           by=c("muni.no", "month.no"), type="full") %>%
              select(-c(muni))

# add in NHP for each year and muni
# all.data <-  all.data %>%
#               left_join(NHP, by=c("muni.no", "year")) %>% 
#               mutate(muni.name= muni.name.x) %>%
#               select(-c(muni.name.y, muni.name.x)) #drop second muni.name

#add in NHP Richness for each muni
NHPenviro <- NHPRichness %>%
             select(-c(muni.name)) %>%
            dplyr::right_join(all.enviro, by=c('muni.no'))

          
all.covar <- NHPProp %>%
             select(-c(muni.name)) %>%  
            dplyr::right_join(NHPenviro, by=c('muni.no','year'))

#add in cases
all.data <- cases %>%
            select(c(muni.no, month.no, case, NumCase)) %>%
            dplyr::right_join(all.covar, by=c('muni.no', 'month.no')) %>%
            mutate(case=ifelse(is.na(case),0,case)) %>% #replace NA with zero
            mutate(NumCase=ifelse(is.na(NumCase),0,NumCase)) #replace NA with zero

#4. Clean it up -------------

final.data <- all.data[c("case", "NumCase",
                       "popLog10","NDVI","NDVIScale",
                        "RFsqrt","RFScale",
                        "tempMean","tempScale",
                        "fireDenSqrt","fireDenScale",
                        "spRich","primProp",
                        "muni.no", "month.no", "muni.name", "cal.month","year")]


#5. Split the data ----------------------

all.data <- final.data[order(-final.data$case, final.data$month.no),] 

all.pres <- filter(all.data, case==1)
all.bg <- filter(all.data, case==0)

#Split infected municipalities
#test.pres.inds <- base::sample(nrow(all.pres), ceiling(nrow(all.pres)/3)) #without year stratification
test.pres.inds <- seq(1,nrow(all.pres), by=3) #with year stratification
test.pres <- all.pres[test.pres.inds,]
train.pres <- all.pres[-test.pres.inds,]

#Split background data
test.bg.inds <- base::sample(nrow(all.bg), ceiling(nrow(all.bg)/3))
test.bg <- all.bg[test.bg.inds,]
train.bg <- all.bg[-test.bg.inds,]

training <- rbind(train.pres, train.bg)
testing <- rbind(test.pres, test.bg)

#6. Save data ---------------------------
#individual training and testing data
saveRDS(training, file="../data_clean/TrainingData.rds")
saveRDS(testing, file="../data_clean/TestingData.rds")
saveRDS(final.data, file="../data_clean/FinalData.rds")

#index of data to create training and testing
save(test.pres.inds, test.bg.inds, file="IndexForDataSplit.RData")

#7. Split the data spatially and temporally (from #4)----------------------

#get lat long coordinates for positive cases
brazil <- readOGR("../data_clean", "BRAZpolygons")
muni.centroids <- data.frame(muni_no = brazil@data$muni_no, gCentroid(brazil, byid = T)@coords)
colnames(muni.centroids) <- c("muni.no", "x", "y")

all.pres <- filter(final.data, case==1)
all.bg <- filter(final.data, case==0)

#calculate index to split presence on based on x, y, and month.no
pres.meta <- all.pres %>%
  left_join(muni.centroids, by = "muni.no") %>%
  select(muni.no, month.no, x, y)
N <- nrow(pres.meta) # size of all data
n <- ceiling(0.30*N) # sample size, testing data = 30%
p <- rep(n/N,N) # base inclusion probability 
X <- as.matrix(pres.meta[2:4])
set.seed(8675309)
test.pres.inds <- lcube(p, X, cbind(p))

#calculate index to split presence on based on x, y, and month.no
bg.meta <- all.bg %>%
  left_join(muni.centroids, by = "muni.no") %>%
  select(muni.no, month.no, x, y)
N <- nrow(bg.meta) # size of all data
n <- ceiling(0.30*N) # sample size, testing data = 30%
p <- rep(n/N,N) # base inclusion probability 
X <- as.matrix(bg.meta[2:4])
set.seed(8675309)
test.bg.inds <- lcube(p, X, cbind(p))


## visualize randomness to check
# s <- test.pres.inds
# randPlot <- scatterplot3d(x = X[,1], y = X[,2], z = X[,3])
# randPlot$points3d(x = X[s,1], y = X[s,2], z = X[s,3], col = "black", pch = 19)
# #multiple 2d
# plot(X[,1], X[,2])
# points(X[s,1],X[s,2], pch=19); # plot sample
# plot(X[,1], X[,3])
# points(X[s,1],X[s,3], pch=19); # plot sample
# plot(X[,2], X[,3])
# points(X[s,2],X[s,3], pch=19); # plot sample

#split testing
test.pres <- all.pres[test.pres.inds,]
train.pres <- all.pres[-test.pres.inds,]

#split training (not stratified at all because there are so many)
#Split background data
#test.bg.inds <- base::sample(nrow(all.bg), ceiling(nrow(all.bg)/3))
test.bg <- all.bg[test.bg.inds,]
train.bg <- all.bg[-test.bg.inds,]

#combine background and presence into full training and testing data
training <- rbind(train.pres, train.bg)
testing <- rbind(test.pres, test.bg)

#8. Save data with spatial and temporal stratification---------------------------
#individual training and testing data
saveRDS(training, file="../data_clean/TrainingDataSpat2.rds")
saveRDS(testing, file="../data_clean/TestingDataSpat2.rds")

#index of data to create training and testing
save(test.pres.inds, test.bg.inds, file="IndexForDataSplitSpat2.RData")
