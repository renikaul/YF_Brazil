## Mosquito Data Processing
## MV Evans May 29 2018

# wd must be set to project directory

library(raster)
library(sp)
library(rgdal)
library(dplyr)


ha.janthin <- raster("data_raw/environmental/mosiData/MaxEntModels/ha_janthin.tif")
ha.leuco <- raster("data_raw/environmental/mosiData/MaxEntModels/ha_leuco.tif")
sa.chloro <- raster("data_raw/environmental/mosiData/MaxEntModels/sa_chloro.tif")
ae.aegypti <- raster("data_raw/environmental/mosiData/MaxEntModels/ae_aegypti.tif")
s.america <- readOGR("data_clean/shapefiles", "South_America")

plot(ha.leuco)
plot(sa.chloro)

three.mosi <- sum(ha.janthin, ha.leuco, sa.chloro, na.rm = T)

png("mosiMap.png", width =1800, height = 1200)

par(mfrow = c(2,3))

plot(ha.janthin)
plot(s.america, add = T)
mtext("Ha. janthin")

plot(ha.leuco)
plot(s.america, add = T)
mtext("Ha. leuco")

plot(sa.chloro)
plot(s.america, add = T)
mtext("Sa. chloro")

plot(three.mosi)
plot(s.america, add = T)
mtext("all three species")

plot(ae.aegypti, col = "blue")
plot(s.america, add = T)
mtext("ae aegypti")

dev.off()
