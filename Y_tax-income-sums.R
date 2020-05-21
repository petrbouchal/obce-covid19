library(tidyverse)
library(statnipokladna)

source("shared.R")
options(scipen = 100)

prijmy <- read_rds("data-processed/budgets_druhove_prijmy_annual.rds") %>%
  filter(per_yr == "2019")
prijmy_indikatory <- read_rds("data-processed/budget_for_scenarios.rds") %>%
  filter(per_yr == 2019)

prijmy_indikatory %>%
  ungroup() %>%
  count(wt = rozp_p_rud/1e9)

prijmy %>%
  sp_add_codelist(polozka) %>%
  filter(trida == "Daňové příjmy",
         ico %in% ico_obce,
         ) %>%
  count(
    seskupeni,
    podseskupeni,
    wt = budget_spending/1e9) %>%
  mutate(n = round(n, 2)) %>% View()
