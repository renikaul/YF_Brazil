# All code to build for YF MS

#Load packages and functions ----

##packages----
library(dplyr)
library(gplots)
library(parallel)
library(doParallel)
library(foreach)
library(ROCR)
library(pROC)

##functions (all stored in single script) ----
source("functions/baggingWperm.R")

## Model function ----
# Models

glm.formula <- as.formula("case~  popLog10 +
                               ndvi + ndviScale +
                               rf + rfScale +
                               temp + tempScale +
                               fire + fireScale +
                               spRich + primProp + vectorOcc + year") 


## Constants ----

variables <- trimws(unlist(strsplit(as.character(glm.formula)[3], "+", fixed = T)), which = "both")
variablesName <- c("full model", variables, "all permutated")
permutations <- 100


#1. High NHP Model----
## Load data
high.training <- readRDS("../data_clean/FinalData_Mosi/TrainingDataHighNHP.rds")
high.testing <- readRDS("../data_clean/FinalData_Mosi/TestingDataHighNHP.rds")

## Convert year to factor

high.training$year <- as.factor(high.training$year)
high.testing$year <- as.factor(high.testing$year)

## Build the models and training predictions
high.model <-  BaggedModel(form.x.y = glm.formula, training = high.training, new.data = high.training, no.iterations = 500, bag.fnc = baggingTryCatch)

## Predict on testing data
list.of.high.models <- high.model[[1]] #pull out models from object returned by BaggedModel
high.test.pred <- baggedPredictions(list.of.high.models, high.testing) #predict on testing data

high.test.pred[[1]] #pull out test auc

#predictions for whole dataset
#add col to tell if in training vs testing 
high.model.prediction <- high.model[[2]] %>%
  bind_rows(high.test.pred[[2]]) %>%
  mutate(set=c(rep("train", dim(high.model[[2]])[1]), rep("test", dim(high.test.pred[[2]])[1])))

#save all the things
saveRDS(high.model, file="../data_out/MS_results_revisions/Supplement_Year/HighModel/model.rds")
saveRDS(high.test.pred, file="../data_out/MS_results_revisions/Supplement_Year/HighModel/testingPredictions.rds")
saveRDS(high.model.prediction, file="../data_out/MS_results_revisions/Supplement_Year/HighModel/wholePredictions.rds")

## Assess variable importance through permutation test

#parse out variables from formula object 
high.perm.auc <- matrix(NA, nrow=permutations, ncol=length(variablesName)) #place to save AUC of models based on different permuation

#loop through permutations for each variable
for (j in 1:length(variablesName)){
  print(c(j,variablesName[j])) #let us know where the simulation is at. 
  
  high.perm.auc[,j] <-  PermOneVar(VarToPerm = j,formula = glm.formula, bag.fnc = baggingTryCatch, permute.fnc = permutedata, traindata = high.training, 
                                   cores = 10, no.iterations = 500, perm = permutations) 
}  


saveRDS(high.perm.auc, "../data_out/MS_results_revisions/Supplement_Year/HighModel/lPerm100Model500TryCatch.rds")

high.perm.summary <- SumPermOneVar(perm.auc = high.perm.auc, permutations = 100, title = "high NHP")
saveRDS(high.perm.summary, "../data_out/MS_results_revisions/Supplement_Year/HighModel/SummaryLPerm100Model500TryCatch.rds")

