
# Getting & Opening the data ----------------------------------------------


# Toronto datasets --------------------------------------------------------
library(opendatatoronto)

#https://open.toronto.ca/dataset/theft-from-motor-vehicle/
#https://open.toronto.ca/dataset/shootings-firearm-discharges/
#https://open.toronto.ca/dataset/police-annual-statistical-report-homicide/
#https://open.toronto.ca/dataset/bicycle-thefts/
#https://open.toronto.ca/dataset/neighbourhood-crime-rates/
#https://open.toronto.ca/dataset/police-annual-statistical-report-traffic-collisions/
#install.packages("opendatatoronto")
library(opendatatoronto)
library(dplyr)

# get package
package <- show_package("c7d34d9b-23d2-44fe-8b3b-cd82c8b38978")
package

# get all resources for this package
resources <- list_package_resources("c7d34d9b-23d2-44fe-8b3b-cd82c8b38978")

# identify datastore resources; by default, Toronto Open Data sets datastore resource format to CSV for non-geospatial and GeoJSON for geospatial resources
datastore_resources <- filter(resources, tolower(format) %in% c('geojson'))

# load the first datastore resource as a sample
data <- filter(datastore_resources, row_number()==1) %>% get_resource()
data


# New york:  --------------------------------------------------------------

#https://data.cityofnewyork.us/resource/8h9b-rp9u.geojson

#https://data.cityofnewyork.us/browse?Dataset-Information_Agency=Police+Department+%28NYPD%29&limitTo=datasets
#https://data.cityofnewyork.us/Public-Safety/Motor-Vehicle-Collisions-Crashes/h9gi-nx95
#https://data.cityofnewyork.us/Public-Safety/NYPD-Complaint-Data-Historic/qgea-i56i
#https://data.cityofnewyork.us/Public-Safety/NYPD-Complaint-Data-Current-Year-To-Date-/5uac-w243
#https://data.cityofnewyork.us/Public-Safety/NYPD-Arrest-Data-Year-to-Date-/uip8-fykc
#https://data.cityofnewyork.us/Public-Safety/NYPD-Arrests-Data-Historic-/8h9b-rp9u
#https://data.cityofnewyork.us/Public-Safety/NYPD-Shooting-Incident-Data-Historic-/833y-fsy8
#https://data.cityofnewyork.us/Public-Safety/NYPD-Shooting-Incident-Data-Year-To-Date-/5ucz-vwe8
#https://data.cityofnewyork.us/Public-Safety/NYPD-Personnel-Demographics/5vr7-5fki NO SPATIAL
#https://data.cityofnewyork.us/Public-Safety/NYPD-B-Summons-Historic-/bme5-7ty4
#https://data.cityofnewyork.us/Public-Safety/NYPD-B-Summons-Year-to-Date-/57p3-pdcj
#https://data.cityofnewyork.us/Public-Safety/NYPD-Criminal-Court-Summons-Incident-Level-Data-Ye/mv4k-y93f
#https://data.cityofnewyork.us/Public-Safety/NYPD-Criminal-Court-Summons-Historic-/sv2w-rv3k

#Examples how to get directly in geojson
shooting_ny <- geojsonio::geojson_sf("https://data.cityofnewyork.us/resource/833y-fsy8.geojson?%24limit=5000&%24%24app_token=59LeXuU7FNOMnnOJxik8Cs47y")
arrests_ny <- geojsonio::geojson_sf("https://data.cityofnewyork.us/resource/8h9b-rp9u.geojson?%24limit=10000&%24%24app_token=59LeXuU7FNOMnnOJxik8Cs47y")

#Saving automatically

getOption('timeout')#See value variable time out
options(timeout=360)#Change variable timeout 

#CSV
download.file("https://data.cityofnewyork.us/resource/8h9b-rp9u.csv?%24limit=5308876&%24%24app_token=59LeXuU7FNOMnnOJxik8Cs47y", "output/nypd-arrest-historic.csv")

#Geojson
download.file("https://data.cityofnewyork.us/resource/8h9b-rp9u.geojson?%24limit=5308876&%24%24app_token=59LeXuU7FNOMnnOJxik8Cs47y", "output/nypd-arrest-historic.geojson")

#Other way to Read from the url and write as csv 
write.csv(read.csv("https://data.cityofnewyork.us/resource/8h9b-rp9u.csv?%24limit=5308876&%24%24app_token=59LeXuU7FNOMnnOJxik8Cs47y"), "output/nypd-arrest-historic.csv")

# Load the data to Postgresql and PosGIS ----------------------------------
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

# Seeing drivers ----------------------------------------------------------

st_drivers() %>% 
  filter(grepl("Post", name))

"PostgreSQL" %in% st_drivers()$name

#dbDisconnect(conn)

# Changing postgis schema -------------------------------------------------

