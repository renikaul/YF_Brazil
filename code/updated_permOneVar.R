# Main function ----
permOneVar=function(formula = glm.formula, bag.fnc=bagging,permute.fnc=permutedata, traindata = training, cores=2, no.iterations= 100, perm=10){
  
  # glm.formula:
  # training : training data with pres and abs
  # cores : number of cores to use for parallel; default to 2
  # no.iterations : number of low bias models to make; default to 100
  library(dplyr)
  library(doParallel)
  
  #create class to combine multiple results
  multiResultClass <- function(predictions = NULL,coefs = NULL)
  {
    me <- list(
      predictions = predictions,
      coefs = coefs
    )
    
    ## Set the name for the class
    class(me) <- append(class(me),"multiResultClass")
    return(me)
  }
  
  #parse out variables from formula object 
  variables <- trimws(unlist(strsplit(as.character(formula)[3], "+", fixed = T)), which = "both")
  variablesName <- c("full model", variables, "all permutated")
  
  #make objects for outputs to be saved in
  perm.auc <- matrix(NA, nrow=perm, ncol=length(variablesName)) #place to save AUC of models based on different permuation
  
  for (j in 1:length(variablesName)){
    print(c(j,variablesName[j])) #let us know where the simulation is at. 
    VarToPerm <- j
    
    cores.to.use <- cores
    
    cl <- makeCluster(cores.to.use)
    registerDoParallel(cl)
    
    results <- foreach(i = 1:perm) %dopar% {
      permuted.data <- permute.fnc(formula = formula, trainingdata = traindata, i = VarToPerm)
      
      list_of_lists <- replicate(n = no.iterations, expr = bag.fnc(form.x.y = formula, training = permuted.data,
                                                        new.data = traindata))
    }
    stopCluster(cl)
    
    paste_all_pred <- function(x) {
      indices <- seq(from = 1, to = length(results[[1]]), by = 2)
      return(results[[x]][indices])
    }
    
    all_preds <- unlist(sapply(1:perm, paste_all_pred))
    
    
    #aggregate data from clusters ----
    #pull out data in usable fashion
    
    # Set number of columns to the number of iterations times the number of permutations.
    col_length <- no.iterations*perm
    trainingPreds <- matrix(all_preds, ncol = col_length)
    #trainingCoefs <- do.call(cbind,(lapply(trainModel, '[[', 2)))
    
    output.preds<- apply(trainingPreds, 1, mean)
    preds <- prediction(output.preds, traindata$case) #other projects have used dismo::evaluate instead. Not sure if is makes a difference. 
    
    #matrix of AUC to return
    perm.auc[k,j] <- unlist(performance(preds, "auc")@y.values)
      
  }
  #calculate relative importance
  perm.auc.mean <- apply(perm.auc,2,mean)
  perm.auc.sd <- apply(perm.auc, 2, sd)
  delta.auc <- perm.auc.mean[1] - perm.auc.mean[-c(1, length(perm.auc.mean))] #change in AUC from base model only for single variable permutation
  rel.import <- delta.auc/max(delta.auc) # normalized relative change in AUC from base model only for single variable permutation
  
  #Output for relative importance
  relative.import <- as.data.frame(cbind(Permutated=variables,RelImport=rel.import))
  #plot it for fun
  barplot(rel.import, names.arg = variables)
  #Output for mean and sd of permutations for all permutations (non, single var, and all var)
  mean.auc <- as.data.frame(cbind(Model=variablesName,meanAUC=perm.auc.mean, sdAUC=perm.auc.sd))
  
  #Output of AUC for each permutation
  colnames(perm.auc) <- variablesName
  
  #return training coefs and AUC for each iteration
  #return(list(train.auc, Coefs))
  return(list(rel.import, mean.auc,perm.auc))
}

# Min working script ---- 
training.data <- readRDS("TrainingData.rds") #load data

#define function for model
glm.formula <- as.formula("case~  NDVI+NDVIScale+ 
                          popLog10+
                          RFsqrt+RFScale+
                          tempMean+tempScale+
                          fireDenSqrt+fireDenScale+
                          spRich+primProp") 

#Create 10 permuted datasets for each variable, fit model bagged 100 times, predict on full dataset, save AUC
PermFullModel <- permOneVar(formula = glm.formula,traindata = training.data, cores=2, no.iterations = 100, perm = 10)











