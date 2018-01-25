# Single Bagged Model ----
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
  #glm.coef <- coef(glm_fit)
  #4. Use model to predict (0,1) on whole training data   
  predictions <- predict(glm_fit,newdata=new.data,type="response")
  return(predictions)
}

# Bagging with predictions 
BaggedModel = function(form.x.y, training, new.data, no.iterations= 100, bag.fnc=baggingTryCatch){
  #make a matrix of predictions 
  list.of.models <- replicate(n = no.iterations, expr = bag.fnc(form.x.y, training, new.data, keep.model=TRUE), simplify = FALSE)
  #calculate mean prediction 
  matrix.of.predictions <- matrix(NA, ncol=no.iterations, nrow = dim(new.data)[1])
  for (i in 1:no.iterations){
    print(i)
    tmp <- list.of.models[[i]]
    matrix.of.predictions[,i] <- predict(tmp, newdata=new.data, type="response")
  }
  output.preds<- apply(matrix.of.predictions, 1, mean) 
  #add identifiers to predictions
  preds <- as.data.frame(cbind(muni.no=new.data$muni.no, month.no=new.data$month.no,case=new.data$case,prediction=output.preds))
  return(list(list.of.models,preds))
  }

# Making predictions from a bagged models (Bagged Model[[2]] output) ----
baggedPredictions = function(list.of.models, new.data){
  library(ROCR)
  
  matrix.of.predictions <- matrix(NA, ncol=length(list.of.models), nrow = dim(new.data)[1])
  
    for(i in 1:length(list.of.models)){
    tmp <- list.of.models[[i]]
    matrix.of.predictions[,i] <- predict(tmp, newdata=new.data, type="response")
    }
  #calculate mean value for each row
  output.preds<- apply(matrix.of.predictions, 1, mean) 
  #calculate model AUC
  preds <- ROCR::prediction(output.preds, new.data$case) #other projects have used dismo::evaluate instead. Not sure if is makes a difference. 
  #AUC to return
  auc <- unlist(ROCR::performance(preds, "auc")@y.values)
  
  #add identifiers to predictions
  preds <- as.data.frame(cbind(muni.no=new.data$muni.no, month.no=new.data$month.no,case=new.data$case,prediction=output.preds))
  return(list(auc,preds))
}


