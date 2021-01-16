source("shared.R")
library(tibble)
library(tidyr)
library(dplyr)
library(forcats)
library(stringr)

indik_base <- read_parquet("data-processed/indikatory.parquet")

# Set scenarios -----------------------------------------------------------

scenarios <- tribble(~scenario , ~spending_change, ~rud_change, ~dph_change, ~borrowing_ratio, ~scenario_name,
                     "R0",    1.00, 1 - 0.0, 1 - 0.00, 0,   "konstantní příjmy a výdaje, konstantní dluh",
                     "R0-D33-res", 1.00, 1 - 0.0, 1 - 0.33, 0,   "jen propad DPH o 33 %, konstantní dluh",
                     "R0-D66-res", 1.00, 1 - 0.0, 1 - 0.66, 0,   "jen propad DPH o 66 %, konstantní dluh",
                     "R10-D0-res",  1.00, 1 - 0.1, 1 - 0.10, 0,   "RUD ↓ 10 %, konstantní dluh",
                     "R10-D0-debt",  1.00, 1 - 0.1, 1 - 0.10, 1,   "RUD ↓ 10 %, nárůst dluhu o saldo",
                     "R10-D0-mix",  1.00, 1 - 0.1, 1 - 0.10, 0.5, "RUD ↓ 10 %, nárůst dluhu o půl salda",
                     "R20-D0-res",  1.00, 1 - 0.2, 1 - 0.20, 0,   "RUD ↓ 20 %, konstantní dluh",
                     "R20-D0-mix",  1.00, 1 - 0.2, 1 - 0.20, 0.5, "RUD ↓ 20 %, nárůst dluhu o půl salda",
                     "R20-D0-debt",  1.00, 1 - 0.2, 1 - 0.20, 1,   "RUD ↓ 20 %, nárůst dluhu o saldo",
                     "R30-D0-res",  1.00, 1 - 0.3, 1 - 0.30, 0,   "RUD ↓ 30 %, konstantní dluh",
                     "R30-D0-mix",  1.00, 1 - 0.3, 1 - 0.30, 0.5, "RUD ↓ 30 %, nárůst dluhu o půl salda",
                     "R30-D0-debt",  1.00, 1 - 0.3, 1 - 0.30, 1,   "RUD ↓ 30 %, nárůst dluhu o saldo",
                     "R10-D33-res", 1.00, 1 - 0.1, 1 - 0.33, 0,   "DPH ↓ 33 %, zbytek RUD ↓ 10 %, konstantní dluh",
                     "R10-D33-debt", 1.00, 1 - 0.1, 1 - 0.33, 1,   "DPH ↓ 33 %, zbytek RUD ↓ 10 %, nárůst dluhu o saldo",
                     "R10-D33-mix", 1.00, 1 - 0.1, 1 - 0.33, 0.5, "DPH ↓ 33 %, zbytek RUD ↓ 10 %, nárůst dluhu o půl salda",
                     "R20-D33-res", 1.00, 1 - 0.2, 1 - 0.33, 0,   "DPH ↓ 33 %, zbytek RUD ↓ 20 %, konstantní dluh",
                     "R20-D33-mix", 1.00, 1 - 0.2, 1 - 0.33, 0.5, "DPH ↓ 33 %, zbytek RUD ↓ 20 %, nárůst dluhu o půl salda",
                     "R20-D33-debt", 1.00, 1 - 0.2, 1 - 0.33, 1,   "DPH ↓ 33 %, zbytek RUD ↓ 20 %, nárůst dluhu o saldo",
                     "R30-D33-res", 1.00, 1 - 0.3, 1 - 0.33, 0,   "DPH ↓ 33 %, zbytek RUD ↓ 30 %, konstantní dluh",
                     "R30-D33-mix", 1.00, 1 - 0.3, 1 - 0.33, 0.5, "DPH ↓ 33 %, zbytek RUD ↓ 30 %, nárůst dluhu o půl salda",
                     "R30-D33-debt", 1.00, 1 - 0.3, 1 - 0.33, 1,   "DPH ↓ 33 %, zbytek RUD ↓ 30 %, nárůst dluhu o saldo",
                     "R10-D66-res", 1.00, 1 - 0.1, 1 - 0.66, 0,   "DPH ↓ 66 %, zbytek RUD ↓ 10 %, konstantní dluh",
                     "R10-D66-debt", 1.00, 1 - 0.1, 1 - 0.66, 1,   "DPH ↓ 66 %, zbytek RUD ↓ 10 %, nárůst dluhu o saldo",
                     "R10-D66-mix", 1.00, 1 - 0.1, 1 - 0.66, 0.5, "DPH ↓ 66 %, zbytek RUD ↓ 10 %, nárůst dluhu o půl salda",
                     "R20-D66-res", 1.00, 1 - 0.2, 1 - 0.66, 0,   "DPH ↓ 66 %, zbytek RUD ↓ 20 %, konstantní dluh",
                     "R20-D66-mix", 1.00, 1 - 0.2, 1 - 0.66, 0.5, "DPH ↓ 66 %, zbytek RUD ↓ 20 %, nárůst dluhu o půl salda",
                     "R20-D66-debt", 1.00, 1 - 0.2, 1 - 0.66, 1,   "DPH ↓ 66 %, zbytek RUD ↓ 20 %, nárůst dluhu o saldo",
                     "R30-D66-res", 1.00, 1 - 0.3, 1 - 0.66, 0,   "DPH ↓ 66 %, zbytek RUD ↓ 30 %, konstantní dluh",
                     "R30-D66-mix", 1.00, 1 - 0.3, 1 - 0.66, 0.5, "DPH ↓ 66 %, zbytek RUD ↓ 30 %, nárůst dluhu o půl salda",
                     "R30-D66-debt", 1.00, 1 - 0.3, 1 - 0.66, 1,   "DPH ↓ 66 %, zbytek RUD ↓ 30 %, nárůst dluhu o saldo",
                     )
