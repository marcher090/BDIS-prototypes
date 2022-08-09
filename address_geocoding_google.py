#address_geocoding.txt
#The purpose of this script is to generate a list of latitude / longitude coordinates from a list of addresses in a stick-delimited text file. I used the Google V3 geocoder to geocode the addresses. 

#============================================================
#Step 0: Install/import Python Libraries
##Install the libraries using command line arguments
# pip install wheel
# pip install pipwin
# pipwin install numpy
# pipwin install pandas
# pipwin install shapely
# pipwin install gdal
# pipwin install fiona
# pipwin install pyproj
# pipwin install six
# pipwin install rtree
# pipwin install geopandaspas
# pip install geopy
# pip install googlemaps

##Import the relevant libraries and modules
from tkinter.tix import PopupMenu
import pandas
import geopandas
import geopy
from geopy.geocoders import nominatim
from geopy.extra.rate_limiter import RateLimiter
import matplotlib.pyplot
import folium
from folium.plugins import fast_marker_cluster
from shapely.geometry import point
import json

#=========================================================================================

#Step 1: Configure environment and execute geocoder

#Configure the geocoder. We have chosen Nominatim because it  provides a geocoding function utilizing the same data that is used to generate OpenStreetMap

#import the geocoder
import googlemaps
from datetime import datetime
import json


#set the geolocator as the the geocoder with nominatim as the algorithm and with the user_agent <BDISGeocoder>
gmaps = googlemaps.Client(key = "AIzaSyC283GR8D4_S7EKkYtmDi7Em4CZyeB1DD8")
geocoder = gmaps.geocode


#Test the geocoder
print("TESTING THE GEOCODER \n \n")


location_json= geocoder("Champ de Mars, Paris, France")

location_dict = location_json[0]

latitude = location_dict["geometry"]["location"]["lat"]
longitude = location_dict["geometry"]["location"]["lng"]

print(latitude)
print(longitude)

print("TESTING COMPLETE")

#=========================================================================================

#step 2: Read and import data from text file


#read data from file to data frame
df =pandas.read_csv(r"C:\Users\marcher\OneDrive - Best Doctors Insurance\General - Data & Analytics Team\Ad Hoc Data Requests\Agent Geolocating\Agent_Address_List.txt", sep = "|", engine = 'python')


#add a latitude and longitude column to the data frame
df["latitude"] = 0.0
df["longitude"] = 0.0

#provide basic information on dataframe
print("there are ", len(df), " rows in the dataframe")
df.head()



#========================================================================================

#Step 3: Run the geocoder

print ("GEOLOCATING")
a = 0
i = len(df)


while a < i: 
    #geolocate the address of row a
    location_json= geocoder(df["full_address"].loc[a])
    location_dict = location_json[0]
    #assign the lat and lon to the address of row a
    df["latitude"].loc[a] =  location_dict["geometry"]["location"]["lat"]  # type: ignore
    df["longitude"].loc[a] = location_dict["geometry"]["location"]["lng"]  # type: ignore
    #set a one up 
    a += 1
print ("GEOLOCATION COMPLETE")

print(df)


df.to_csv(r"C:\Users\marcher\OneDrive - Best Doctors Insurance\General - Data & Analytics Team\Ad Hoc Data Requests\Agent Geolocating\Agent_Address_List_geocode.txt")

#==========================================================================

#Step 4: Visualize the locations
import folium
from folium.plugins import MarkerCluster

m = folium.Map(location=df[["latitude", "longitude"]].mean().to_list(), zoom_start=2)

marker_cluster = MarkerCluster().add_to(m)

for i,r in df.iterrows():
    location = (r["latitude"], r["longitude"])
    folium.Marker(location=location,
                popup =
                "<b>Agency Name:\n</b>"+
                r['IsAgencyName']+
                "\n"+
                "<b>Agency Code: </b>" +
                "\n"+ 
                r['IsAgencyCode'] + 
                "\n"+
                "<b>Agency Full Address: </b>" +
                "\n"+ 
                str(r['full_address']))\
    .add_to(marker_cluster)


m