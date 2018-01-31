# All code to build for YF MS


#Load packages and functions ----

##packages----
library(dplyr)
library(gplots)
library(parallel)
library(doParallel)
library(ROCR)
library(pROC)

##functions (all stored in single script) ----
source("functions/baggingWperm.R")

##Model function
#Model
glm.formula <- as.formula("case~  popLog10+
                          NDVI+NDVIScale+
                          RFsqrt+RFScale+
                          tempMean+tempScale+
                          fireDenSqrt+fireDenScale+
                          spRich+primProp") 

#1. High NHP Model----
## Load data----
high.training <- readRDS("../data_clean/TrainingDataHighNHP2.rds")
high.testing <- readRDS("../data_clean/TestingDataHighNHP2.rds")

## Build the models and training predictions ----
high.model <-  BaggedModel(form.x.y = glm.formula, training = high.training, new.data = high.training, no.iterations = 500, bag.fnc = baggingTryCatch)

## Predict on testing data ----
list.of.high.models <- high.model[[1]] #pull out models from object returned by BaggedModel
high.test.pred <- baggedPredictions(list.of.high.models, high.testing) #predict on testing data

high.test.pred[[1]] #pull out test auc

#predictions for whole dataset
#add col to tell if in training vs testing 
high.model.prediction <- high.model[[2]] %>%
  bind_rows(high.test.pred[[2]]) %>%
  mutate(set=c(rep("train", dim(high.model[[2]])[1]), rep("test", dim(high.test.pred[[2]])[1])))

#save all the things
saveRDS(high.model, file="../data_out/MS_results/HighModel/model.rds")
saveRDS(high.test.pred, file="../data_out/MS_results/HighModel/testingPredictions.rds")
saveRDS(high.model.prediction, file="../data_out/MS_results/HighModel/wholePredictions.rds")


## Assess variable importance through permutation test ----

hPermFull <- permOneVar(formula = glm.formula, bag.fnc = baggingTryCatch, traindata = high.training, cores = 10, no.iterations = 500, perm = 100, viz = TRUE, title="High NHP Full Model")

saveRDS(hPermFull, "../data_out/MS_results/HighModel/HPerm100Model500TryCatch.rds")

###################

#2. Low NHP Model----
## Load data----
low.training <- readRDS("../data_clean/TrainingDataLowNHP2.rds")
low.testing <- readRDS("../data_clean/TestingDataLowNHP2.rds")

## Build the models and training predictions ----
low.model <-  BaggedModel(form.x.y = glm.formula, training = low.training, new.data = low.training, no.iterations = 500, bag.fnc = baggingTryCatch)

## Predict on testing data ----
list.of.low.models <- low.model[[1]] #pull out models from object returned by BaggedModel
low.test.pred <- baggedPredictions(list.of.low.models, low.testing) #predict on testing data

low.test.pred[[1]] #pull out test auc

#predictions for whole dataset
#add col to tell if in training vs testing 
low.model.prediction <- low.model[[2]] %>%
  bind_rows(low.test.pred[[2]]) %>%
  mutate(set=c(rep("train", dim(low.model[[2]])[1]), rep("test", dim(low.test.pred[[2]])[1])))

#save all the things
saveRDS(low.model, file="../data_out/MS_results/LowModel/model.rds")
saveRDS(low.test.pred, file="../data_out/MS_results/LowModel/testingPredictions.rds")
saveRDS(low.model.prediction, file="../data_out/MS_results/LowModel/wholePredictions.rds")


## Assess variable importance through permutation test ----

lPermFull <- permOneVar(formula = glm.formula, bag.fnc = baggingTryCatch, traindata = low.training, cores = 10, no.iterations = 500, perm = 100, viz = TRUE, title="Low NHP Full Model")

saveRDS(hPermFull, "../data_out/MS_results/LowModel/lPerm100Model500TryCatch.rds")

###################

#3. One Model----
## Load data----
one.training <- readRDS("../data_clean/TrainingDataSpat2.rds")
one.testing <- readRDS("../data_clean/TestingDataSpat2.rds")

## Build the models and training predictions ----
one.model <-  BaggedModel(form.x.y = glm.formula, training = one.training, new.data = one.training, no.iterations = 500, bag.fnc = baggingTryCatch)

## Predict on testing data ----
list.of.one.models <- one.model[[1]]
one.test.pred <- baggedPredictions(list.of.one.models, one.testing) #predict on testing data

one.test.pred[[1]] #test auc

#predictions for whole dataset
#add col to tell if in training vs testing 
one.model.prediction <- one.model[[2]] %>%
  bind_rows(one.test.pred[[2]]) %>%
  mutate(set=c(rep("train", dim(one.model[[2]])[1]), rep("test", dim(one.test.pred[[2]])[1])))

#save all the things
saveRDS(one.model, file="../data_out/MS_results/OneModel/model.rds")
saveRDS(one.test.pred, file="../data_out/MS_results/OneModel/testingPredictions.rds")
saveRDS(one.model.prediction, file="../data_out/MS_results/OneModel/wholePredictions.rds")

## Assess variable importance through permutation test ----

PermFullModel <- permOneVar(formula = glm.formula,bag.fnc = baggingTryCatch,traindata = one.training, cores = 10, no.iterations = 500, perm = 100, viz = TRUE, title="Full Model")
saveRDS(PermFullModel, "../data_out/MS_results/OneModel/Perm100FullModel500TryCatch.rds")

