# Notes from meeting with JP

Michelle met with JP on August 3rd 2017 to go over some of the model creation and variable selection that he did for the Ebola stuff.

JP orignally started out with a BRT model, but found that many of the partial dependence plots were "spiky" and not biologically realistic. He then used the inference regarding variable importance from the BRT to then choose variables for the lobag model. This is also why he chose to bin the population data the way he did.

In his email, his description of coarse environmental variables refers the fact that they are multi-dimensional and not simply detailing the rainfall, but EVI ad PET say more about the biome as a whole. He used this becuase he found that mammal species richness was a strong predictor, and it tended to follow EVI closely.

Regarding the 'iterations' term in the bagging function, he says to ask Drew.
