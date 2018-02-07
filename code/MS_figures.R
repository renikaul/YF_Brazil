#######
## Figures for manuscript
## R. Kaul 1/27/18
######

#global packages
library(dplyr)
library(ggplot2)
library(ggthemes)
# Dodged Variable Importance ----

#1. load packages and functions

#Return Quick Rank Importance
RankImp=function(x){
  #pull out Relative Importance
  RI <- x[[1]]
  #convert varImp to numeric (coming out as factor for some reason)
  RI$varImp <- as.numeric(as.character(RI$varImp))
  #order and add rank
  RI <- RI %>%
    dplyr::arrange(desc(varImp)) %>%
    dplyr::mutate(varRank=dim(RI)[1]:1)
  
  return(RI)
}


#2. Load data
#Whole Country Model 
#fullM <- readRDS("../data_out/SpaceAndTimeSplit/Trim2014/Perm10FullModel500TryCatch.rds") 

#NHP Split Model
#lowM <- readRDS("../data_out/TwoModelSoln/Trim2014/LPermFullModelTryCatch.rds")
#highM <- readRDS("../data_out/TwoModelSoln/Trim2014/HPermFullModelTryCatch.rds")
fullM <- readRDS("../data_out/MS_results/OneModel/Perm100FullModel500TryCatch.rds") 
lowM <- readRDS("../data_out/MS_results/LowModel/lPerm100Model500TryCatch.rds")
highM <- readRDS('../data_out/MS_results/HighModel/HPerm100Model500TryCatch.rds')

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
                                      levels = c( "fireDenSqrt","NDVI", "fireDenScale","RFScale","primProp", "tempScale","NDVIScale","tempMean", "RFsqrt","spRich", "popLog10" )))

#RankFull$varImp <- as.numeric(as.character(RankFull$varImp))

#Relative Imp Plots

b <- ggplot(RankFull, aes(x=Variable, y=varImp,fill=Model)) + 
  geom_bar(stat="identity",position="dodge") +
 #facet_grid(Model~.) +
  ylab("Relative Importance") + xlab("variable") +
  theme(axis.text.x=element_text(angle=45, hjust=1)) +
  theme_minimal()+
  scale_fill_tableau("colorblind10")
  
plot(b)

# Coord Plot ----
 ##must run Variable importance plot first
#cord plot business
RankFull <- within(RankFull,
                   Variable <- factor(Variable, 
                                      levels = c( "fireDenSqrt","NDVI", "fireDenScale","RFScale","primProp", "tempScale","NDVIScale","tempMean", "RFsqrt","spRich", "popLog10" )))


y_levels <- levels(RankFull$Variable)

p <- ggplot(RankFull, aes(x = Model, y = varRank, group = Variable)) +   # group = id is important!
  geom_path(aes(color = Variable),lineend = 'round', linejoin = 'round') +
  scale_y_discrete(limits = levels(RankFull$Variable)) + #ylim/lab details
  ylab("Rank Importance (1 is most important)") +
#  scale_x_discrete(labels = c('Four','Six','Eight')) +
  xlab("Model")+
  annotate("text", x = c(0.75), y=c(1,2,3,4), label = c("two", "ship", "six", "boat")) + 
  theme(legend.position = "none") 

plot(p)





library(tidyverse)

mtcars <- within(mtcars, cyl <- factor(cyl, levels=c(4,6,8)))
ggplot(mtcars) + 
  geom_boxplot(aes(factor(cyl), mpg))+ 
 scale_x_discrete(labels = c('Four','Six','Eight'))
