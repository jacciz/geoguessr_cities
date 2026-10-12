extract_valid_points <- function(point_sf) {
  coords <- st_coordinates(point_sf)

  results <- lapply(seq_len(nrow(coords)), function(i) {
    response <- fromJSON(
      GET(
        paste0(
          "https://maps.googleapis.com/maps/api/streetview/metadata?location=",
          coords[i, "Y"],
          ",",
          coords[i, "X"],
          "&key=",
          Sys.getenv("GOOGLE_MAPS_API_KEY")
        )
      ) %>%
        content("text")
    )$status
  })

  results_df <- data.frame(
    status = unlist(results)
  )
  cbind(point_sf, results_df) |> filter(status == "OK")
}
# Generate random points within the polygon
generate_random_points <- function(polygon, n = 1) {
  bbox <- st_bbox(polygon)
  points <- tibble(
    lon = runif(n * 5, bbox["xmin"], bbox["xmax"]), # Generate extra points for filtering
    lat = runif(n * 5, bbox["ymin"], bbox["ymax"])
  ) %>%
    st_as_sf(coords = c("lon", "lat"), crs = 4326)

  points_within <- points[st_intersects(points, polygon, sparse = FALSE), ]

  points_within <- extract_valid_points(points_within)

  if (nrow(points_within) < n) {
    # Generate more points if needed
    rbind(
      points_within,
      generate_random_points(polygon, n - nrow(points_within))
    )
  } else {
    # Take first row
    points_within[1:n, ]
  }
}

generate_locations <- function(polygon, number_of_sites) {
  polygon_sf <- st_sfc(st_as_sfc(polygon), crs = 4326)
  locations_draft <- data.frame()
  
  locations_draft <- map_dfr(
    1:number_of_sites,
    ~ st_coordinates(
      generate_random_points(polygon_sf, n = 1)
    ) %>%
      as_tibble() %>%
      rename(
        longitude_draft = X,
        latitude_draft = Y
      ) %>%
      mutate(
        location = paste0(latitude_draft, ",", longitude_draft)
      )
  )

  locations_draft
}

locations_draft <- generate_locations(
  polygon = polygon_sf,
  number_of_sites = number_of_sites
)

locations_draft$row_num <- seq_len(nrow(locations_draft))

locations_draft_spaced <- locations_draft %>%
  cross_join(locations_draft) %>%
  filter(row_num.x != row_num.y) %>%
  mutate(
    distance = distHaversine(
      cbind(longitude_draft.x, latitude_draft.x),
      cbind(longitude_draft.y, latitude_draft.y)
    )
  ) %>%
  group_by(row_num.x) %>%
  mutate(min_dist = min(distance, na.rm = TRUE)) %>%
  filter(min_dist >= 314) %>%
  ungroup() %>%
  select(
    longitude_draft = longitude_draft.x,
    latitude_draft = latitude_draft.x,
    location = location.x
  ) %>%
  distinct()
