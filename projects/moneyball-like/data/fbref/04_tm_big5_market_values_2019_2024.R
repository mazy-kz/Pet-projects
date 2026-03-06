# 04_tm_market_values_history_scrape.R
# Scrape Transfermarkt market value history for players (from /marktwertverlauf/)
# Input : tm_big5_player_urls_2019_2024.csv
# Output: tm_big5_player_market_values_history.csv (+ progress file)

library(readr)
library(dplyr)
library(stringr)
library(tibble)
library(purrr)
library(httr)
library(rvest)
library(xml2)

# -----------------------------
# CONFIG
# -----------------------------
INPUT_CSV  <- "tm_big5_player_urls_2019_2024.csv"
OUT_CSV    <- "tm_big5_player_market_values_history.csv"
PROGRESS_CSV <- "tm_big5_player_market_values_history_PROGRESS.csv"

SLEEP_SEC <- 3          # increase to 5-8 if you hit 429/403
SAVE_EVERY <- 200       # write progress every N players
DOMAIN <- "https://www.transfermarkt.com"  # you can swap to transfermarkt.us if needed

# -----------------------------
# HELPERS
# -----------------------------

# Ensure we only keep the actual URL (defensive: trims accidental ",England,2020,...")
clean_url <- function(x) {
  x <- str_trim(x)
  # keep only up to first comma if user accidentally has a whole row pasted in
  str_split_fixed(x, ",", 2)[, 1]
}

# Convert profile URL to market value history URL
to_mv_url <- function(profile_url) {
  # normalize domain + strip commas
  u <- clean_url(profile_url)
  u <- str_replace(u, "^https?://www\\.transfermarkt\\.[^/]+", DOMAIN)
  str_replace(u, "/profil/", "/marktwertverlauf/")
}

# Convert market value string like "€50.00m" / "€800k" to numeric EUR
parse_value_eur <- function(x) {
  x <- str_replace_all(x, "\\s+", "")
  x <- str_replace_all(x, "€", "")
  x <- str_replace_all(x, "\\.", "")  # 50.00m -> 5000? careful: we handle via regex below
  
  # safer approach:
  # accept raw like "50.00m", "800k", "1.5m" depending on locale
  raw <- str_replace_all(str_replace_all(str_trim(x), "€", ""), "\\s+", "")
  raw <- str_replace_all(raw, ",", ".")  # decimal comma -> dot
  
  mult <- case_when(
    str_detect(raw, "[mM]$") ~ 1e6,
    str_detect(raw, "[kK]$") ~ 1e3,
    TRUE ~ 1
  )
  num <- str_remove(raw, "[mMkK]$")
  suppressWarnings(as.numeric(num) * mult)
}

# Robust GET with browser-like headers
fetch_html <- function(url) {
  resp <- GET(
    url,
    add_headers(
      `User-Agent` = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
      `Accept-Language` = "en-US,en;q=0.9",
      `Referer` = DOMAIN
    ),
    timeout(30)
  )
  
  code <- status_code(resp)
  if (code != 200) stop("HTTP ", code)
  
  read_html(content(resp, as = "text", encoding = "UTF-8"))
}

# Parse the market value history table into standardized columns
parse_mv_history <- function(html) {
  tables <- html_elements(html, "table.items")
  if (length(tables) == 0) return(NULL)
  
  df_list <- html_table(tables, fill = TRUE)
  if (length(df_list) == 0) return(NULL)
  
  # pick the table that contains a "Market value" column (or German "Marktwert")
  idx <- which(map_lgl(df_list, ~ any(grepl("Market value|Marktwert", names(.x), ignore.case = TRUE))))
  df <- if (length(idx) > 0) df_list[[idx[1]]] else df_list[[1]]
  
  df <- as_tibble(df)
  names(df) <- make.names(names(df))
  
  # Common column patterns on Transfermarkt MV history pages:
  # Date / Datum, Market.value / Marktwert, Club / Verein, Age / Alter
  date_col <- names(df)[which(grepl("^Date$|^Datum$", names(df), ignore.case = TRUE))[1]]
  mv_col   <- names(df)[which(grepl("Market\\.value|Marktwert", names(df), ignore.case = TRUE))[1]]
  club_col <- names(df)[which(grepl("^Club$|^Verein$", names(df), ignore.case = TRUE))[1]]
  age_col  <- names(df)[which(grepl("^Age$|^Alter$", names(df), ignore.case = TRUE))[1]]
  
  # If any are missing, return raw table (still useful)
  if (is.na(date_col) || is.na(mv_col)) return(df)
  
  out <- tibble(
    date_raw = df[[date_col]],
    market_value_raw = df[[mv_col]],
    club = if (!is.na(club_col)) df[[club_col]] else NA_character_,
    age = if (!is.na(age_col)) df[[age_col]] else NA_character_
  )
  
  # Parse date if possible (Transfermarkt usually uses e.g. "Dec 16, 2019" or "16.12.2019")
  out <- out %>%
    mutate(
      date = suppressWarnings(as.Date(date_raw, format = "%b %d, %Y")),
      date = ifelse(is.na(date), suppressWarnings(as.Date(date_raw, format = "%d.%m.%Y")), date),
      date = as.Date(date, origin = "1970-01-01"),
      market_value_eur = parse_value_eur(market_value_raw)
    )
  
  out
}

