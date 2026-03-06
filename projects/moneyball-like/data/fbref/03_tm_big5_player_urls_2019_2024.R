library(worldfootballR)
library(dplyr)
library(purrr)
library(readr)
library(tibble)

# Load team URLs you already created
team_urls_df <- read_csv("tm_big5_team_urls_2019_2024.csv")

all_player_urls <- list()

for (i in 1:nrow(team_urls_df)) {
  
  team_url <- team_urls_df$team_url[i]
  country  <- team_urls_df$country[i]
  season   <- team_urls_df$start_year[i]
  
  message("Processing: ", team_url)
  
  players <- tryCatch({
    
    urls <- tm_team_player_urls(team_url = team_url)
    
    tibble(
      player_url = urls,
      country = country,
      start_year = season,
      team_url = team_url
    )
    
  }, error = function(e) {
    message("FAILED: ", team_url, " | ", conditionMessage(e))
    NULL
  })
  
  if (!is.null(players)) {
    all_player_urls[[i]] <- players
  }
  
  Sys.sleep(2)
}

player_urls_df <- bind_rows(all_player_urls)

write_csv(player_urls_df, "tm_big5_player_urls_2019_2024.csv")

message("Saved: tm_big5_player_urls_2019_2024.csv")
message("Total players: ", nrow(player_urls_df))