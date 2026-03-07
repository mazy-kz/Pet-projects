library(readr)
library(dplyr)
library(stringr)

# --- CONFIG ---
setwd("C:/Users/User/Desktop/projects/Portfolio/Pet-projects/projects/moneyball-like/data/fbref")
INPUT_CSV    <- "tm_big5_player_urls_2019_2024.csv"
PROGRESS_CSV <- "tm_big5_player_market_values_history_PROGRESS.csv"

# 1. Load Input
all_data <- read_csv(INPUT_CSV, show_col_types = FALSE)
unique_urls <- unique(all_data$player_url)

# 2. Load Progress - FORCE HEADERS
if (file.exists(PROGRESS_CSV) && file.size(PROGRESS_CSV) > 0) {
  # We read with col_names = FALSE because your file currently uses data as headers
  done_data <- read_csv(PROGRESS_CSV, col_names = FALSE, show_col_types = FALSE)
  
  # Manually name the first column so we can match it
  colnames(done_data)[1] <- "player_url"
  
  done_urls <- unique(as.character(done_data$player_url))
  
  # Match logic
  urls_to_process <- unique_urls[!(unique_urls %in% done_urls)]
  num_done <- length(done_urls)
  
  message("SUCCESS: Logic forced headers and found ", num_done, " players.")
} else {
  urls_to_process <- unique_urls
  num_done <- 0
  message("Starting fresh.")
}

# ---------------------------------------------------------
# 3. THE LOOP (SAVE EVERY 1 WITH HEADERS TURNED OFF)
# ---------------------------------------------------------
for (i in seq_along(urls_to_process)) {
  p_url <- urls_to_process[i]
  
  message(sprintf("[%d / %d] Total Progress: %d / %d", 
                  i, length(urls_to_process), (num_done + i), length(unique_urls)))
  
  mv_data <- extract_mv_api(p_url) # Use the API function from earlier
  
  if (!is.null(mv_data) && nrow(mv_data) > 0) {
    # CRITICAL: We set col_names = FALSE so we don't keep adding 
    # the word 'player_url' into the middle of your data file
    write_csv(mv_data, PROGRESS_CSV, append = TRUE, col_names = FALSE)
  }
  
  Sys.sleep(runif(1, 1.5, 2.5))
}