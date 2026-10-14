# score_guesses(google_locations, round_no, google_sheet_link)

score_guesses <- function(
  google_locations,
  google_sheet_link
) {
  max_dist <- 73000
  round_no <- 1

  answers <- read_sheet(ss = google_locations)

  # Takes most recent submission per location
  guesses <- googlesheets4::read_sheet(google_sheet_link) %>%
    # filter(round==round_no)%>%
    group_by(team_name, location) %>%
    filter(datetime == max(datetime)) %>%
    ungroup()

  # if(answers > 1)
  score_by_location <- answers %>%
    mutate(seqnum = row_number()) |>
    right_join(guesses, by = c("seqnum" = "location")) %>%
    mutate(
      distance = geosphere::distHaversine(
        cbind(longitude, latitude),
        cbind(longitude_guess, latitude_guess)
      ) *
        3.28084
    ) %>%
    mutate(score = 5000 * exp(-10 * distance / max_dist)) %>%
    mutate(score = ifelse(distance < 5280, score * 1.02, score)) %>%
    mutate(score = ifelse(distance < 160, 5000, score)) %>%
    mutate(score = ifelse(score > 5000, 5000, score)) %>%
    mutate(score = round(score, 0)) %>%
    mutate(
      distance_label = ifelse(
        distance < 5280,
        paste0(round(distance, 0), " ft"),
        paste0(round(distance / 5280, 1), " mi")
      )
    )

  score_by_team <- score_by_location %>%
    group_by(team_name) %>%
    summarise(score = sum(score, na.rm = TRUE))

  googlesheets4::write_sheet(
    data = score_by_location,
    ss = "https://docs.google.com/spreadsheets/d/11DeQ3X3cR465WhVIjKQxcrddHtfAcJYknQncJ7mctTM/edit?usp=drive_link",
    sheet = "Sheet1"
  )

  googlesheets4::write_sheet(
    data = score_by_team,
    ss = "https://docs.google.com/spreadsheets/d/16jr22Ob9jWK0K6zhLtsw8zMTEnvelYZBFoj0Sz9buT0/edit?usp=drive_link",
    sheet = "Sheet1"
  )

  if (round_no == 1) {
    scores_cumulative <- score_by_team %>%
      group_by(team_name) %>%
      summarise(
        round1_score = sum(score, na.rm = T),
        cumulative_score = sum(score, na.rm = T)
      ) %>%
      arrange(desc(cumulative_score))
  }

  # if (round_no == 2) {
  #   score_round1 <-
  #     score_by_team
  #   read_csv(paste0(
  #     output_location,
  #     "Round ",
  #     "1",
  #     "/results by team.csv"
  #   )) %>%
  #     rename(round1_score = score)
  #
  #   scores_cumulative <- score_by_team %>%
  #     full_join(score_round1, by = c("team_name")) %>%
  #     rename(round2_score = score) %>%
  #     mutate(
  #       round1_score = ifelse(is.na(round1_score), 0, round1_score),
  #       round2_score = ifelse(is.na(round2_score), 0, round2_score)
  #     ) %>%
  #     group_by(team_name) %>%
  #     mutate(cumulative_score = sum(round1_score + round2_score, na.rm = T)) %>%
  #     select(team_name, round1_score, round2_score, cumulative_score) %>%
  #     arrange(desc(cumulative_score))
  # }
  #
  # if (round_no == 3) {
  #   score_round1 <- read_csv(paste0(
  #     output_location,
  #     "Round ",
  #     "1",
  #     "/results by team.csv"
  #   ))
  #   score_round2 <- read_csv(paste0(
  #     output_location,
  #     "Round ",
  #     "2",
  #     "/results by team.csv"
  #   ))
  #
  #   scores_cumulative <- score_by_team %>%
  #     rename(round3_score = score) %>%
  #     full_join(score_round1, by = c("team_name")) %>%
  #     rename(round1_score = score) %>%
  #     full_join(score_round2, by = c("team_name")) %>%
  #     rename(round2_score = score) %>%
  #     mutate(
  #       round1_score = ifelse(is.na(round1_score), 0, round1_score),
  #       round2_score = ifelse(is.na(round2_score), 0, round2_score),
  #       round3_score = ifelse(is.na(round3_score), 0, round3_score)
  #     ) %>%
  #     group_by(team_name) %>%
  #     mutate(
  #       cumulative_score = sum(
  #         round1_score + round2_score + round3_score,
  #         na.rm = T
  #       )
  #     ) %>%
  #     select(
  #       team_name,
  #       round1_score,
  #       round2_score,
  #       round3_score,
  #       cumulative_score
  #     ) %>%
  #     arrange(desc(cumulative_score))
  # }
}
