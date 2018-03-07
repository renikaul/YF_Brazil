Model predictions and permutations from different data sets are organized into separate folders. Models are the output of functions in the code/function/baggingWperm.R file
However, the output of PermOneVar changed with time so the objects between the different directories may differ. 

Models produced as part of variable exploration work, and outlined in chronological order:

1. TempSplit: Predictions using permuation of data for the training dataset that was temporally split. This is the earlest version of the work.
  - FullModel: all variables; scaled and unscaled
  - PoplessModel: all variables but population density
  - SFModel: Single flavor model, the highest ranking type for each variable (either scaled or unscaled)   
  - SFPModel: Single flavor model without population, the highest ranking type for each variable (either scaled or unscaled)
2. SpaceAndTimeSplit: Predictions using training data with a balance split of time and space
    - Naming Perm[X][Variables]Model[bags] 
    - default number of permutations is 10
    - [Variables]
      - Full: all variables
      - Popless: less population
      - SF: single favor model
    - The process was also repeated without the 2014 data (ie. complete cases only since landcover is missing for 2014)
3. Predictions: Hot mess trying to figure out complete cases, approach for regional model and tryCatch. 
4. MS_results: Broken down into subdirectories for each model. High, and Low ref to the data set split based on high and low NHP reservoir richness. One is the whole data set. 
    - Within each subdir
      - Perm100Model500TryCatch.rds: Variable importance using 100 permutation of models bagged 500 times. The bagging function used TryCatch to kickout models that returned an error in the logistic function (perferct separation). 
      - testingPredictions.rds: prediction using un-altered dataset with a model bagged 500 times. The model is saved in the local repo on the HMM in the pillow bunker. 
      - wholePredictions.rds: predictions of whole data set using model built on training data 
      
      
