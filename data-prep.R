# data-prep.R
# Filed Under: MLS strikers
# Pulls 2025 MLS regular-season player shooting data from the American Soccer
# Analysis (ASA) public API: https://app.americansocceranalysis.com/api/v1/
# No key required. Requests are spaced 2 s apart.
#
# Keeps attacking players (ASA general_position ST, W, AM) so the striker
# definition used in analysis.Rmd can be checked against wingers and attacking
# midfielders. Splits penalties out so non-penalty figures can be computed.
# Assigns each player a primary team (most minutes) and that team's conference.
# Also writes team totals (points, goals, xG, penalties split out) for the
# team-context analysis.
#
# Output: data/mls-attackers-2025.csv
#         data/mls-teams-2025.csv

library(tidyverse)
library(httr)
library(jsonlite)

API    <- "https://app.americansocceranalysis.com/api/v1/mls"
SEASON <- "2025"
STAGE  <- "Regular Season"

asa_get <- function(endpoint, ...) {
  resp <- GET(paste0(API, endpoint), query = list(...), timeout(120))
  stop_for_status(resp)
  Sys.sleep(2)
  fromJSON(content(resp, as = "text", encoding = "UTF-8"))
}

# ── Fetch ──────────────────────────────────────────────────────────────────

message("Fetching ASA data for ", SEASON, " ", STAGE)

xg_all <- asa_get("/players/xgoals",
                  season_name = SEASON, stage_name = STAGE,
                  split_by_teams = "false")

xg_pen <- asa_get("/players/xgoals",
                  season_name = SEASON, stage_name = STAGE,
                  split_by_teams = "false", shot_pattern = "Penalty")

xg_by_team <- asa_get("/players/xgoals",
                      season_name = SEASON, stage_name = STAGE,
                      split_by_teams = "true")

goals_added <- asa_get("/players/goals-added",
                       season_name = SEASON, stage_name = STAGE,
                       split_by_teams = "false")

team_xg <- asa_get("/teams/xgoals",
                   season_name = SEASON, stage_name = STAGE)

team_xg_pen <- asa_get("/teams/xgoals",
                       season_name = SEASON, stage_name = STAGE,
                       shot_pattern = "Penalty")

players <- asa_get("/players")
teams   <- asa_get("/teams")

# ── Conference alignment, 2025 ─────────────────────────────────────────────
# Keyed on ASA team_short_name. 15 teams per conference.

conferences <- tribble(
  ~team_short_name, ~conference,
  "Atlanta",        "East",
  "Charlotte",      "East",
  "Chicago",        "East",
  "Cincinnati",     "East",
  "Columbus",       "East",
  "D.C. United",    "East",
  "Miami",          "East",
  "Montréal",       "East",
  "Nashville",      "East",
  "New England",    "East",
  "New York",       "East",
  "New York City",  "East",
  "Orlando City",   "East",
  "Philadelphia",   "East",
  "Toronto",        "East",
  "Austin",         "West",
  "Colorado",       "West",
  "Dallas",         "West",
  "Houston",        "West",
  "Kansas City",    "West",
  "LA Galaxy",      "West",
  "Los Angeles FC", "West",
  "Minnesota",      "West",
  "Portland",       "West",
  "Salt Lake",      "West",
  "San Diego",      "West",
  "San Jose",       "West",
  "Seattle",        "West",
  "St. Louis",      "West",
  "Vancouver",      "West"
)

# ── Primary team ───────────────────────────────────────────────────────────

primary_team <- as_tibble(xg_by_team) %>%
  group_by(player_id) %>%
  mutate(n_teams = n()) %>%
  slice_max(minutes_played, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  left_join(as_tibble(teams), by = "team_id") %>%
  left_join(conferences, by = "team_short_name") %>%
  select(player_id, team = team_name, conference, n_teams)

stopifnot(!any(is.na(primary_team$conference)))

# ── Penalties ──────────────────────────────────────────────────────────────

penalties <- as_tibble(xg_pen) %>%
  select(player_id,
         pen_shots = shots,
         pen_goals = goals,
         pen_xg    = xgoals)

# ── Goals added (g+), summed across action types ───────────────────────────

g_plus <- tibble(
  player_id = goals_added$player_id,
  g_plus    = map_dbl(goals_added$data, ~ round(sum(.x$goals_added_above_avg), 4))
)

# ── Assemble ───────────────────────────────────────────────────────────────

attackers <- as_tibble(xg_all) %>%
  filter(general_position %in% c("ST", "W", "AM")) %>%
  left_join(as_tibble(players) %>% select(player_id, player = player_name, birth_date),
            by = "player_id") %>%
  left_join(primary_team, by = "player_id") %>%
  left_join(penalties,    by = "player_id") %>%
  left_join(g_plus,       by = "player_id") %>%
  mutate(across(c(pen_shots, pen_goals, pen_xg), ~ replace_na(.x, 0))) %>%
  select(player_id, player, birth_date, position = general_position,
         team, conference, n_teams,
         minutes = minutes_played,
         shots, shots_on_target, goals, xg = xgoals,
         pen_shots, pen_goals, pen_xg,
         key_passes, assists = primary_assists, xa = xassists,
         g_plus) %>%
  arrange(desc(goals))

stopifnot(!any(duplicated(attackers$player_id)))

# ── Team totals ────────────────────────────────────────────────────────────

team_totals <- as_tibble(team_xg) %>%
  select(team_id, games = count_games, points,
         goals_for, xg_for = xgoals_for) %>%
  left_join(as_tibble(team_xg_pen) %>%
              select(team_id, pen_goals_for = goals_for, pen_xg_for = xgoals_for),
            by = "team_id") %>%
  left_join(as_tibble(teams), by = "team_id") %>%
  left_join(conferences, by = "team_short_name") %>%
  select(team = team_name, conference, games, points,
         goals_for, xg_for, pen_goals_for, pen_xg_for) %>%
  arrange(desc(points))

stopifnot(nrow(team_totals) == 30, !any(is.na(team_totals$conference)))

# ── Write ──────────────────────────────────────────────────────────────────

dir.create("data", showWarnings = FALSE)
write_csv(attackers, "data/mls-attackers-2025.csv")

message(sprintf("Wrote data/mls-attackers-2025.csv: %d players (%s)",
                nrow(attackers),
                paste(names(table(attackers$position)), table(attackers$position),
                      sep = " ", collapse = ", ")))

write_csv(team_totals, "data/mls-teams-2025.csv")
message(sprintf("Wrote data/mls-teams-2025.csv: %d teams", nrow(team_totals)))
