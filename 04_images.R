camera_angles <- c("0", "72", "144", "216", "288")

locations <- locations_draft_spaced

google_folder <- googledrive::drive_get(paste0("Live Geoguessr/", city))

for (i in 1:nrow(locations)) {
  for (j in 1:length(camera_angles)) {
    # Parameters
    api_key <- Sys.getenv("GOOGLE_MAPS_API_KEY")
    location <- locations$location[i] # Latitude,Longitude
    size <- "2048x2048" # Image size in pixels
    heading <- camera_angles[j] # Direction of the camera in degrees
    pitch <- "0" # Angle of the camera
    output_file <- paste0(
      output_location,
      "Round ",
      round_no,
      "/location_",
      i,
      "_image_",
      j,
      ".jpg"
    ) # Name of the output file

    # Construct the URL
    url <- paste0(
      "https://maps.googleapis.com/maps/api/streetview?",
      "size=",
      size,
      "&",
      "location=",
      location,
      "&",
      "heading=",
      heading,
      "&",
      "pitch=",
      pitch,
      "&",
      "source=outdoor",
      "&",
      "key=",
      api_key
    )

    response <- GET(url)

    # Temporary local file
    tmp_file <- tempfile(fileext = ".jpg")

    # Write the JPEG binary
    writeBin(content(response, "raw"), tmp_file)

    # Upload to Google Drive
    googledrive::drive_upload(
      media = tmp_file,
      path = google_folder,
      name = paste0("location_",i,"_image_",j,".jpg"),
      overwrite = TRUE
    )

    # Check if the download was successful
    if (response$status_code == 200) {
      message("Image downloaded successfully!")
    } else {
      message("Failed to download image: ", response$status_code)
    }
    Sys.sleep(1)
  }
}