# -----------------------------
# LOAD INPUT
# -----------------------------
player_urls_df <- read_csv(INPUT_CSV, show_col_types = FALSE)

if (!("player_url" %in% colnames(player_urls_df))) {
  stop("Input CSV must contain a column named 'player_url'. Check your file format.")
}

unique_players <- player_urls_df %>%
  mutate(player_url = clean_url(player_url)) %>%
  distinct(player_url) %>%
  filter(!is.na(player_url), player_url != "")

message("Unique player URLs: ", nrow(unique_players))

# If progress exists, skip already-done players
done_urls <- character(0)
if (file.exists(PROGRESS_CSV)) {
  done <- read_csv(PROGRESS_CSV, show_col_types = FALSE)
  if ("player_url" %in% colnames(done)) done_urls <- unique(done$player_url)
  message("Progress file found. Already done: ", length(done_urls))
}

# -----------------------------
# MAIN LOOP
# -----------------------------
results_accum <- list()
written_rows <- 0

for (i in seq_len(nrow(unique_players))) {
  
  purl <- unique_players$player_url[i]
  if (purl %in% done_urls) next
  
  mv_url <- to_mv_url(purl)
  message("MV: ", i, "/", nrow(unique_players), " | ", mv_url)
  
  out <- tryCatch({
    html <- fetch_html(mv_url)
    mv <- parse_mv_history(html)
    
    if (is.null(mv) || nrow(mv) == 0) {
      NULL
    } else {
      mv %>%
        mutate(
          player_url = purl,
          mv_url = mv_url
        )
    }
  }, error = function(e) {
    message("FAILED: ", mv_url, " | ", conditionMessage(e))
    NULL
  })
  
  results_accum[[length(results_accum) + 1]] <- out
  Sys.sleep(SLEEP_SEC)
  
  # Save progress every N players
  if ((i %% SAVE_EVERY) == 0) {
    chunk <- bind_rows(results_accum)
    if (nrow(chunk) > 0) {
      if (!file.exists(PROGRESS_CSV)) {
        write_csv(chunk, PROGRESS_CSV)
      } else {
        write_csv(bind_rows(read_csv(PROGRESS_CSV, show_col_types = FALSE), chunk), PROGRESS_CSV)
      }
      written_rows <- written_rows + nrow(chunk)
      message("Progress saved. Added rows: ", nrow(chunk), " | Total added (this run): ", written_rows)
    }
    results_accum <- list()
  }
}

# Final save
final_chunk <- bind_rows(results_accum)
if (nrow(final_chunk) > 0) {
  if (!file.exists(PROGRESS_CSV)) {
    write_csv(final_chunk, PROGRESS_CSV)
  } else {
    write_csv(bind_rows(read_csv(PROGRESS_CSV, show_col_types = FALSE), final_chunk), PROGRESS_CSV)
  }
}

# Write final output (dedup)
all_out <- read_csv(PROGRESS_CSV, show_col_types = FALSE) %>%
  distinct(player_url, mv_url, date_raw, market_value_raw, club, age, .keep_all = TRUE)

write_csv(all_out, OUT_CSV)

message("DONE. Final saved: ", OUT_CSV)
message("Rows: ", nrow(all_out))
length(all_rows)
length(PROGRESS_CSV)
ls()
write_csv(market_values_df, "tm_big5_player_market_values_history.csv")


library(dplyr)
library(readr)

market_values_df <- bind_rows(all_rows)

nrow(market_values_df)
head(market_values_df)

write_csv(market_values_df, "tm_big5_player_market_values_history.csv")

file.exists("tm_big5_player_market_values_history.csv")