
# Getting & Opening the data ----------------------------------------------


#Toronto datasets:
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


shooting_ny <- geojsonio::geojson_sf("https://data.cityofnewyork.us/resource/833y-fsy8.geojson?%24limit=5000&%24%24app_token=59LeXuU7FNOMnnOJxik8Cs47y")
arrests_ny <- geojsonio::geojson_sf("https://data.cityofnewyork.us/resource/8h9b-rp9u.geojson?%24limit=10000&%24%24app_token=59LeXuU7FNOMnnOJxik8Cs47y")

test <- sf::st_read("C:\\Users\\bryan\\PycharmProjects\\spatial_python\\data\\nypd_arrest_historic.geojson")