scenario_years <- 2020:2022

# edit scenarios_by_year to make year-specific changes

scenarios_by_year <- crossing(per_yr = scenario_years, scenarios) %>%
  mutate(dph_change = if_else(per_yr == 2020, dph_change, rud_change))

# Likviditu nepujde projektovat, protože některé dluhy mohou být krátkodobé
# leda bychom předpokládali nějaký podíl
# podíl cizích zdrojů: pokud se zvyšuje i dluh, zvyušují se i cizí zdroje


write_parquet(scenarios, "data-processed/scenarios.parquet")
write_parquet(scenarios_by_year, "data-processed/scenarios_by_year.parquet")

# Project -----------------------------------------------------------------

ico_scenare_years <- crossing(per_yr = scenario_years,
                              # FIXME: filter out municipalities invalid in 2019
                              ico = ico_obce)

indik_scenarios <- indik_base %>%
  ungroup() %>%
  filter(per_yr > 2015) %>%
  bind_rows(ico_scenare_years) %>%
  crossing(scenario = unique(scenarios_by_year$scenario)) %>%
  left_join(scenarios_by_year) %>%
  replace_na(list(rud_change = 1, spending_change = 1, dph_change = 1)) %>%
  group_by(scenario, ico) %>%
  arrange(per_yr) %>%
  fill(starts_with("rozp_"), kratkodobe_zavazky, aktiva_brutto, obezna_aktiva,
       dluh, cizi_zdroje_netto, kratkodoby_fin_majetek) %>%
  mutate(rozp_p_rud_dph = rozp_p_rud_dph * dph_change,
         rozp_p_rud_exc_dph = rozp_p_rud_exc_dph * rud_change,
         rozp_p_rud = rozp_p_rud_dph + rozp_p_rud_exc_dph,
         rozp_p_celkem = rozp_p_rud + rozp_p_other_tax + rozp_p_non_tax +
           rozp_p_transfers + rozp_p_capital,
         rozp_v_celkem = rozp_v_celkem * spending_change,
         bilance = rozp_p_celkem - rozp_v_celkem,
         bilance_rel = bilance/rozp_v_celkem,
         saldo_to_sum = if_else(per_yr > 2019 & bilance < 0, abs(bilance), 0),
         saldo_cum = cumsum(saldo_to_sum),
         dluh = dluh + saldo_cum * borrowing_ratio,
         cizi_zdroje_netto = cizi_zdroje_netto + saldo_cum * borrowing_ratio,
         cash_drain_to_sum = if_else(per_yr > 2019 & bilance < 0,
                                     abs(bilance) * (1 - borrowing_ratio),
                                     0),
         cash_drain_cum = cumsum(cash_drain_to_sum),
         kratkodoby_fin_majetek = if_else(kratkodoby_fin_majetek - cash_drain_cum < 0,
                                          0,
                                          kratkodoby_fin_majetek - cash_drain_cum),
         financing_shortfall = if_else(kratkodoby_fin_majetek < cash_drain_cum,
                                       kratkodoby_fin_majetek - cash_drain_cum,
                                       0))

