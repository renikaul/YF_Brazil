library(maptools)
library(shapefiles)
library(surveillance)
library(plyr)
library(dplyr)
library(ggplot2)
library(magrittr)

muni.map<-readShapePoly("municipios_2010/municipios_2010.shp")
#View(muni.map@data)
# id: 
# nome: name (of municipio)
# uf: ??
  # same number of levels as 'estado_id' so could be another version of that
# populacao: population
# pib: produto interno bruto / gross domestic product
# estado_id: state id
# condigo_ibg: condition
  # unsure what 'ibg' is, but IBGE = Instituto Brasileiro de Geografia e Estatística
    #(Brazilian Institute of Geography and Statistics)

spplot(muni.map)

