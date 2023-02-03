#Download manually and in OSgeo4w
#ogr2ogr -f PostgreSQL PG:"host=localhost dbname=censos user=postgres password=adminpass port=5432 schemas=censos ACTIVE_SCHEMA=censos" -lco SCHEMA=censos nypd-arrest-historic.geojson -lco GEOMETRY_NAME=geometry

#Working with the data --------------------------------------------------------
library(RPostgreSQL)
library(DBI)
library(sf)
library(rpostgis)
library(tidyverse)

fun_connect<-function(){dbConnect(RPostgres::Postgres(),
                                  dbname='censos',
                                  host='localhost',
                                  port=5432,
                                  user='postgres',
                                  password='adminpass',
                                  options= '-c search_path=censos'
)}

conn<-fun_connect()



# Reading from PostGIS ----------------------------------------------------

#Arrest
 st_read(conn, "nypd_arrest_historic") %>% 
  filter(!st_is_empty(.)) %>%
  st_set_crs(.,4326) 

arrests<- tbl(conn, "nypd_arrest_historic")
colnames(arrests_his) 
col_detail <- lapply(as.data.frame(test)[,c(2,4,6,9,10,11,13:18)], unique)

#Shootings
shootings <- st_read(conn, "nypd_shooting_historic") %>% 
  filter(!st_is_empty(.)) %>%
  st_set_crs(.,4326) 




ggplot(shootings[!is.na(shootings$perp_race),], aes(color=perp_race))+
  geom_sf()

#Loading borough at PostGIS
st_write(st_read("https://data.cityofnewyork.us/resource/7t3b-ywvw.geojson"),dsn = conn, 'borough_nyc')


#Querying intersects as table
test <- dbSendQuery(conn,"SELECT ST_Intersects(nypd_shooting_historic.geometry, borough_nyc.geometry)
            FROM nypd_shooting_historic, borough_nyc;")

test <- dbFetch(test)

#OR

#Querying intersects as shapefile
test <- st_read(conn,query="SELECT ST_Intersects(nypd_shooting_historic.geometry, borough_nyc.geometry)
                FROM nypd_shooting_historic, borough_nyc;")

# It returns tables without geometries 
test<- st_read(conn,query="SELECT boro_name, perp_sex, vic_sex, occur_date, occur_time, perp_age_group, 
                           vic_age_group FROM borough_nyc, nypd_shooting_historic
                    WHERE ST_Intersects(nypd_shooting_historic.geometry, borough_nyc.geometry)")





# Observation Window ------------------------------------------------------

w1 <- st_bbox(shootings)|>st_as_sfc() #Create a Polygon based in the bbox

w2 <- st_point(c(st_bbox(shootings)[3], ((st_bbox(shootings)[2]+st_bbox(shootings)[4]))/2))|>st_buffer(st_bbox(shootings)[3]-st_bbox(shootings)[1])

#Windows 1
plot(w1)
plot(shootings,add=T)

#Windows 2
plot(w2)
plot(shootings,add=T)

#Windows arrest from PostGIS 
plot(w1)
plot(st_read(dsn=conn,layer="nypd_arrest_historic")
     ,add=T) #It works but is hyper memory consumer
gc()

plot(w2)
plot(read_sf(dsn=conn,layer="nypd_arrest_historic")# In this case works better to do closer windows
     ,add=T) #It works but is hyper memory consumer



# Trying others methods to open PostGIS data ------------------------------

install.packages("rgdal")

test <- st_read(dsn=conn,layer="nypd_shooting_historic")
class(test)

test <- rgdal::readOGR(dsn=conn,layer="nypd_arrest_historic")

test <-dbReadTable(conn, "nypd_arrest_historic")#Suuuuuuper light process, maybe with Lat and Long attribute is possible do some easier

class(test)
library(pryr)
mem_used()# Damn it said the true



# Trying to plot with ggplot ----------------------------------------------

ggplot(data=test, aes(x=longitude, y=latitude))+
  geom_point() #Take long long to load, the best is QGIS I think 

#Anyways is not worth to explore point patterns with all data in the map a lot of overlapping
#slowness

rm(test)

#R-Spatial book give us the approach to use point-patterns in windows 
#Also apply a function that it works to count the points in the different regular windos

#What about to replicate this method with another administratives scales 
