library(tidyverse)
library(statnipokladna)

source("shared.R")

# this file created in 5_budget-balance.R
spending <- read_rds("data-processed/budgets_bilance.rds") %>%
  rename(rozp_v_celkem = Výdaje) %>% select(-Příjmy, -bilance, -bilance_rel)

spending %>% count(per_yr)

income00 <- read_rds("data-processed/budgets_druhove_prijmy_annual.rds")

# income00 %>% group_by(per_yr) %>% n_distinct(ico)

polozka %>%
  filter(druh == "Příjmy") %>%
  count(trida, seskupeni)

income0 <- income00 %>%
  sp_add_codelist(polozka %>% select(-ends_with("_nazev"), -podseskupeni))

income <- income0 %>%
  # konsolidace
  filter(!kon_pol & ico %in% ico_obce) %>%
  # vyrobit novou kategorizaci prijmu
  mutate(kat_new = case_when(polozka %in% polozky_rud ~ "rud",
                             trida == "Daňové příjmy" ~ "other_tax",
                             trida == "Nedaňové příjmy" ~ "non_tax",
                             trida == "Přijaté transfery" ~ "transfers",
                             trida == "Kapitálové příjmy" ~ "capital")) %>%
  # secist
  group_by(ico, per_yr, kat_new) %>%
  summarise(rozp_p = sum(budget_spending)) %>%
  # preklopit do dlouheho formatu
  pivot_wider(names_from = kat_new, values_from = rozp_p,
              names_prefix = "rozp_p_", values_fill = list(rozp_p = 0)) %>%
  # spocitat celkove vydaje
  mutate(rozp_p_celkem = rozp_p_rud + rozp_p_non_tax + rozp_p_other_tax + rozp_p_transfers + rozp_p_capital)

income %>% group_by(per_yr) %>% count(per_yr, .drop = T)

# use this before the pivot call above to check that all items have a kat_new
# table(income$kat_new, useNA = "always")

rozp <- income %>%
  left_join(spending) %>%
  mutate(bilance = rozp_p_celkem - rozp_v_celkem)

rozp %>% ungroup() %>% count(per_yr)
rozp %>% ungroup() %>% count(kraj, per_yr) %>% spread(per_yr, n)

write_rds(rozp, "data-processed/budget_for_scenarios.rds")
