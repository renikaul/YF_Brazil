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
RankFull$Model <- factor(c(rep("Single Point Process", dim(Full)[1]),
                           rep("LRR", dim(LFull)[1]),
                           rep("HRR", dim(HFull)[1])),
                         levels=c("Single Point Process", "LRR", "HRR"))
#order the variable levels
RankFull <- within(RankFull,
                   Variable <- factor(Variable, 
                                      levels = c("popLog10", "spRich","RFsqrt","tempMean","NDVIScale", "tempScale","primProp",
                                                  "RFScale","fireDenScale","NDVI", "fireDenSqrt")))

#RankFull$varImp <- as.numeric(as.character(RankFull$varImp))
#variable names
niceNames <- c("popLog10"="Population",
               "spRich" = "NHP Richness",
               "RFsqrt" = "Mean Rainfall",
               "tempMean" = "Mean Temperature",
               "NDVIScale" = "Scaled NDVI",
               "tempScale" = "Scaled Mean Temperature",
               "primProp" = "NHP Agriculture Overlap",
               "RFScale" = "Scaled Mean Rainfall",
               "fireDenScale" = "Scaled Fire Density",
               "NDVI" ="NDVI",
               "fireDenSqrt" ="Fire Density")

#Relative Imp Plots

b <-  ggplot(RankFull, aes(x=Variable, y=varImp,fill=Model)) + 
  geom_bar(stat="identity",position="dodge") +
  ylab("Relative Importance") + xlab("variable") +
   scale_y_continuous(expand = c(0, 0)) +
   scale_x_discrete("",labels=niceNames) +
  theme_few()+
  theme(axis.text.x=element_text(angle=35, hjust=1), legend.position = c(.8,.8) ) +
  scale_fill_tableau("colorblind10")

tiff("figures/manuscript/VarImp.tiff")
plot(b)
dev.off()
# Coord Plot ----
 ##must run Variable importance plot first
#cord plot business
RankFull <- within(RankFull,
                   Variable <- factor(Variable, 
                                      levels = c( "fireDenSqrt","NDVI", "fireDenScale","RFScale","primProp", "tempScale","NDVIScale","tempMean", "RFsqrt","spRich", "popLog10" )))

justNames <- c("Population",
               "NHP Richness",
               "Mean Rainfall",
               "Mean Temperature",
                "Scaled NDVI",
               "Scaled Mean\nTemperature",
               "NHP Agriculture\nOverlap",
               "Scaled Mean\nRainfall",
                "Scaled Fire\nDensity",
               "NDVI",
               "Fire Density") 

y_levels <- levels(RankFull$Variable)

p <- ggplot(RankFull, aes(x = Model, y = varRank, group = Variable)) +   # group = id is important!
  geom_hline(yintercept = c(1:11), color="grey80", linetype=2) +
  geom_path(aes(color = Variable),lineend = 'round', linejoin = 'round', size=2) +
  scale_y_discrete(limits = levels(RankFull$Variable), labels=c(11:1)) + #ylim/lab details
  ylab("Variable Importance Rank") +
  xlab("Model")+
  theme_few() +
  scale_x_discrete(expand = c(0, 1)) +
  annotate("text", x = c(0.5), y=c(11:1), label = justNames) + 
  theme(legend.position = "none") 

tiff("figures/manuscript/Rank.tiff")
plot(p)
dev.off()





library(tidyverse)

mtcars <- within(mtcars, cyl <- factor(cyl, levels=c(4,6,8)))
ggplot(mtcars) + 
  geom_boxplot(aes(factor(cyl), mpg))+ 
 scale_x_discrete(labels = c('Four','Six','Eight'))
