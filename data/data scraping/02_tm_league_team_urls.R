library(worldfootballR)
library(dplyr)
library(purrr)
library(readr)
library(tibble)

countries_tm <- c("England","Spain","Germany","Italy","France")
seasons_start <- 2018:2025

all_team_urls <- list()

for (cty in countries_tm) {
  for (sy in seasons_start) {
    
    message("Getting teams: ", cty, " | ", sy)
    
    teams <- tryCatch({
      urls <- tm_league_team_urls(country_name = cty, start_year = sy)
      
      tibble(
        team_url = urls,
        country = cty,
        start_year = sy
      )
    }, error = function(e) {
      message("FAILED: ", cty, " | ", sy, " | ", conditionMessage(e))
      NULL
    })
    
    if (!is.null(teams)) {
      all_team_urls[[paste(cty, sy, sep = "_")]] <- teams
    }
    
    Sys.sleep(2)
  }
}

team_urls_df <- bind_rows(all_team_urls)
write_csv(team_urls_df, "tm_big5_team_urls_2019_2024.csv")