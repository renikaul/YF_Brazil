# Script to run models for 2 modle YF in Brazil
# Writen 1/4/18 R Kaul

#load packages
library(dplyr)
library(gplots)
library(parallel)
library(doParallel)
library(ROCR)
library(pROC)
#source functions
source("functions/baggingWperm.R")


# Full Model----


glm.formula <- as.formula("case~  NDVI+NDVIScale+
                          popLog10+
                          RF+RFsqrt+RFScale+
                          tempMean+tempScale+
                          fireNum+fireDen+fireDenSqrt+fireDenScale+
                          spRich+primProp") 

## High NHP
#load data
Htraining.data <- readRDS("../data_clean/TrainingDataHighNHP.rds")

HPermFullModel <- permOneVar(formula = glm.formula,traindata = Htraining.data, cores = 10, no.iterations = 500, perm = 10, viz = FALSE)

saveRDS(HPermFullModel, "../data_out/TwoModelSoln/HPermFullModel.rds")

rm(Htraining.data, HPermFullModel)

## Low NHP
#load data
Ltraining.data <- readRDS("../data_clean/TrainingDataLowNHP.rds")

LPermFullModel <- permOneVar(formula = glm.formula,traindata = Ltraining.data, cores = 10, no.iterations = 500, perm = 10, viz = FALSE)

saveRDS(LPermFullModel, "../data_out/TwoModelSoln/LPermFullModel.rds")