create_map_of_guesses_by_location <- function(
  score_by_location,
  seqnum_i,
  starting_view,
  url
) {
  round_no <- 1
  
  filtered_data <- score_by_location %>% dplyr::filter(seqnum == seqnum_i)

  # Create a leaflet map
  map <- leaflet(
    ) %>%
    # addProviderTiles(providers$CartoDB.Positron)
    addTiles(
      urlTemplate = url,
      attribution = paste(
        '&copy; <a href="https://carto.com/attributions">CARTO</a>,',
        '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
      )
    )

  # Add lines connecting each guess to its corresponding actual coordinate
  for (i in 1:nrow(filtered_data)) {
    map <- map %>%
      addPolylines(
        lng = c(filtered_data$longitude[i], filtered_data$longitude_guess[i]),
        lat = c(filtered_data$latitude[i], filtered_data$latitude_guess[i]),
        color = "black",
        opacity = 1,
        weight = 1
      )
  }

  # Add points for actual coordinates
  map <- map %>%
    addCircleMarkers(
      data = filtered_data,
      lng = ~longitude,
      lat = ~latitude,
      color = "yellow",
      stroke = TRUE,
      weight = 4,
      fillColor = "black",
      fillOpacity = 1,
      radius = 5,
      popup = ~ paste("Actual location ", max(filtered_data$seqnum))
    )

  # Add points for guessed coordinates
  map <- map %>%
    addCircleMarkers(
      data = filtered_data,
      lng = ~longitude_guess,
      lat = ~latitude_guess,
      color = "black",
      stroke = TRUE,
      weight = 2,
      fillColor = "red",
      fillOpacity = 1,
      radius = 5,
      popup = ~ paste(
        team_name,
        "<br>",
        "Distance: ",
        distance_label,
        "<br>",
        "Score: ",
        score
      )
    )
  
  map <- map %>%
    setView(
      lng = starting_view[["lng"]],
      1766,
      lat = starting_view[["lat"]],
      zoom = 10
    )
  
  map

}
