#######
## Figures for manuscript
## R. Kaul 1/27/18
######

#global packages
library(dplyr)
library(ggplot2)
# ROC plots ----


# Dodged Variable Importance ----

#1. load packages and functions

#Return Quick Rank Importance
RankImp=function(x){
  #pull out Relative Importance
  RI <- x[[1]]
  #order and add rank
  RI <- RI %>%
    dplyr::arrange(desc(varImp)) %>%
    dplyr::mutate(varRank=1:dim(RI)[1])
  
  return(RI)
}


#2. Load data
#Whole Country Model 
fullM <- readRDS("../data_out/SpaceAndTimeSplit/Trim2014/Perm10FullModel500TryCatch.rds") 

#NHP Split Model
lowM <- readRDS("../data_out/TwoModelSoln/Trim2014/LPermFullModelTryCatch.rds")
highM <- readRDS("../data_out/TwoModelSoln/Trim2014/HPermFullModelTryCatch.rds")

#3. Pull out variable importance from permutations
Full <- RankImp(fullM)
HFull <- RankImp(highM)
LFull <- RankImp(lowM)

RankFull <- rbind(Full,LFull, HFull)
RankFull$Model <- factor(c(rep("Full", dim(Full)[1]),
                           rep("Low NHP", dim(LFull)[1]),
                           rep("High NHP", dim(HFull)[1])),
                         levels=c("Full", "Low NHP", "High NHP"))
#order the variable levels
RankFull <- within(RankFull,
                   Variable <- factor(Variable, 
                                      levels = c( "spRich", "popLog10", "RFsqrt","tempMean","NDVIScale","RF","primProp","RFScale","tempScale","NDVI", "fireDenScale", "fireDenSqrt")))

RankFull$varImp <- as.numeric(as.character(RankFull$varImp))

#Relative Imp Plots

b <- ggplot(RankFull, aes(x=Variable, y=varImp,fill=Model)) + 
  geom_bar(stat="identity",position="dodge") +
 #facet_grid(Model~.) +
  ylab("Relative Importance") + xlab("variable") +
  theme(axis.text.x=element_text(angle=45, hjust=1))
plot(b)
