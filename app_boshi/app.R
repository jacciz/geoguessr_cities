library(leaflet)
library(sf)
library(googlesheets4)
library(shinyjs)
library(shiny)
library(tibble)
library(dplyr)

number_of_locations <- 10

selected_city <- "Madison"

# To allow access, open the .json. Copy that email (geoguessr@xx.iam.gserviceaccount.com) and 'Share with' for each google sheet.

if (selected_city == "Madison") {
  google_pics_folder <- "https://drive.google.com/drive/folders/1fD_wJYOYjsGevijQ9zGCmdnRRTmGak9k?usp=drive_link"
  response_spreadsheet_id <- "1wtOGecQTVsv8w-fESy0DRQ3kzagE9bqqYv4zz4ZV2u4"
  score_by_location_id <- "11DeQ3X3cR465WhVIjKQxcrddHtfAcJYknQncJ7mctTM"
  score_by_team_id <- "16jr22Ob9jWK0K6zhLtsw8zMTEnvelYZBFoj0Sz9buT0"
  # google_file_path <- "https://drive.google.com/drive/folders/1f4Gnv5bOFSkuigm3jB4DB02MZZi4uf49?usp=drive_link"
  google_sheet_link <- "https://docs.google.com/spreadsheets/d/1wtOGecQTVsv8w-fESy0DRQ3kzagE9bqqYv4zz4ZV2u4/edit?usp=sharing"
  google_locations <- "https://docs.google.com/spreadsheets/d/1_onfERhOgAqT4-PEpCp1ggPxFf-JyHYO-nAuTNHI0Kw/edit?usp=drive_link"
  starting_view <- c(lng = -89.3843312, 56, lat = 43.0747589)
}

source("05_score.R")
source("06_map.R")

carto_url <- paste0(
  "https://basemaps.cartocdn.com/rastertiles/light_all/{z}/{x}/{y}.png?key=",
  Sys.getenv('CARTO_MAPS_API_KEY')
)