dbSendQuery(conn, "UPDATE pg_extension
            SET extrelocatable = true
            WHERE extname = 'postgis';")
            
dbSendQuery(conn,"ALTER EXTENSION postgis
            SET SCHEMA censos;")
            
dbSendQuery(conn,"ALTER EXTENSION postgis
            UPDATE TO \"3.1.0\";")
            
dbSendQuery(conn,"ALTER EXTENSION postgis
            UPDATE TO \"3.1.0\";")

# First try ---------------------------------------------------------------

#CSV: It works
sf::st_write(read.csv("https://data.cityofnewyork.us/resource/8h9b-rp9u.csv?%24limit=5000&%24%24app_token=59LeXuU7FNOMnnOJxik8Cs47y"),
             dsn= conn, layer="ny_shotingt_historic",delete_layer=T,append=F)

#SF: To works, it was necessary to verify that postgis extension was associated to our schema 
sf::st_write(geojsonio::geojson_sf("https://data.cityofnewyork.us/resource/833y-fsy8.geojson?%24limit=5308876&%24%24app_token=59LeXuU7FNOMnnOJxik8Cs47y"),
             dsn= conn,
             layer="ny_shoting_historic",delete_layer=T,append=F,
             driver="PostgreSQL/PostGIS")


sf::st_write(st_read("https://data.cityofnewyork.us/resource/8h9b-rp9u.geojson?%24limit=2000000&%24%24app_token=59LeXuU7FNOMnnOJxik8Cs47y"),"output/nyp_arrest_hist.gpkg")
#It doesnt work sf::st_write(st_read("https://data.cityofnewyork.us/resource/8h9b-rp9u.geojson?%24limit=5308876&%24%24app_token=59LeXuU7FNOMnnOJxik8Cs47y"),"output/nyp_arrest_hist.gpkg")

test <- st_read("https://data.cityofnewyork.us/resource/8h9b-rp9u.geojson?%24limit=530887&%24%24app_token=59LeXuU7FNOMnnOJxik8Cs47y")
#ogr2ogr -f GPKG dst.gpkg https://data.cityofnewyork.us/resource/8h9b-rp9u.geojson?%24limit=530887&%24%24app_token=59LeXuU7FNOMnnOJxik8Cs47y -nln layerOne

#Seeing row numbers
query <- dbSendQuery(conn, "SELECT count(geometry) AS exact_count FROM censos.ny_shoting_historic;")
dbFetch(query)

#dbSendQuery(conn, "DROP TABLE ny_shoting_historic ;")

# Creating a function to load db from scratch db to postgresql/pos --------

create_postgis <-  function(x,y,z){
  x
  y
  z
  query <- sf::st_write(st_read(paste0("https://data.cityofnewyork.us/resource/",y,".geojson?%24limit=",z,"&%24%24app_token=59LeXuU7FNOMnnOJxik8Cs47y")) %>% 
                          st_make_valid() %>%
                          filter(!st_is_empty(.)) %>%
                          st_set_crs(.,4326), IDs = "geometry",
                        dsn= conn,
                        layer=x,
                        delete_layer=T,
                        append=F,
                        driver="PostgreSQL/PostGIS")
  return(query)
}

create_postgis("nypd_arrests_historic","8h9b-rp9u", "4000000")
create_postgis("collisions_crashes","h9gi-nx95")
create_postgis("nypd_shoting_historic","833y-fsy8","1000000")

# Trying rpostgis ---------------------------------------------------------
library(rpostgis)
library(tidyverse)
#https://mablab.org/rpostgis/reference/pgInsert.html
fun_connect<-function(){dbConnect(RPostgres::Postgres(),
                                  dbname='censos',
                                  host='localhost',
                                  port=5432,
                                  user='postgres',
                                  password='adminpass',
                                  options= '-c search_path=censos'
)}

conn<-fun_connect()

pgInsert(conn, name = c("censos","nypd_shoting_hist"),
         data.obj = as_Spatial(st_read("https://data.cityofnewyork.us/resource/833y-fsy8.geojson?%24limit=5000&%24%24app_token=59LeXuU7FNOMnnOJxik8Cs47y") %>%
                                 st_make_valid() %>%
                                 filter(!st_is_empty(.)) %>%
                                 st_set_crs(.,4326), IDs = "geometry"),
         geom = "geometry",
         partial.match = TRUE)

dbDisconnect(conn)


library(sf)
sf_extSoftVersion()


# More old-school methods  ------------------------------------------------


# Writing table -----------------------------------------------------------
#How to read from the url and save as 7zip

install.packages("archive") #Interesting package
readr::write_csv(readr::read_csv("https://data.cityofnewyork.us/resource/8h9b-rp9u.csv?%24limit=5308876&%24%24app_token=59LeXuU7FNOMnnOJxik8Cs47y"), archive_write("output/nypdarresthistoric.7zip", "nypdarresthistoric.csv", format='7zip'))

#https://oliverstringham.com/blog/data-science-tutorials/setting-up-postgres-postgis-to-run-spatial-queries-in-r-tutorial/

"ARREST_KEY	VARCHAR(15),
ARREST_DATE	DATE,
PD_CD	REAL(15),
PD_DESC	VARCHAR(15),
KY_CD	REAL,
OFNS_DESC VARCHAR(15),
LAW_CODE	VARCHAR(15),
LAW_CAT_CD VARCHAR(15),
ARREST_BORO VARCHAR(15),
ARREST_PRECINCT REAL,
JURISDICTION_CODE REAL,
AGE_GROUP VARCHAR(15),
PERP_SEX VARCHAR(15),
PERP_RACE VARCHAR(15),
X_COORD_CD VARCHAR(15),
Y_COORD_CD VARCHAR(15),
Latitude REAL,
Longitude REAL,
Lon_Lat	geom(POINT, 4326)"
