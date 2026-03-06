# 02_big5_prescraped_2019_2025_download.R
# Downloads pre-scraped FBref Big 5 player data
# Seasons: 2019-20 onward
# Output: single CSV file

library(worldfootballR)
library(dplyr)
library(purrr)
library(readr)

# ---------------------------------
# Seasons (season_end_year format)
# 2019-20 = 2020
# ---------------------------------

seasons_end <- 2020:2025   # adjust if 2025 not available yet

stat_types <- c(
  "standard",
  "shooting",
  "passing",
  "passing_types",
  "gca",
  "defense",
  "possession",
  "playing_time",
  "misc",
  "keepers",
  "keepers_adv"
)

all_data <- list()

for (sy in seasons_end) {
  for (st in stat_types) {
    
    message("Downloading season_end_year=", sy, " | stat_type=", st)
    
    df <- tryCatch({
      load_fb_big5_advanced_season_stats(
        season_end_year = sy,
        stat_type = st,
        team_or_player = "player"
      ) %>%
        mutate(
          season_end_year = sy,
          stat_type = st
        )
    }, error = function(e) {
      message("FAILED: ", sy, " | ", st)
      return(NULL)
    })
    
    if (!is.null(df)) {
      key <- paste(sy, st, sep = "_")
      all_data[[key]] <- df
    }
    
    Sys.sleep(1)
  }
}

# Combine all seasons and stat types
final_df <- bind_rows(all_data)

# Save to CSV
write_csv(final_df, "fbref_big5_players_2019_2025_all_stat_types.csv")

message("Done.")
message("Rows saved: ", nrow(final_df))