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
                          spRich + primProp + vectorOcc") 



## Constants ----

variables <- trimws(unlist(strsplit(as.character(glm.formula)[3], "+", fixed = T)), which = "both")
variablesName <- c("full model", variables, "all permutated")
permutations <- 100


#1. High NHP Model----
## Load data
high.training <- readRDS("../data_clean/FinalData_Mosi/TrainingDataHighNHP.rds")
high.testing <- readRDS("../data_clean/FinalData_Mosi/TestingDataHighNHP.rds")

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
saveRDS(high.model, file="../data_out/MS_results_revisions/HighModel/model.rds")
saveRDS(high.test.pred, file="../data_out/MS_results_revisions/HighModel/testingPredictions.rds")
saveRDS(high.model.prediction, file="../data_out/MS_results_revisions/HighModel/wholePredictions.rds")

## Assess variable importance through permutation test

#parse out variables from formula object 
high.perm.auc <- matrix(NA, nrow=permutations, ncol=length(variablesName)) #place to save AUC of models based on different permuation

#loop through permutations for each variable
for (j in 1:length(variablesName)){
  print(c(j,variablesName[j])) #let us know where the simulation is at. 
  
  high.perm.auc[,j] <-  PermOneVar(VarToPerm = j,formula = glm.formula, bag.fnc = baggingTryCatch, permute.fnc = permutedata, traindata = high.training, 
                                  cores = 10, no.iterations = 500, perm = permutations) 
}  


saveRDS(high.perm.auc, "../data_out/MS_results_revisions/HighModel/lPerm100Model500TryCatch.rds")

high.perm.summary <- SumPermOneVar(perm.auc = high.perm.auc, permutations = 100, title = "high NHP")
saveRDS(high.perm.summary, "../data_out/MS_results_revisions/HighModel/SummaryLPerm100Model500TryCatch.rds")

###################

#2. Low NHP Model----
## Load data
low.training <- readRDS("../data_clean/FinalData_Mosi/TrainingDataLowNHP.rds")
low.testing <- readRDS("../data_clean/FinalData_Mosi/TestingDataLowNHP.rds")

## Build the models and training predictions
low.model <-  BaggedModel(form.x.y = glm.formula, training = low.training, new.data = low.training, no.iterations = 500, bag.fnc = baggingTryCatch)

## Predict on testing data
list.of.low.models <- low.model[[1]] #pull out models from object returned by BaggedModel
low.test.pred <- baggedPredictions(list.of.low.models, low.testing) #predict on testing data

low.test.pred[[1]] #pull out test auc

#predictions for whole dataset
#add col to tell if in training vs testing 
low.model.prediction <- low.model[[2]] %>%
  bind_rows(low.test.pred[[2]]) %>%
  mutate(set=c(rep("train", dim(low.model[[2]])[1]), rep("test", dim(low.test.pred[[2]])[1])))

#save all the things
saveRDS(low.model, file="../data_out/MS_results_revisions/LowModel/model.rds")
saveRDS(low.test.pred, file="../data_out/MS_results_revisions/LowModel/testingPredictions.rds")
saveRDS(low.model.prediction, file="../data_out/MS_results_revisions/LowModel/wholePredictions.rds")


## Assess variable importance through permutation test

#parse out variables from formula object 
low.perm.auc <- matrix(NA, nrow=permutations, ncol=length(variablesName)) #place to save AUC of models based on different permuation

#loop through permutations for each variable
for (j in 1:length(variablesName)){
  print(c(j,variablesName[j])) #let us know where the simulation is at. 
  
  low.perm.auc[,j] <-  PermOneVar(VarToPerm = j,formula = glm.formula, bag.fnc = baggingTryCatch, permute.fnc = permutedata, traindata = low.training, 
                                  cores = 10, no.iterations = 500, perm = permutations) 
}  


saveRDS(low.perm.auc, "../data_out/MS_results_revisions/LowModel/lPerm100Model500TryCatch.rds")

