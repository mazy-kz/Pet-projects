library(readr)
library(dplyr)
library(stringr)

# --- CONFIG ---
setwd("C:\Users\User\Desktop\projects\Portfolio\Pet-projects\moneyball-like\data\data scraping")
INPUT_CSV    <- "tm_big5_player_urls_2019_2024.csv"
PROGRESS_CSV <- "tm_big5_player_market_values_history_PROGRESS.csv"
TRACKER_FILE <- "done_players_2018_2025.txt" # Tracks progress for this specific scrape

# ---------------------------------------------------------
# 1. LOAD INPUT & EXTRACT CLEAN URLs
# ---------------------------------------------------------
all_data <- read_csv(INPUT_CSV, show_col_types = FALSE)
raw_lines <- unique(all_data$player_url)

# The input has format: "https://.../spieler/123,England,2019,https://..."
# This extracts ONLY the first link and removes any existing season ID
base_urls <- sapply(raw_lines, function(x) str_split(x, ",")[[1]][1])
base_urls_clean <- unique(unname(str_remove(base_urls, "/saison_id/\\d{4}$")))

# ---------------------------------------------------------
# 2. CHECK PROGRESS (Resume Logic)
# ---------------------------------------------------------
if (file.exists(TRACKER_FILE)) {
  done_urls <- readLines(TRACKER_FILE, warn = FALSE)
  urls_to_process <- base_urls_clean[!(base_urls_clean %in% done_urls)]
  message("Resuming: ", length(urls_to_process), " players remaining for 2018 & 2025.")
} else {
  urls_to_process <- base_urls_clean
  file.create(TRACKER_FILE)
  message("Starting fresh. All players queued for 2018 and 2025.")
}

# ---------------------------------------------------------
# 3. THE LOOP (APPENDING EXACT 5-COLUMN DATA)
# ---------------------------------------------------------
for (i in seq_along(urls_to_process)) {
  p_url_base <- urls_to_process[i]
  
  # Target exactly the 2018 (starts 2017) and 2025 (starts 2024) seasons
  p_url_2018 <- paste0(p_url_base, "/saison_id/2017")
  p_url_2025 <- paste0(p_url_base, "/saison_id/2024")
  
  message(sprintf("[%d / %d] Fetching 2018 & 2025 for: %s", 
                  i, length(urls_to_process), p_url_base))
  
  # Call your API function for both seasons
  mv_data_2018 <- extract_mv_api(p_url_2018)
  mv_data_2025 <- extract_mv_api(p_url_2025)
  
  # Combine the results (bind_rows safely ignores if a player didn't exist in 2018)
  mv_data_combined <- bind_rows(mv_data_2018, mv_data_2025)
  
  # Append to your main CSV in the exact 5-column format
  if (!is.null(mv_data_combined) && nrow(mv_data_combined) > 0) {
    write_csv(mv_data_combined, PROGRESS_CSV, append = TRUE, col_names = FALSE)
  }
  
  # Mark player as done in the tracker file so they are skipped if you restart
  write(p_url_base, file = TRACKER_FILE, append = TRUE)
  
  Sys.sleep(runif(1, 1.5, 2.5)) 
}

message("Scraping for 2018 and 2025 complete!")