# Bagging ----
bagging<-function(form.x.y,training,new.data){
  # modified JP's bagging function 12/1/17 RK 
  # form.x.y the formula for model to use
  # training dataframe containing training data (presence and abs)
  # new.data new data for logreg model to predict onto
  
  # returns predictions based on logreg model for new data and coefficients of model
  #0. load packages
  library(dplyr)
  #1. Create subset of data with fixed number of pres and abs
  training.pres <- dplyr::filter(training, case==1) #pull out just present points
  training.abs <- dplyr::filter(training, case==0)  #pull out just absence points
  training_positions.p <- sample(nrow(training.pres),size=10) #randomly choose 10 present point rows
  training_positions.b <- sample(nrow(training.abs),size=100) #randomly choose 100 absence point rows  
  train_pos.p<-1:nrow(training.pres) %in% training_positions.p #presence 
  train_pos.b<-1:nrow(training.abs) %in% training_positions.b #background
  #2. Build logreg model with subset of data    
  glm_fit<-glm(form.x.y,data=rbind(training.pres[train_pos.p,],training.abs[train_pos.b,]),family=binomial(logit))
  #3. Pull out model coefs  
  glm.coef <- coef(glm_fit)
  #4. Use model to predict (0,1) on whole training data   
  predictions <- predict(glm_fit,newdata=new.data,type="response")
  return(list(predictions, glm.coef))
}

# Permute Variable based on loop iteration of PermOneVar ----
permutedata=function(formula = glm.formula,trainingdata, i){
  # glm.formula:
  # training : training data with pres and abs
  # cores : number of cores to use for parallel; default to 2
  # no.iterations : number of low bias models to make; default to 100
  
  #parse out variables from formula object 
  variables <- trimws(unlist(strsplit(as.character(formula)[3], "+", fixed = T)), which = "both")
  variablesName <- c("full model", variables, "all permutated")
  
  #if statments to permute data as needed ----
  if(i==1){
    #run full model
    permuted.data <- trainingdata
  }else if(i==length(variablesName)){
    #permute all variables; using loop so can I can use same sampling method (apply statement coherced data into weird format)
    # temp.data <- dplyr::select(traindata, variables) %>%
    #   dplyr::sample_frac() 
    # permuted.data <- cbind(case=traindata$case, tmp.data)
    
    #bug: treating colnames as colnumber in fun but not when ran in console. :(   
    permuted.data <- trainingdata
    for( j in 1:length(variables)){
      vari <- variables[j]
      permuted.data[,vari] <- sample(permuted.data[,vari],dim(permuted.data)[1],FALSE) #permute the col named included in vari (ie. variable.names)
    }   
  } else {
    #permute single variable
    permuted.data <- trainingdata
    permuted.data[,variablesName[i]] <- sample(permuted.data[,variablesName[i]],dim(permuted.data)[1],FALSE) #permute the col named included in vari (ie. variable.names)
  } 
  
  return(permuted.data)
}



# Models with permutated variables ----
permOneVar=function(formula = glm.formula, bag.fnc=bagging,permute.fnc=permutedata, traindata = training, cores=2, no.iterations= 100, perm=10){
  
  # glm.formula: full formula for the model to use
  # traindata : training data with pres and abs
  # cores : number of cores to use for parallel; default to 2
  # no.iterations : number of low bias models to make; default to 100
  # bag.fnc : bagging(form.x.y,training,new.data); bagging function 
  # permute.fnc : permutedata(formula = glm.formula,trainingdata, i); function to permute single variable 
  library(dplyr)
  library(doParallel)
  library(ROCR)
  
  #useful functions----
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
  #organize results from different cores
  paste_all_pred <- function(x) {
    indices <- seq(from = 1, to = length(results[[1]]), by = 2)
    return(results[[x]][indices])
  }
  
  #make some local objects----
  cores.to.use <- cores
  #parse out variables from formula object 
  variables <- trimws(unlist(strsplit(as.character(formula)[3], "+", fixed = T)), which = "both")
  variablesName <- c("full model", variables, "all permutated")
  
  #make objects for outputs to be saved in ----
  perm.auc <- matrix(NA, nrow=perm, ncol=length(variablesName)) #place to save AUC of models based on different permuation
  
  #loop through permutations for each variable ----
  for (j in 1:length(variablesName)){
    print(c(j,variablesName[j])) #let us know where the simulation is at. 
    VarToPerm <- j
    
    cl <- makeCluster(cores.to.use)
    registerDoParallel(cl)
    
    results <- foreach(i = 1:perm) %dopar% {
      permuted.data <- permute.fnc(formula = formula, trainingdata = traindata, i = VarToPerm)
      
      list_of_lists <- replicate(n = no.iterations, expr = bag.fnc(form.x.y = formula, training = permuted.data,
                                                        new.data = traindata))
    }
    stopCluster(cl)
    
    all_preds <- unlist(sapply(1:perm, paste_all_pred)) #all predictions for perm variable
    
    
    #aggregate data from clusters to calculate AUC for each bagged model from each unique perm data----
    col_length <- no.iterations*perm
    trainingPreds <- matrix(all_preds, ncol = col_length) #each col is the predictions of a single lowbias model
    
    #calculate mean prediction for model over all no.iterations for a given dataset
    for ( k in 1:perm){
      top <- 1 + ((k-1)*no.iterations)
      bottom <- no.iterations + ((k-1)*no.iterations)
      tmpPred <- trainingPreds[,c(top:bottom)]
      output.preds<- apply(tmpPred, 1, mean) 
      preds <- ROCR::prediction(output.preds, traindata$case) #other projects have used dismo::evaluate instead. Not sure if is makes a difference. 
      
      #matrix of AUC to return
      perm.auc[k,j] <- unlist(performance(preds, "auc")@y.values)
    }
      
  }
  
  #calculate relative importance ----
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
#training.data <- readRDS("../../data_clean/TrainingData.rds") #load data

#define function for model
#glm.formula <- as.formula("case~  NDVI+NDVIScale+popLog10") 

#Create 10 permuted datasets for each variable, fit model bagged 100 times, predict on full dataset, save AUC
#PermTestModel <- permOneVar(formula = glm.formula,traindata = training.data, cores=2, no.iterations = 5, perm = 3)











