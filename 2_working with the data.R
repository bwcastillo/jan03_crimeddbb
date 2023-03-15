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


# Loading different scales ------------------------------------------------


# Administratives scales --------------------------------------------------

#Census Track: https://data.cityofnewyork.us/City-Government/2020-Census-Tracts-Tabular/63ge-mke6
st_write(st_read("https://data.cityofnewyork.us/api/geospatial/63ge-mke6?accessType=DOWNLOAD&method=export&format=GeoJSON"),dsn = conn, 'ct_nyc')

#Census Block: https://data.cityofnewyork.us/City-Government/2020-Census-Blocks-Tabular/wmsu-5muw
st_write(st_read("https://data.cityofnewyork.us/api/geospatial/wmsu-5muw?accessType=DOWNLOAD&method=export&format=GeoJSON"),dsn = conn, 'block_nyc')



# Census population -------------------------------------------------------


library(tigris)
#https://rconsortium.github.io/censusguide/
st_write(st_read(blocks(state="NY",year=2020)),dsn=conn, layer='block_ny_state')

ggplot(blocknyc)+
  geom_sf()
rm(blocknyc)

# Joining NY state block Census data with NYC block Geom ------------------
#Knowing the GEOID attribute name of both
st_read(conn,query="SELECT column_name 
                    FROM information_schema.columns
                    WHERE table_name = 'block_nyc'")

dbSendQuery(conn,"SELECT * 
                  FROM block_nyc block_nyc
                  LEFT JOIN block_ny_state block_ny_state
                  ON block_nyc. = block_ny_state.id")

dbSendQuery(conn,"SELECT * 
                  FROM  block_nyc
                  LEFT JOIN  block_ny_state
                  ON block_nyc. = block_ny_state.id")

# Unique scales -----------------------------------------------------------

#Loading borough at PostGIS
st_write(st_read("https://data.cityofnewyork.us/resource/7t3b-ywvw.geojson"),dsn = conn, 'borough_nyc')

#Community District Tabulation Areas
st_write(st_read("https://data.cityofnewyork.us/api/geospatial/xn3r-zk6y?accessType=DOWNLOAD&method=export&format=GeoJSON"),dsn = conn, 'cdta_nyc')

#Neighborhood
st_write(st_read("https://data.cityofnewyork.us/api/geospatial/9nt8-h7nd?accessType=DOWNLOAD&method=export&format=GeoJSON"),dsn = conn, 'neighborhood_nyc')

# Polcies boundaries ------------------------------------------------------

#Police Precincts
#https://data.cityofnewyork.us/api/geospatial/78dh-3ptz?method=export&format=GeoJSON


#NYPD Sectors
#https://data.cityofnewyork.us/api/geospatial/eizi-ujye?method=export&format=GeoJSON


#Querying intersects as table ------------------------------------------------------
test <- dbSendQuery(conn,"SELECT ST_Intersects(nypd_shooting_historic.geometry, borough_nyc.geometry)
            FROM nypd_shooting_historic, borough_nyc;")

test <- dbFetch(test)

#OR

#
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


# Counting the frequency of each point in each scale ----------------------
#https://www2.census.gov/geo/pdfs/reference/geodiagram.pdf
#https://en.wikipedia.org/wiki/Administrative_divisions_of_New_York_(state)
#https://ballotpedia.org/New_York_state_executive_offices



test <- st_read(conn,query="SELECT ST_Contains(nypd_shooting_historic.geometry, borough_nyc.geometry)
                FROM nypd_shooting_historic, borough_nyc;")

test <- st_read(conn,query="SELECT  boro_name, statistical_murder_flag, vic_race FROM borough_nyc, nypd_shooting_historic
                            WHERE ST_Contains(borough_nyc.geometry,nypd_shooting_historic.geometry);")

test <- table(test)|>as.data.frame() #Funny

sum(test$Freq)

# Densities of shooting and arrest by block -------------------------------

#First method: very slow
#Count people in each borough
# st_intersection(st_make_valid(st_read(conn,query='SELECT block_nyc.geoid, block_nyc.geometry FROM block_nyc')),
#                 st_make_valid(st_read(conn,query='SELECT * FROM nypd_shooting_historic')))

#Second method
#Querying shootings
shooting_block <- st_read(conn,query="SELECT block_nyc.geoid, count(nypd_shooting_historic.geometry)
                                       FROM block_nyc
                                       LEFT JOIN nypd_shooting_historic ON st_contains(block_nyc.geometry, nypd_shooting_historic.geometry)
                                       GROUP BY block_nyc.geoid;")

#Querying arrest
arrests_block <- st_read(conn,query="SELECT block_nyc.geoid, count(nypd_arrest_historic.geometry)
                                       FROM block_nyc
                                       LEFT JOIN nypd_arrest_historic ON st_contains(block_nyc.geometry, nypd_arrest_historic.geometry)
                                       GROUP BY block_nyc.geoid;")

# Joining with geometry ----------------------------------------------------
# Shooting
shooting_block <- left_join(shooting_block, st_read(conn,layer = "block_nyc"), by="geoid")|> st_as_sf()
#Arrest
arrests_block <- left_join(arrests_block, st_read(conn,layer = "block_nyc"), by="geoid")|> st_as_sf()


# Seeing descriptive statistics for the variable of interest --------------

# Creating Poisson model --------------------------------------------------



shooting_block$count <- as.integer(shooting_block$count)
freq_shoot <- table(shooting_block$count)|>as.data.frame()
table(shooting_block$count)|>as.data.frame()|>ggplot()+geom_col(aes(x=Var1,y=Freq))
shooting_block[shooting_block$count>0,] |> ggplot()+geom_histogram(aes(x=count))
shooting_block$count[shooting_block$count>0&shooting_block$count<30] |> hist()
shooting_block$count[shooting_block$count>0]|>mean()
shooting_block$count[shooting_block$count>0]|>sd()

#Finding the distribution of the dependent variable -----------------------
library(fitdistrplus)
descdist(shooting_block$count, discrete = T)
descdist(shooting_block$count[shooting_block$count>0&shooting_block$count<15], discrete = T)#Very ideal case
descdist(shooting_block$count[shooting_block$count>0&shooting_block$count<30], discrete = T)

options(scipen = F)


# Calculating Expsoure and Offset -----------------------------------------





# Classification shooting -----------------------------------
library(rgeoda)
natural_breaks(5, shooting_block[shooting_block$count>0,]['count'])

shooting_block$class <- case_when(shooting_block$count==0 ~ "No shooting",
                                  shooting_block$count>=1 & shooting_block$count<=4 ~ "1-4",
                                  shooting_block$count>4 & shooting_block$count<=9 ~ ">4-9",
                                  shooting_block$count>9 & shooting_block$count<=18 ~ ">9-18",
                                  shooting_block$count>18 & shooting_block$count<=37 ~ ">18-37",
                                  shooting_block$count>37 ~ ">37")


# Ploting shootings --------------------------------------------------------
ggplot()+
  geom_sf(data=shooting_block,aes(fill=as.integer(count)),colour=NA)+
  scale_fill_gradient(low = 'pink', high='red', na.value = 'yellow')+
  labs(fill='Number of Shootings', title='Number of Shootings')+
  geom_sf(data = st_read(conn,layer = 'neighborhood_nyc'), fill=NA, linewidth = 0.5, color='green')+
  geom_sf(data = st_read(conn,layer = 'borough_nyc'),fill=NA, linewidth = 1.3 ,color='gray')

# Ploting arrests --------------------------------------------------------
ggplot()+
  geom_sf(data=arrests_block,aes(fill=as.integer(count)),colour=NA)+
  scale_fill_gradient(low = 'pink', high='red', na.value = 'yellow')+
  labs(fill='Number of Arrests' , title='Number of Arrest')+
  geom_sf(data = st_read(conn,layer = 'neighborhood_nyc'), fill=NA, linewidth = 0.5, color='green')+
  geom_sf(data = st_read(conn,layer = 'borough_nyc'),fill=NA, linewidth = 1.3 ,color='gray')

# Creating interactive maps -----------------------------------------------

library(leaflet)

colpal <- 
  colorFactor(palette ="viridis", 
              domain=shooting_block$class, 
              levels = factor(shooting_block$class,
                              labels = c('>37','>18-37', '>9-18','>4-9', '1-4','No shooting'),
                              levels = c('>37','>18-37', '>9-18','>4-9', '1-4','No shooting')),
              ordered = F)


#head(st_read(conn, 'neighborhood_nyc'))
library(rmapshaper)

map_shooting<-leaflet() %>% 
              addTiles() %>%
              addPolygons(data=rmapshaper::ms_simplify(shooting_block, 0.8),
                          popup=shooting_block$class,
                          group = "barrios",
                          color = ~colpal(class),
                          stroke = T,
                          weight = 0.5) %>% 
              addPolygons(data= st_read(dsn=conn,layer="neighborhood_nyc"),
                          label =  st_read(dsn=conn,layer="neighborhood_nyc")$ntaname,
                          dashArray = 1,
                          color = 'white',
                          fillColor = F,
                          weight = 2,
                          group = 'neighbor') %>% 
              addLegend(values=shooting_block$class, pal=colpal) %>% 
              addLayersControl(overlayGroups  = 'neighbor')
          
library(htmlwidgets)
saveWidget(map_shooting, file="output/map_shooting.html")
  
#Nominal classifications
#Vic_race
#vic_sex
#precinct
#vic_age_group
#boro
#occur_date
#occur_time
#Statistical murder flag

# Querying spatial and non-spatial ------------------------
# Non Spatial counts of categories ------------------------
st_read(conn,query="SELECT nypd_shooting_historic.vic_race, count(*)
                     FROM nypd_shooting_historic
                     GROUP BY vic_race
                     ORDER BY count(*) desc;")

st_read(conn,query="SELECT nypd_shooting_historic.vic_sex, count(*)
                     FROM nypd_shooting_historic
                     GROUP BY vic_sex
                     ORDER BY count(*) desc;")

st_read(conn,query="SELECT nypd_shooting_historic.precinct, count(*)
                     FROM nypd_shooting_historic
                     GROUP BY precinct
                     ORDER BY count(*) desc;")

st_read(conn,query="SELECT nypd_shooting_historic.occur_time, count(*)
                     FROM nypd_shooting_historic
                     GROUP BY occur_time
                     ORDER BY count(*) desc;")

st_read(conn,query='ALTER TABLE nypd_shooting_historic
                    ALTER COLUMN occur_time TYPE time
                    USING occur_time::time without time zone')



dbListTables(conn)

st_read(conn,query="SELECT column_name 
                    FROM information_schema.columns
                    WHERE table_name = 'block_nyc'")

st_read(conn,query='SELECT COUNT(*) FROM block_nyc ')




# Spatial -----------------------------------------------------------------





#Exploring Heterogeneity, Dependence, Sparsity, Uncertainty 
#Heterogeneity: https://www.crimrxiv.com/pub/44brr2tx/release/1
#https://postgis.net/workshops/postgis-intro/






# Bibliography to read ----------------------------------------------------
#https://scholar.google.com/citations?user=k1zG5D0AAAAJ&hl=en
#https://onlinelibrary.wiley.com/doi/full/10.1111/1556-4029.15132
#https://www.sciencedirect.com/science/article/pii/S0047235222000496
#https://onlinelibrary.wiley.com/doi/abs/10.1111/1745-9133.12608
#https://onlinelibrary.wiley.com/doi/full/10.1111/1556-4029.15132
#https://www.ncbi.nlm.nih.gov/pmc/articles/PMC9642971/
#https://journals.sagepub.com/doi/abs/10.1177/002242788001700107?journalCode=jrca
#https://link.springer.com/article/10.1007/s10940-020-09490-6
#https://onlinelibrary.wiley.com/doi/full/10.1002/cl2.1046
# Arrests
#https://academic.oup.com/bjc/article-abstract/59/4/958/5373005
#https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0157223

