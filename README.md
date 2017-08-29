# YF_Brazil

## 8/29 Reni meeting with John
This is a good start. We should grow our list of covariates, then explore how they relate to eachother and vary over the landscape. Once we have a good feel for their behavior we can start adding them to the model. Throughout this process leave the 30% testing data alone. 

### Additional covariates
  Transforming variables for normality can be done with ln,log10 or sqrt. They are generally the same, but sqrt can handle zero values. 
  
#### Population
  Given that municipalities vary in size, we might want to use density instead. We should also look into why there are zeros in this covariate. I think this might be a hold over from "birthed" municipalitites. 
  
#### PET
  Might be getting at something slightly different than NDVI
  
#### YF reservoir 
  Should be able to pull species ranges from IUCN. The number of diff sp present in the municipality could be useful. 
  It is unlikely that there would be density data. 

  This might not be worth while if reservoirs are everywhere at similar abundances (ie. species richness). The value of including or exploring this covariate would be to avoid situations where the model predicts high likelihood of YF but transmission isn't likely due to lack of reservoir. 

#### Changes in human-wildlife interactions
  John isn't a big fan of fragstat. Perhaps an alternative way to get at human-wildlife interactions is to look at fire maps. He thinks they might even be temporal data on this. 

### Penalty for additional covariate
  Since this isn't a traditional ML method we need to incorporate a penalty for additional covariates. In this situation, we are looking for signs of the model being overfit. The general goal is to end with a model that can handle pertibations in cases (rows) and covariates (cols) with little change in the AUC when compared to the AUC on the testing data. There are two ways that this can be explored:
  
  1. Use 10-fold CV to get at model stability. An increase in AUC variance would indicate the model is overfit. 
  2. Look at variability of model predictions at a single site. They should be relately consistent if the model isn't overfit.   
  
***  

## Notes on Column Names

In order to have some standardization across data and files, here are the column names we are using:

  - **muni.no**: the municipality number (like FIPS), six digits (num)
  - **muni.name**: the municipality name (chr)
  - **year**: the year (num)
  - **cal.month**: the month, 1 - 12 (num)
  - **month.no**: the month, out of the whole data set, 1-168 (num)
