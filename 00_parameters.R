# library(tibble)
library(dplyr)
library(readr)
library(sf)
library(httr)
library(jsonlite)
library(purrr)
# library(tidyverse)
# library(janitor)
# library(googlesheets4)
library(stringr)
library(geosphere)
round_no <- 1
number_of_sites <- 10
city <- "Madison"

# To upload images
googledrive::drive_auth()

# RESPONSE FROM USERS
# google_sheet_link <- "https://docs.google.com/spreadsheets/d/1wtOGecQTVsv8w-fESy0DRQ3kzagE9bqqYv4zz4ZV2u4/edit?usp=sharing"
google_locations <- "https://docs.google.com/spreadsheets/d/1_onfERhOgAqT4-PEpCp1ggPxFf-JyHYO-nAuTNHI0Kw/edit?usp=drive_link"
response_spreadsheet_id <- "1wtOGecQTVsv8w-fESy0DRQ3kzagE9bqqYv4zz4ZV2u4"

pano <- "on" #on or off to save panorama pictures of locations
auto_run <- "yes"

# output_location <- paste0(city, "/output/")

wi <- tigris::places(state = "WI")
madison <- wi |> filter(NAME == "Madison") |> st_transform(4326)

polygon_sf <- madison
sf::write_sf(madison, "app_boshi/madison.shp")

# Clear the spreadsheet
googlesheets4::range_delete(
  ss = response_spreadsheet_id,
  sheet = "Sheet1",
  range = "Sheet1!A2:ZZ"
)

if (auto_run == "yes") {
  # Outputs locations_draft_spaced
  source("02_locations.R")

  # Saves to locations sheet
  source("03_metadata.R")

  # Loops through locations to download images
  source("04_images.R")
}

# Need to specify url with API so basemap will work
# mapType <- "CartoDB.Positron"
# #Map the chosen basemap to the appropriate URL
# url <- paste0(
#   switch(
#     mapType, #This is my selection variable as I use this inside of a shiny app
#     'CartoDB' = "https://basemaps.cartocdn.com/rastertiles/light_all/{z}/{x}/{y}.png",
#     'CartoDB.Positron' = "https://basemaps.cartocdn.com/rastertiles/light_all/{z}/{x}/{y}.png",
#     'CartoDB.PositronNoLabels' = "https://basemaps.cartocdn.com/rastertiles/light_nolabels/{z}/{x}/{y}.png",
#     'CartoDB.PositronOnlyLabels' = "https://basemaps.cartocdn.com/rastertiles/light_only_labels/{z}/{x}/{y}.png",
#     'CartoDB.DarkMatter' = "https://basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}.png",
#     'CartoDB.DarkMatterNoLabels' = "https://basemaps.cartocdn.com/rastertiles/dark_nolabels/{z}/{x}/{y}.png",
#     'CartoDB.DarkMatterOnlyLabels' = "https://basemaps.cartocdn.com/rastertiles/dark_only_labels/{z}/{x}/{y}.png",
#     'CartoDB.Voyager' = "https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png",
#     'CartoDB.VoyagerNoLabels' = "https://basemaps.cartocdn.com/rastertiles/voyager_nolabels/{z}/{x}/{y}.png",
#     'CartoDB.VoyagerOnlyLabels' = "https://basemaps.cartocdn.com/rastertiles/voyager_only_labels/{z}/{x}/{y}.png",
#     'CartoDB.VoyagerLabelsUnder' = "https://basemaps.cartocdn.com/rastertiles/voyager_labels_under/{z}/{x}/{y}.png"
#   ),
#   '?key=',
#   Sys.getenv('CARTO_MAPS_API_KEY')
# )
