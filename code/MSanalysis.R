# All code to build for YF MS


#1. Load packages, functions and data ----

##packages
library(dplyr)
library(gplots)
library(parallel)
library(doParallel)
library(ROCR)
library(pROC)

##functions (all stored in single script)
source("")
#2. Build the models ----


## High NHP
#load data
hPermFull <- permOneVar(formula = glm.formula, bag.fnc = baggingTryCatch, traindata = hTrimTrain, cores = 10, no.iterations = 500, perm = 10, viz = TRUE, title="High NHP Full Model")

saveRDS(hPermFull, "../data_out/TwoModelSoln/Trim2014/HPermFullModelTryCatch.rds")

## Low NHP
#load data
lPermFull <- permOneVar(formula = glm.formula, bag.fnc = baggingTryCatch,traindata = lTrimTrain, cores = 10, no.iterations = 500, perm = 10, viz = TRUE, title="Low NHP Full Model")
saveRDS(lPermFull, "../data_out/TwoModelSoln/Trim2014/LPermFullModelTryCatch.rds")