ui <- bslib::page_navbar(
  # theme = bslib::bs_theme(bootswatch = "lux"),
  useShinyjs(),

  tags$head(
    tags$style(HTML(
      "
      body {
        background-image: url('https://file.garden/Zy75IlKnFHAuCMr4/subtletiles.png');
        background-size: 400px;
        background-repeat: repeat;
        min-height: 100vh;
        max-height: 100vh;
        max-width: 1200px;
        margin: auto;
        position: relative;
      }
      .mapContainer {
        width: 100%;
        height: 40vh;
        margin: auto;
        margin-bottom: 150px;
        filter: drop-shadow(2px 2px 0.12rem lightgray);
      }
      .mapTitle {
        text-align: left;
        font-size: 20px;
        font-weight: bold;
        margin-bottom: 10px;
      }
      .hidden {
        display: none;
      }
      .btn {
        background-color: #A5C679 !important;
        border-color: #A5C679 !important;
        color: black !important;
        font-weight: bold !important;
        transition: background-color 0.2s ease-in-out, box-shadow 0.2s ease-in-out;
        box-shadow: 2px 2px 5px forestgreen !important;
        margin: 5px;
      }
      .btn:hover {
        background-color: lightgray !important;
      }
      .header-image {
        margin: auto;
        display: block;
        margin-top: 20px;
        width: 100%;
        filter: drop-shadow(2px 2px 0.12rem #969696);
      }
      .spacer {
        margin-top: 15px;
      }
      .spacer_large {
        margin-top: 100px;
      }
      .wide-btn {
        width: 200px !important;
        height: 40px !important;
        font-size: 1.1em !important;
      }
      .left-align {
        text-align: left;
        margin-top: 10px;
      }
    "
    ))
  ),
  bslib::nav_panel(
    title = "Make Your Guesses!",
    # tags$img(
    #   src = "https://file.garden/Zy75IlKnFHAuCMr4/nycsign2.png",
    #   class = "header-image"
    # ),
    bslib::card(
    h1("Local Geoguesser!"),
    p(
      "There are 10 locations with pictures. Your job is to guess where in the selected city these Google Street View images were taken."
    ),

    p(
      "Once you submit your guesses, go to the 'Reveal Answers' tab above to view answers! And see how well you did compared to others! Your results WILL be seen by others."
    ),
    radioButtons(
      "select_city",
      label = "Select City",
      # choices = c("Madison", "Columbus"),
      choices = c("Madison"),
      inline = TRUE
    ),

    "All locations are within these city bounds",
    div(
      id = paste0("map_container", 99),
      class = "mapContainer",
      # div(class = "mapTitle", paste("Location", i)),
    leafletOutput("selected_city_map")
    ),
    div(
      class = "left-align",
      actionButton(
        "photo_link",
        "View Photos",
        class = "btn wide-btn",
        onclick = paste0("window.open('", google_pics_folder, "', '_blank')")
      )
    ),

    textInput(
      "team_name",
      "Your Identity",
      value = "",
      placeholder = "Enter your identity (or real name)",
      width = "80%"
    ),
    fluidRow(
      column(
        6,
        tags$h2(tags$b(
          tags$span(paste("Number of Locations:", number_of_locations))
        ))
      )
    ),

    fluidRow(
      lapply(1:number_of_locations, function(i) {
        column(
          width = 6,
          div(
            id = paste0("map_container", i),
            class = "mapContainer",
            div(class = "mapTitle", paste("Location", i)),
            leafletOutput(
              paste0("map", i),
              width = "100%",
              # height = "400px"
              height = "100%"
            ),
            tags$br(),
            textInput(
              paste0("coords_text", i),
              paste("Location", i, "Coordinates:"),
              value = "",
              placeholder = "Click on the map to get coordinates"
            )
          )
        )
      })
    ),

    actionButton("submit_button", "Submit", class = "wide-btn")
  )),
  bslib::nav_panel(
    title = "Reveal Answers",
    actionButton(
      "answer_button",
      "Reveal Answers",
      class = "btn large"
    ),
    uiOutput("solutions_maps")
  )

)

server <- function(input, output, session) {
  googledrive::drive_auth(path = "geocoding-420620-6865fda94d05.json", use_oob = TRUE)
  googlesheets4::gs4_auth(path = "geocoding-420620-6865fda94d05.json", use_oob = TRUE,
                          scopes = c("spreadsheets", "drive"))
  # gs4_auth_configure(api_key = Sys.getenv("GMAILR_OAUTH_CLIENT"))
  # gs4_auth()

  output$selected_city_map <- renderLeaflet({
    polygon_sf <- sf::read_sf("madison.shp")

    leaflet::leaflet(polygon_sf) |>
      addPolygons() |>
      addTiles(
        urlTemplate = carto_url,
        attribution = paste(
          '&copy; <a href="https://carto.com/attributions">CARTO</a>,',
          '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        )
      )
  })
  
  selected_coords <- reactiveValues(
    coords = vector("list", number_of_locations)
  )

  lapply(1:number_of_locations, function(i) {
    output[[paste0("map", i)]] <- renderLeaflet({
      leaflet(data = tibble(name = character())) %>%
        addTiles(
          urlTemplate = carto_url,
          attribution = paste(
            '&copy; <a href="https://carto.com/attributions">CARTO</a>,',
            '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          )
        ) |>
        # addProviderTiles(providers$CartoDB.Positron) %>%
        setView(
          lng = starting_view[["lng"]],
          lat = starting_view[["lat"]],
          zoom = 11
        )
    })

    observeEvent(input[[paste0("map", i, "_click")]], {
      click <- input[[paste0("map", i, "_click")]]
      selected_coords$coords[[i]] <- c(lat = click$lat, lng = click$lng)

      leafletProxy(paste0("map", i)) %>%
        clearMarkers() %>%
        addMarkers(lng = click$lng, lat = click$lat)

      updateTextInput(
        session,
        paste0("coords_text", i),
        value = paste(click$lat, click$lng, sep = ", ")
      )
    })
  })

  observeEvent(input$submit_button, {
    team_name <- input$team_name
    if (team_name == "") {
      showNotification(
        "Please enter a team name before submitting.",
        type = "error"
      )
      return()
    }

    all_coords <- lapply(1:number_of_locations, function(i) {
      coords <- selected_coords$coords[[i]]
      if (!is.null(coords)) {
        data.frame(
          team_name = team_name,
          location = i,
          lat = coords["lat"],
          lng = coords["lng"],
          datetime = Sys.time(),
          round = 1
        )
      } else {
        NULL
      }
    })
    all_coords <- bind_rows(all_coords)

    # TODO change back
    # if (nrow(all_coords) == number_of_locations) {
    if (nrow(all_coords) > 0) {
      sheet_append(ss = response_spreadsheet_id, data = all_coords, sheet = "Sheet1")
      showNotification("Responses saved successfully!", type = "message")

      showModal(
        modalDialog(
          title = "Please wait",
          tags$div(
            style = "text-align: center;",
            tags$p("Saving Answers and Generating Maps..."),
            tags$div(
              class = "spinner-border",
              role = "status"
            )
          ),
          footer = NULL,
          easyClose = FALSE
        )
      )

      score_guesses(google_locations, google_sheet_link)

      removeModal()

      showNotification(
        "Go To 'Reveal Answers' Tab Above to See Answers!",
        type = "message"
      )
    } else {
      showNotification(
        "Please select points on all maps before submitting.",
        type = "error"
      )
    }
  })

  observeEvent(input$answer_button, {
    showModal(
      modalDialog(
        title = "Warning",
        "Are you sure you want to continue? This will reveal the answers!",

        footer = tagList(
          modalButton("Cancel"),
          actionButton("confirm_ok", "OK", class = "btn-primary")
        ),

        easyClose = FALSE
      )
    )
  })

  observeEvent(input$confirm_ok, {
    removeModal()
  })

  output$solutions_maps <- renderUI({
    req(input$confirm_ok == 1)

    by_location_all <- googlesheets4::read_sheet(
      ss = score_by_location_id,
      sheet = "Sheet1"
    )

    by_location <- by_location_all |>
      dplyr::filter(team_name == input$team_name)

    if (input$team_name == "") {
      by_location <- ""
    } else {
      by_location <- by_location |>
        group_by(location) |>
        # Keeps last submitted guess for each location
        filter(datetime == max(datetime)) |>
        ungroup() |>
        select(Location = seqnum, Identity = team_name, Distance = distance_label, Score = score) |>
        gt::gt(caption = "Scores by Location") |>
        gt::as_raw_html()
    }
    
    by_user <- googlesheets4::read_sheet(
      ss = score_by_team_id,
      sheet = "Sheet1"
    ) |>
      dplyr::rename("Identity" = "team_name", "Score" = "score") |>
      dplyr::arrange(rev(Score)) |>
      gt::gt(caption = "Overall Scores by Identity") |>
      gt::as_raw_html()

    fluidRow(
      # Overall standings card
      column(
        width = 12,
        bslib::card(
          bslib::card_header("Overall Standings"),
          bslib::card_body(
            div(
              style = "display: flex; gap: 40px; align-items: flex-start;",
              by_location,
              by_user
            )
          )
        )
      ),
      
      # Answers by identity card
      column(
        width = 12,
        bslib::card(
          bslib::card_header("Answers by Identity"),
          bslib::card_body(
            fluidRow(
              lapply(1:number_of_locations, function(i) {
                column(
                  width = 6,
                  div(
                    id = paste0("map_container", i),
                    class = "mapContainer",
                    div(class = "mapTitle", paste("Location", i)),
                    create_map_of_guesses_by_location(
                      score_by_location = by_location_all,
                      seqnum_i = i,
                      starting_view,
                      url = carto_url
                    )
                  )
                )
              })
            )
          )
        )
      )
    )
  })
}

shinyApp(ui, server)