low.perm.summary <- SumPermOneVar(perm.auc = low.perm.auc, permutations = 100, title = "Low NHP")
saveRDS(low.perm.summary, "../data_out/MS_results_revisions/LowModel/SummaryLPerm100Model500TryCatch.rds")

###################

#3. One Model----
## Load data
one.training <- readRDS("../data_clean/FinalData_Mosi/TrainingData.rds")
one.testing <- readRDS("../data_clean/FinalData_Mosi/TestingData.rds")

## Build the models and training predictions
one.model <-  BaggedModel(form.x.y = glm.formula, training = one.training, new.data = one.training, no.iterations = 500, bag.fnc = baggingTryCatch)

## Predict on testing data
list.of.one.models <- one.model[[1]]
one.test.pred <- baggedPredictions(list.of.one.models, one.testing) #predict on testing data

one.test.pred[[1]] #test auc

#predictions for whole dataset
#add col to tell if in training vs testing 
one.model.prediction <- one.model[[2]] %>%
  bind_rows(one.test.pred[[2]]) %>%
  mutate(set=c(rep("train", dim(one.model[[2]])[1]), rep("test", dim(one.test.pred[[2]])[1])))

#save all the things
saveRDS(one.model, file="../data_out/MS_results_revisions/OneModel/model.rds")
saveRDS(one.test.pred, file="../data_out/MS_results_revisions/OneModel/testingPredictions.rds")
saveRDS(one.model.prediction, file="../data_out/MS_results_revisions/OneModel/wholePredictions.rds")

## Assess variable importance through permutation test

#make objects for outputs to be saved in
national.perm.auc <- matrix(NA, nrow=permutations, ncol=length(variablesName)) #place to save AUC of models based on different permuation

#loop through permutations for each variable
for (j in 1:length(variablesName)){
  print(c(j,variablesName[j])) #let us know where the simulation is at. 
  
  national.perm.auc[,j] <-  PermOneVar(VarToPerm = j,formula = glm.formula, bag.fnc = baggingTryCatch, permute.fnc = permutedata, traindata = one.training, 
                                       cores = 10, no.iterations = 500, perm = permutations) 
}  


saveRDS(national.perm.auc, "../data_out/MS_results_revisions/OneModel/Perm100Model500TryCatch.rds")

national.perm.summary <- SumPermOneVar(perm.auc = national.perm.auc, permutations = 100, title = "National")
saveRDS(national.perm.summary, "../data_out/MS_results_revisions/OneModel/SummaryPerm100Model500TryCatch.rds")  


#4. Exploring Model testing AUC----
###################
#load data if not already in ws
 one.model.prediction <- readRDS("../data_out/MS_results_revisions/OneModel/wholePredictions.rds")
 low.model.prediction <- readRDS("../data_out/MS_results_revisions/LowModel/wholePredictions.rds")
 high.model.prediction <- readRDS("../data_out/MS_results_revisions/HighModel/wholePredictions.rds")

CalcAUC=function(x){
  train <-x %>% filter(set=="train") %>% select(c("case", "prediction"))
  train.preds <- ROCR::prediction(train$prediction, train$case)
  train.auc <- unlist(ROCR::performance(train.preds, "auc")@y.values)
  
  test <-x %>% filter(set=="test") %>% select(c("case", "prediction"))
  test.preds <- ROCR::prediction(test$prediction, test$case)
  test.auc <- unlist(ROCR::performance(test.preds, "auc")@y.values)
  
  return(c(train.auc, test.auc))
}

#calculate training and testing AUC
oneAUC <- CalcAUC(one.model.prediction)
lowAUC <- CalcAUC(low.model.prediction)
highAUC <- CalcAUC(high.model.prediction)

#save AUCs in table
sumAUC <- rbind(oneAUC,lowAUC,highAUC)
colnames(sumAUC) <- c('train','test')
write.csv(sumAUC, file="../data_out/MS_results_revisions/summaryAUC.csv")