# Single Bagged Model with tryCatch----
baggingTryCatch<-function(form.x.y,training,new.data, keep.model=FALSE){
  # modified JP's bagging function 12/1/17 RK 
  # form.x.y the formula for model to use
  # training dataframe containing training data (presence and abs)
  # new.data new data for logreg model to predict onto
  
  perfectSeparation <- function(w) {
    if(grepl("fitted probabilities numerically 0 or 1 occurred", #text to match
             as.character(w))) {} #output warning message, counter NA
  }
  # returns predictions based on logreg model for new data and coefficients of model
  #0. load packages
  library(dplyr)
  #1. Create subset of data with fixed number of pres and abs
  training.pres <- dplyr::filter(training, case==1) #pull out just present points
  training.abs <- dplyr::filter(training, case==0)  #pull out just absence points
  attempt <- 0 #attempt counter
  repeat {
    attempt <- attempt +1 #count attempt
    training_positions.p <- sample(nrow(training.pres),size=10) #randomly choose 10 present point rows
    training_positions.b <- sample(nrow(training.abs),size=100) #randomly choose 100 absence point rows  
    train_pos.p<-1:nrow(training.pres) %in% training_positions.p #presence 
    train_pos.b<-1:nrow(training.abs) %in% training_positions.b #background
    #2. Build logreg model with subset of data    
    glm_fit<-tryCatch(glm(form.x.y,data=rbind(training.pres[train_pos.p,],training.abs[train_pos.b,]),family=binomial(logit)), warning=perfectSeparation) # if this returns a warning the predictions errors out b/c glm_fit is NULL 
    #2b. test to if perfect sep   
    if(is.list(glm_fit)==TRUE){
      break
    }
    #escape for stupid amounts of attempts
    if(attempt > 100){
      break
    }
  }
  #4. Use model to predict (0,1) on whole training data 
  if(is.list(glm_fit)==TRUE){
        if(keep.model==TRUE){   #3. Return model too is keep.model is TRUE  
          return(glm_fit)  
        } else {
          predictions <- predict(glm_fit,newdata=new.data,type="response")
          return(predictions)
        }
    }  
  #If model fails after 100 attempts return just NAs  
  if(attempt>100){
    predictions <- rep(NA, dim(new.data)[1])
    return(predictions)
    }
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
permOneVar=function(formula = glm.formula, bag.fnc=bagging,permute.fnc=permutedata, traindata = training, cores=2, no.iterations= 100, perm=10, 
                    viz=TRUE, title= "NA"){
  #cores should be =< perm
  
  # glm.formula: full formula for the model to use
  # traindata : training data with pres and abs
  # cores : number of cores to use for parallel; default to 2
  # no.iterations : number of low bias models to make; default to 100
  # bag.fnc : bagging(form.x.y,training,new.data); bagging function 
  # permute.fnc : permutedata(formula = glm.formula,trainingdata, i); function to permute single variable 
  library(dplyr)
  library(doParallel)
  library(ROCR)
  

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
      #permute data
      permuted.data <- permute.fnc(formula = formula, trainingdata = traindata, i = VarToPerm)
      #create model and prediction no.iterations times
      matrix_of_predictions <- replicate(n = no.iterations, expr = bag.fnc(form.x.y = formula, training = permuted.data, new.data = traindata))
      #calculate mean prediction 
      output.preds<- apply(matrix_of_predictions, 1, mean) 
      #rm(matrix_of_predictions) doesn't really free up any memory until cluster is stopped. 
      preds <- ROCR::prediction(output.preds, traindata$case) #other projects have used dismo::evaluate instead. Not sure if is makes a difference. 
      #AUC to return
      perm.auc <- unlist(ROCR::performance(preds, "auc")@y.values)
      }
    
    stopCluster(cl)
    #matrix of AUC to return
      perm.auc[,j] <- unlist(results)
    }
  
  #count number of permutations used to make stats
  no.failed <- apply(perm.auc, 2, function(x) sum(is.na(x)))
  no.suc.perm <- perm - no.failed  
  
  #calculate relative importance ----
  perm.auc.mean <- apply(perm.auc,2,function(x) mean(x,na.rm=TRUE))
  perm.auc.sd <- apply(perm.auc, 2, function(x) sd(x,na.rm=TRUE))
  delta.auc <- perm.auc.mean[1] - perm.auc.mean[-c(1, length(perm.auc.mean))] #change in AUC from base model only for single variable permutation
  rel.import <- delta.auc/max(delta.auc, na.rm = TRUE) # normalized relative change in AUC from base model only for single variable permutation
  
  #Output for relative importance
  relative.import <- as.data.frame(cbind(Variable=variables,varImp=rel.import))
  #plot it for fun
  if(viz==TRUE){barplot(rel.import, names.arg = variables, main= title)}
  #Output for mean and sd of permutations for all permutations (non, single var, and all var)
  mean.auc <- as.data.frame(cbind(Model=variablesName,meanAUC=perm.auc.mean, sdAUC=perm.auc.sd, perms=no.suc.perm))
  
  #Output of AUC for each permutation
  colnames(perm.auc) <- variablesName

  #return training coefs and AUC for each iteration
  #return(list(train.auc, Coefs))
  return(list(relative.import, mean.auc,perm.auc))
}



# Min working script ---- 
#training.data <- readRDS("../../data_clean/TrainingData.rds") #load data

#define function for model
#glm.formula <- as.formula("case~  NDVI+NDVIScale+popLog10") 

#Create 10 permuted datasets for each variable, fit model bagged 100 times, predict on full dataset, save AUC
#PermTestModel <- permOneVar(formula = glm.formula,traindata = training.data, cores=2, no.iterations = 5, perm = 3)
