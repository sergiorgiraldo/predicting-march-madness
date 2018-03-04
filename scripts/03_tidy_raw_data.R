# Script to predict win likelihood for college basketball games based on Ken Pomeroy ratings
# by Sam Firke - 2016-2018

#### Data cleaning  -------------------------------------------------------------------------------


library(pacman)
p_load(caret, MASS) # load ML packages that unfortunately mask dplyr functions
p_load(dplyr, readr, stringr, caret, ggplot2, tidyr)

# read previous years of Ken Pomeroy data
kp_raw <- read_csv("data/model_inputs/ken_pom.csv") %>%
  select(team_name = team, year, EM = adj_EM, adj_off = adj_offensive_efficiency, adj_def = adj_defensive_efficiency, adj_tempo)

# read preseason rankings, clean names to match Pomeroy
preseas <- read_csv("data/model_inputs/mens_cbb_preseason_rankings.csv") %>%
  # recode names to match KP
  # okay that KP doesn't have NYU, who was ranked in 1964
  mutate(team_name = gsub("State", "St.", team),
         team_name = recode(team_name, "Louisiana" = "Louisiana Lafayette", "Loyola-Chicago" = "Loyola Chicago", "Miami (FL)" = "Miami FL", "NC St." = "North Carolina St."),
         team_name = gsub(" \\([A-Z][A-Z]\\)", "", team_name)) %>%
  select(-team) %>%
  rename(pre_seas_rank = rank)

kp_dat <- left_join(kp_raw, preseas) %>%
  mutate(ranked = as.factor(ifelse(is.na(pre_seas_rank), "NO", "YES"))) %>%
  rename(pre_seas_rank_all = pre_seas_rank) %>%
  
  # impute rank for all unranked teams.  This is rough.
  # Could I build a model to predict preseason rank from adj_EM and then use that to backfill this?
  # Would be difficult, as only ranks 1-25 are in the data.
  # Would be nice to explore sensitivity of this parameter
  mutate(pre_seas_rank_all = tidyr::replace_na(pre_seas_rank_all, 30))


# read training data - regular season results
treat_past_results <- function(filename){
  read_csv(filename) %>%
    clean_names() %>%
    rename(year = season, wteam = w_team_id, lteam = l_team_id) %>%
    mutate(lower_team = pmin(wteam, lteam), # lower refers to ID number
           higher_team = pmax(wteam, lteam),
           lower_team_wins = ifelse(lower_team == wteam, "YES", "NO")) # the outcome we'll predict
}

past_reg_results <- read_csv("data/kaggle/RegularSeasonCompactResults.csv") %>%
  clean_names() %>%
  rename(year = season, wteam = w_team_id, lteam = l_team_id) %>%
  filter(year > 2001) %>% # don't have Pomeroy ratings before this year


# add in NCAA tourney results from 2003-2012
past_tourney_results <- read_csv("data/kaggle/NCAATourneyCompactResults.csv") %>%
  clean_names() %>%
  rename(year = season, wteam = w_team_id, lteam = l_team_id) %>%
  filter(year < rev(sort(unique(.$year)))[4]) %>% # per contest rules, since the first round of predictions includes most recent 4 years of tourney games, don't train on those
  mutate(lower_team = pmin(wteam, lteam), # lower refers to ID number
         higher_team = pmax(wteam, lteam),
         lower_team_wins = ifelse(lower_team == wteam, "YES", "NO"))

all_past_results <- bind_rows(past_reg_results, past_tourney_results)

# read team names crosswalk
team_crosswalk <- read_csv("data/ken_pom_to_kaggle_crosswalk.csv")

# Join Pomeroy data to past data to make training set
kp_dat <- inner_join(kp_dat, team_crosswalk)

### Two functions that take a matchup (team1, team2, year) and merge in the correct predictor values, then calculate differences for predicting -----------
# Done as functions since the blank matchups to predict on will also need this formatting

# joins in pomeroy data to a df with year, lower_team, higher_team
add_kp_data <- function(dat){
  dat %>%
    left_join(., kp_dat, by = c("year", "lower_team" = "team_id")) %>%
    rename(lower_team_name = team_name, lower_EM = EM, lower_adj_off = adj_off, lower_adj_def = adj_def, lower_adj_tempo = adj_tempo, lower_pre_seas_rank_all = pre_seas_rank_all, lower_ranked = ranked) %>%
    left_join(., kp_dat, by = c("year", "higher_team" = "team_id")) %>%
    rename(higher_team_name = team_name, higher_EM = EM, higher_adj_off = adj_off, higher_adj_def = adj_def, higher_adj_tempo = adj_tempo, higher_pre_seas_rank_all = pre_seas_rank_all, higher_ranked = ranked)
}

# Create differential variables for prediction
create_vars_for_prediction <- function(dat){
  dat %>%
    mutate(EM_diff = lower_EM - higher_EM,
           adj_off_diff = lower_adj_off - higher_adj_off,
           adj_def_diff = lower_adj_def - higher_adj_def,
           adj_tempo_diff = lower_adj_tempo - higher_adj_tempo,
           pre_seas_rank_diff = lower_pre_seas_rank_all - higher_pre_seas_rank_all)
            # there are few cases where a very weak team played games but isn't in the Pomeroy table
}

# Apply functions to prep data for prediction
past_dat <- all_past_results %>%
  add_kp_data() %>%
  create_vars_for_prediction() %>%
  mutate(lower_team_wins = as.factor(lower_team_wins),
         lower_team_court_adv = as.factor(ifelse(lower_team == wteam,
                                                 wloc,
                                                 plyr::mapvalues(wloc, from = c("A", "H", "N"), to = c("H", "A", "N"))))) %>% # reframe home field advantage
  dplyr::select(lower_team_wins, contains("diff"), lower_team_court_adv, contains("rank"), -contains("all")) %>% # drop unneeded vars
  filter(complete.cases(.)) %>%
  as.data.frame()

# You're now ready to run models on the data.frames currently in memory from this script!