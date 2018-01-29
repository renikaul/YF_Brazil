# MS Permutations
# Upper the number of permutations to decrease variation around AUC

#1. Load packages ----
library(dplyr)
library(gplots)
library(parallel)
library(doParallel)
library(ROCR)
library(pROC)

#2. Source functions ----
source("functions/baggingWperm.R")


#3. Define Model ----
glm.formula <- as.formula("case~  NDVI+NDVIScale+
                          popLog10+
                          RF+RFsqrt+RFScale+
                          tempMean+tempScale+
                          fireDenSqrt+fireDenScale+
                          spRich+primProp") 

#4.Load Training Data and Trim 2014----

# High NHP
Htraining.data <- readRDS("../data_clean/TrainingDataHighNHP.rds")
hTrimTrain <-  Htraining.data %>%  filter(year <2014)
rm(Htraining.data)

# Low NHP
Ltraining.data <- readRDS("../data_clean/TrainingDataLowNHP.rds")
lTrimTrain <-  Ltraining.data %>%  filter(year <2014)
rm(Ltraining.data)

training.data <- readRDS("../data_clean/TrainingDataSpat.rds")
trainTrim <-training.data %>% filter(year <2014)
rm(training.data)

#5. Run permuations and save ----

# High NHP
hPermFull <- permOneVar(formula = glm.formula, bag.fnc = baggingTryCatch, traindata = hTrimTrain, cores = 10, no.iterations = 500, perm = 100, viz = TRUE, title="High NHP Full Model")
saveRDS(hPermFull, "../data_out/MS_results/HighModel/HPerm100FullModel500TryCatch.rds")

# Low NHP
lPermFull <- permOneVar(formula = glm.formula, bag.fnc = baggingTryCatch,traindata = lTrimTrain, cores = 10, no.iterations = 500, perm = 100, viz = TRUE, title="Low NHP Full Model")
saveRDS(lPermFull, "../data_out/MS_results/LowModel/LPerm100FullModel500TryCatch.rds")

PermFullModel <- permOneVar(formula = glm.formula,bag.fnc = baggingTryCatch,traindata = trainTrim, cores = 10, no.iterations = 500, perm = 100, viz = TRUE, title="Full Model")
saveRDS(PermFullModel, "../data_out/MS_results/OneModel/Perm100FullModel500TryCatch.rds")


