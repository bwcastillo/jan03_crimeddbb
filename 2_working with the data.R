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
shootings <- st_read(conn, "nypd_shoting_historic") %>% 
  filter(!st_is_empty(.)) %>%
  st_set_crs(.,4326) 


#Apparently, conceptually and according the available data, would be easier analyze shooting
#It would possible to analyze arrest but require more time maybe to apply manually the formulas
#or to find ways to do easier the process


#See the administratives and statistical scales load data

#Roger bivand book
#-Observation window - density
#-Marked point patterns, points on linear networks


#Antonio Paez book

ggplot(shootings[!is.na(shootings$perp_race),], aes(color=perp_race))+
  geom_sf()

#Loading borough
st_write(st_read("https://data.cityofnewyork.us/resource/7t3b-ywvw.geojson"),dsn = conn, 'borough_nyc')

unique(shootings$perp_age_group)

dbSendQuery(conn,"SELECT ST_Intersects(borough, shooting) as freq_shoot
            FROM (SELECT censos.borough_nyc.geometry as borough, censos.nypd_shooting_historic as shooting) as tiroteo")