indik_for_calc <- bind_rows(indik_base %>%
                              mutate(scenario = "R",
                                     scenario_name = "Historie"),
                            indik_scenarios) %>%
  add_obce_meta()

table(indik_for_calc$typobce)

indik_for_calc %>%
  ungroup() %>%
  count(scenario, per_yr) %>%
  spread(scenario, n)

indik_for_calc %>%
  ungroup() %>%
  count(kraj, per_yr) %>%
  spread(per_yr, n)

indik_for_calc %>%
  ungroup() %>%
  count(typobce, per_yr) %>%
  spread(per_yr, n)

# Calculate ---------------------------------------------------------------

indikatory <- indik_for_calc %>%
  # calculate for each scenario in each orgs timeseries
  group_by(scenario, ico) %>%
  # order to get correct lag info
  arrange(per_yr) %>%
  # calculate rolling income average and balance
  mutate(podil_cizich_zdroju = cizi_zdroje_netto/aktiva_brutto,
         likvidita = obezna_aktiva/kratkodobe_zavazky,
         p0 = rozp_p_celkem,
         p1 = lag(rozp_p_celkem, 1),
         p2 = lag(rozp_p_celkem, 2),
         p3 = lag(rozp_p_celkem, 3),
         prijmy_last4 = (p0 + p1 + p2 + p3)/4,
         bilance_rel = bilance/rozp_v_celkem,
         rozp_odp_1yr = dluh/rozp_p_celkem,
         rozp_odp = dluh/prijmy_last4) %>%
  # drop years which were there only to make lag-based calcs possible
  filter(!(scenario != "R" & per_yr < 2020)) %>%
  ungroup() %>%
  mutate(katobyv_nazev = fct_reorder(katobyv_nazev, as.integer(katobyv_id)),
         scenario_name = fct_reorder(scenario_name, as.numeric(factor(scenario)))) %>%
  # reorder columns for better manual inspection
  select(per_yr, scenario, ico, orgs_ucjed_nazev, rozp_p_celkem, rozp_v_celkem,
         bilance, saldo_cum, dluh, rozp_odp, everything()) %>%
  mutate(typobce = as.factor(typobce) %>%
           fct_relevel(c("Krajská města a Praha",
                         "S rozšířenou působností",
                         "S pověřeným obecním úřadem",
                         "Běžná obec")),
         kraj_short = fct_relabel(kraj_nazev,
                                  ~str_remove(.x, "\\s?Kraj\\s?")) %>%
           fct_recode(`Praha` = "Hlavní Město Praha"))

indikatory %>%
  count(scenario, per_yr) %>%
  spread(scenario, n)

indikatory %>%
  count(per_yr, kraj) %>%
  spread(per_yr, n)

names(indikatory)

write_parquet(indikatory, "data-processed/scenare_vysledky.parquet")

# Check -------------------------------------------------------------------

indikatory %>%
  filter(per_yr == 2020 & bilance < 0) %>%
  # View() %>%
  filter(TRUE)


# Basic overview of results -----------------------------------------------

## share of obce breaking budget rule

indikatory %>%
  filter(per_yr %in% 2019:2022) %>%
  ungroup() %>%
  count(scenario, per_yr, wt = (rozp_odp > .6)/n()) %>%
  spread(per_yr, n) %>% View()

## share of obce having negative balance

indikatory %>%
  filter(per_yr %in% 2019:2022) %>%
  ungroup() %>%
  # count(scenario, per_yr, wt = (bilance < 0)/n()) %>%
  count(scenario, per_yr, wt = (bilance < 0 & abs(bilance) > kratkodoby_fin_majetek)/n()) %>%
  spread(per_yr, n)

indikatory %>%
  filter(per_yr %in% 2019:2022) %>%
  group_by(scenario, per_yr) %>%
  filter(bilance < 0) %>%
  count() %>%
  spread(scenario, n)

