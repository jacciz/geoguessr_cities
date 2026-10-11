generate_metadata <- function(
  locations_draft_spaced,
  google_locations,
  round_no
) {
  locations <- locations_draft_spaced %>%
    rowwise() %>%
    mutate(
      valid = {
        coords <- str_split(location, ",")[[1]]
        lat <- coords[1]
        lng <- coords[2]
        res <- fromJSON(
          GET(
            paste0(
              "https://maps.googleapis.com/maps/api/streetview/metadata?location=",
              location,
              "&key=",
              Sys.getenv("GOOGLE_MAPS_API_KEY")
            )
          ) %>%
            content("text")
        )
        res$status == "OK"
      },
      latitude = {
        if (valid) {
          coords <- str_split(location, ",")[[1]]
          res <- fromJSON(
            GET(
              paste0(
                "https://maps.googleapis.com/maps/api/streetview/metadata?location=",
                location,
                "&key=",
                Sys.getenv("GOOGLE_MAPS_API_KEY")
              )
            ) %>%
              content("text")
          )
          res$location$lat
        } else {
          NA
        }
      },
      longitude = {
        if (valid) {
          coords <- str_split(location, ",")[[1]]
          res <- fromJSON(
            GET(
              paste0(
                "https://maps.googleapis.com/maps/api/streetview/metadata?location=",
                location,
                "&key=",
                Sys.getenv("GOOGLE_MAPS_API_KEY")
              )
            ) %>%
              content("text")
          )
          res$location$lng
        } else {
          NA
        }
      }
    )

  googlesheets4::write_sheet(
    data = locations,
    ss = google_locations,
    sheet = "Sheet1"
  )
}

generate_metadata(
  locations_draft_spaced = locations_draft_spaced,
  google_locations,
  round_no = round_no
)
