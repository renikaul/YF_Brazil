
## Figures for manuscript
## R. Kaul 1/27/18


#global packages
library(dplyr)
library(ggplot2)
library(ggthemes)
library(reshape2)

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

# Relative Importance (Drew) ----

RelativeImportance=function(x, model="NA"){
  perms <- x[[3]][complete.cases(x[[3]]),-c(1, dim(x[[3]])[2])] # pull out AUC values, but drop full model and all permuted data columns 
  model.AUC <- as.numeric(as.character(x[[2]][1,2])) # pull out AUC for full model
  # calculate delta AUC
  delta.AUC <- model.AUC- perms
  # scale delta AUC between zero and one
  scale.delta.AUC <- delta.AUC/max(delta.AUC)
  #calculate median, upper and lower quantiles
  Quant.dAUC <- scale.delta.AUC %>% 
    melt(value.name="dAUC") %>% 
    rename(Rep=Var1, Variable=Var2)%>% 
    group_by(Variable) %>%
    summarise(dAUCmean=mean(dAUC),dAUCmedian=median(dAUC),Q975=quantile(dAUC, probs=0.975),Q025=quantile(dAUC, probs=0.025) ) %>%
    arrange(desc(Q975)) %>%
    mutate(Model=model)
  return(Quant.dAUC)
}


hri <- RelativeImportance(highM, "High")
hri <- within(hri, Variable <- factor(Variable, levels = c( "popLog10","spRich","NDVIScale","tempMean","fireDenScale","tempScale", "primProp", "RFsqrt", "RFScale","NDVI","fireDenSqrt")))


lri <- RelativeImportance(lowM, "Low")
lri <- within(lri, Variable <- factor(Variable, levels = c( "popLog10","spRich","RFsqrt","tempMean","NDVIScale","primProp", "NDVI","tempScale","RFScale","fireDenSqrt","fireDenScale")))

fri <- RelativeImportance(fullM, "Single")
fri <- within(fri, Variable <- factor(Variable, levels = c( "popLog10","spRich","RFsqrt","NDVIScale","tempScale","tempMean","NDVI","RFScale","primProp","fireDenSqrt","fireDenScale")))

allRelImportance <- within(allRelImportance, Model <- factor(Model, levels = c("Single","High","Low")))

bfull <-   ggplot(fri, aes(x=Variable, y=dAUCmedian, ymin = Q025, ymax = Q975, fill=Model))+
  geom_crossbar(position="dodge")+
  scale_y_continuous(limits=c(-.05,1))+
  #geom_point(y=allRelImportance$dAUCmean)+
  geom_hline(yintercept = 0.0, color="grey50", linetype=2) +
  ylab("Relative Importance") + xlab("variable") +
  scale_x_discrete("",labels=niceNames) +
  theme_few()+
  theme(axis.text.x=element_text(angle=35, hjust=1), legend.position = c(.8,.8) ) +
  scale_fill_tableau("colorblind10")


blow <-   ggplot(lri, aes(x=Variable, y=dAUCmedian, ymin = Q025, ymax = Q975, fill=Model))+
  geom_crossbar(position="dodge")+
  scale_y_continuous(limits=c(-.05,1))+
  #geom_point(y=allRelImportance$dAUCmean)+
  geom_hline(yintercept = 0.0, color="grey50", linetype=2) +
  ylab("Relative Importance") + xlab("variable") +
  scale_x_discrete("",labels=niceNames) +
  theme_few()+
  theme(axis.text.x=element_text(angle=35, hjust=1), legend.position = c(.8,.8) ) +
  scale_fill_tableau("colorblind10")

  
bhigh <-   ggplot(hri, aes(x=Variable, y=dAUCmedian, ymin = Q025, ymax = Q975, fill=Model))+
    geom_crossbar(position="dodge")+
    scale_y_continuous(limits=c(-.05,1))+
    #geom_point(y=allRelImportance$dAUCmean)+
    geom_hline(yintercept = 0.0, color="grey50", linetype=2) +
    ylab("Relative Importance") + xlab("variable") +
    scale_x_discrete("",labels=niceNames) +
    theme_few()+
    theme(axis.text.x=element_text(angle=35, hjust=1), legend.position = c(.8,.8) ) +
    scale_fill_tableau("colorblind10")
  
  pdf("figures/VarImpQuantile/models.pdf", onefile = TRUE)
  plot(bfull)
  plot(blow)
  plot(bhigh)
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
