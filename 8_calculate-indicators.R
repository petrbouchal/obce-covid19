library(tidyverse)

source("shared.R")

rozvaha <- read_rds("data-processed/rozvaha.rds") %>%
  ungroup() %>%
  mutate(per_yr = as.numeric(per_yr))
rozp <- read_rds("data-processed/budget_for_scenarios.rds") %>%
  ungroup() %>%
  mutate(per_yr = as.numeric(per_yr))

cizi_zdroje <- rozvaha %>%
  filter(polvyk == "D.") %>%
  rename(cizi_zdroje_netto = current_net) %>%
  select(ico, per_yr, cizi_zdroje_netto, orgs_ucjed_nazev)

aktiva_brutto <- rozvaha  %>%
  filter(polvyk == "AKTIVA") %>%
  select(aktiva_brutto = current_gross, ico, per_yr)

obezna_aktiva <- rozvaha  %>%
  filter(polvyk == "B.") %>%
  select(obezna_aktiva = current_net, ico, per_yr)

kratkodobe_zavazky <- rozvaha  %>%
  filter(polvyk_polvyk_nazev == "Krátkodobé závazky") %>%
  rename(kratkodobe_zavazky = current_net) %>%
  select(ico, per_yr, kratkodobe_zavazky)

dluh <- rozvaha %>%
  filter(synuc %in% synuc_dluh) %>%
  group_by(ico, per_yr) %>%
  summarise(dluh = sum(current_net))

indik_base <- rozp %>%
  left_join(cizi_zdroje) %>%
  left_join(aktiva_brutto) %>%
  left_join(obezna_aktiva) %>%
  left_join(kratkodobe_zavazky) %>%
  left_join(dluh)

# Set scenarios -----------------------------------------------------------

scenarios <- tribble(~scenario , ~spending_change, ~rud_change, ~borrowing_ratio, ~scenario_name,
                     "S1", 1.05, 0.9, 0, "5 % nárůst výdajů, 10 % propad RUD, konstantní dluh",
                     "S2", 1.05, 0.9, 1, "5 % nárůst výdajů, 10 % propad RUD, nárůst dluhu pokud klesne bilance",
                     "S3", 1.05, 0.8, 0, "5 % nárůst výdajů, 10 % propad RUD, nárůst dluhu pokud klesne bilance",
                     "S4", 1.05, 0.8, 0.5, "5 % nárůst výdajů, 10 % propad RUD, nárůst dluhu pokud klesne bilance",
                     "S5", 1.05, 0.8, 1, "5 % nárůst výdajů, 20 % propad RUD, nárůst dluhu pokud klesne bilance")
scenario_years <- 2020:2022

scenarios_by_year <- crossing(per_yr = scenario_years, scenarios)

# edit scenarios_by_year to make year-specific changes

# Likviditu nepujde projektovat, protože některé dluhy mohou být krátkodobé
# leda bychom předpokládali nějaký podíl
# podíl cizích zdrojů: pokud se zvyšuje i dluh, zvyušují se i cizí zdroje

ico_scenare_years <- crossing(per_yr = scenario_years,
                              # FIXME: filter out munitipalities invalid in 2019
                              ico = ico_obce)

# Project -----------------------------------------------------------------

indik_scenarios <- indik_base %>%
  ungroup() %>%
  filter(per_yr > 2015) %>%
  bind_rows(ico_scenare_years) %>%
  crossing(scenario = unique(scenarios$scenario)) %>%
  left_join(scenarios_by_year) %>%
  replace_na(list(rud_change = 1, spending_change = 1)) %>%
  group_by(scenario, ico) %>%
  arrange(per_yr) %>%
  fill(starts_with("rozp_"), kratkodobe_zavazky, aktiva_brutto, obezna_aktiva,
       dluh, cizi_zdroje_netto) %>%
  mutate(rozp_p_rud = rozp_p_rud * rud_change,
         rozp_p_celkem = rozp_p_rud + rozp_p_other_tax + rozp_p_non_tax +
           rozp_p_transfers + rozp_p_capital,
         rozp_v_celkem = rozp_v_celkem * spending_change,
         bilance = rozp_p_celkem - rozp_v_celkem,
         bilance_rel = bilance/rozp_v_celkem,
         saldo_to_sum = if_else(per_yr > 2019 & bilance < 0, abs(bilance), 0),
         saldo_cum = cumsum(saldo_to_sum),
         dluh = dluh + saldo_cum * borrowing_ratio,
         cizi_zdroje_netto = cizi_zdroje_netto + saldo_cum * borrowing_ratio)

indik_for_calc <- bind_rows(indik_base %>% mutate(scenario = "R"),
                            indik_scenarios)

indik_for_calc %>%
  ungroup() %>%
  count(scenario, per_yr) %>%
  spread(scenario, n)

# Calculate ---------------------------------------------------------------

indikatory <- indik_for_calc %>%
  group_by(scenario, ico) %>%
  arrange(per_yr) %>%
  mutate(podil_cizich_zdroju = cizi_zdroje_netto/aktiva_brutto,
         likvidita = obezna_aktiva/kratkodobe_zavazky,
         p0 = rozp_p_celkem,
         p1 = lag(rozp_p_celkem, 1),
         p2 = lag(rozp_p_celkem, 2),
         p3 = lag(rozp_p_celkem, 3),
         prijmy_last4 = (p0 + p1 + p2 + p3)/4,
         bilance_rel = bilance/rozp_v_celkem,
         rozp_odp = dluh/prijmy_last4) %>%
  select(-orgs_ucjed_nazev) %>%
  filter(!(scenario != "R" & per_yr < 2020)) %>%
  left_join(orgs %>% distinct(ico, .keep_all = T) %>%
              select(-start_date, -end_date)) %>%
  left_join(nuts, by = "nuts_id") %>%
  left_join(katobyv) %>%
  ungroup() %>%
  mutate(katobyv_nazev = fct_reorder(katobyv_nazev, as.integer(katobyv_id))) %>%
  select(per_yr, scenario, ico, ucjed_nazev, rozp_p_celkem, rozp_v_celkem, bilance, saldo_cum, dluh, rozp_odp, everything())

indikatory %>%
  count(scenario, per_yr) %>%
  spread(scenario, n)

write_rds(indikatory, "data-processed/indikatory.rds")

# Check -------------------------------------------------------------------

indikatory %>%
  filter(per_yr == 2020 & bilance < 0) %>%
  # View() %>%
  filter(TRUE)


# Basic overview of results -----------------------------------------------

indikatory %>%
  bind_rows(indikatory %>%
              filter(per_yr == 2019) %>%
              select(-scenario) %>%
              crossing(scenario = scenarios$scenario)) %>%
  filter(per_yr %in% 2019:2022) %>%
  ungroup() %>%
  count(scenario, per_yr, wt = (rozp_odp > .6)/n()) %>%
  spread(scenario, n)

indikatory %>%
  bind_rows(indikatory %>%
              filter(per_yr == 2019) %>%
              select(-scenario) %>%
              crossing(scenario = scenarios$scenario)) %>%
  filter(per_yr %in% 2019:2022) %>%
  ungroup() %>%
  count(scenario, per_yr, wt = (bilance < 0)/n()) %>%
  spread(scenario, n)

indikatory %>%
  bind_rows(indikatory %>%
              filter(per_yr == 2019) %>%
              select(-scenario) %>%
              crossing(scenario = scenarios$scenario)) %>%
  ungroup() %>%
  filter(per_yr > 2012) %>%
  group_by(per_yr, scenario, katobyv_nazev) %>%
  mutate(highratio = rozp_odp > .6) %>%
  summarise(perc_breach = mean(highratio, na.rm = T)) %>%
  ggplot(aes(per_yr, perc_breach, colour = scenario)) +
  geom_line() +
  facet_wrap(~katobyv_nazev) +
  scale_x_continuous(n.breaks = 6, labels = scales::label_number(accuracy = 1, big.mark = ""))

indikatory %>%
  bind_rows(indikatory %>%
              filter(per_yr == 2019) %>%
              select(-scenario) %>%
              crossing(scenario = scenarios$scenario)) %>%
  filter(scenario %in% c("S1", "S3", "R") & per_yr < 2021) %>%
  mutate(bilance_neg = bilance < 0) %>%
  group_by(per_yr, scenario, kraj.y) %>%
  summarise(perc_minus = mean(bilance_neg, na.rm = T)) %>%
  ggplot(aes(per_yr, perc_minus, colour = scenario)) +
  geom_line() +
  facet_wrap(~kraj.y) +
  scale_x_continuous(n.breaks = 6, labels = scales::label_number(accuracy = 1, big.mark = ""))

indikatory %>%
  filter(per_yr %in% 2019:2020 & scenario %in% c("S1", "S3", "R")) %>%
  mutate(bilance_neg = bilance < 0) %>%
  group_by(per_yr, scenario, katobyv_nazev) %>%
  summarise(perc_minus = mean(bilance_neg, na.rm = T)) %>%
  ggplot(aes(katobyv_nazev, perc_minus, colour = scenario)) +
  geom_point() +
  coord_flip() +
  ptrr::theme_ptrr("scatter", legend.position = "bottom") +
  ptrr::scale_y_percent_cz(expand = ptrr::flush_axis)

indikatory %>%
  filter(per_yr %in% 2019:2020 & scenario %in% c("S1", "S3", "R")) %>%
  group_by(per_yr, scenario) %>%
  ggplot(aes(scenario, bilance_rel, colour = scenario)) +
  geom_violin() +
  coord_flip() +
  ptrr::theme_ptrr("scatter", legend.position = "bottom") +
  ptrr::scale_y_number_cz(expand = ptrr::flush_axis)


# Zobrazit ----------------------------------------------------------------

indikatory %>%
  filter(per_yr %in% 2019:2022) %>%
  mutate(grp = str_c(per_yr, scenario)) %>%
  ggplot(aes(rozp_odp, fill = grp)) +
  geom_density(alpha = .4) +
  geom_vline(xintercept = .6) +
  facet_grid(scenario~per_yr) +
  scale_x_continuous(limits = c(0, 2))

indikatory %>%
  filter(podil_cizich_zdroju < 0.3 & podil_cizich_zdroju > -0.05) %>%
  ggplot(aes(x = per_yr, y = podil_cizich_zdroju,
             group = per_yr))+
  geom_boxplot(alpha = .1) +
  facet_wrap( ~katobyv_nazev) +

indikatory %>%
  ggplot(aes(rozp_odp, likvidita)) +
  geom_point() +
  facet_wrap(~per_yr) +
  scale_y_continuous(limits = c(0, 2500))

indikatory %>%
  filter(!per_yr > 2012) %>%
  group_by(per_yr) %>%
  group_by(katobyv_nazev, add = T) %>%
  summarise(x = mean(rozp_odp > .6, na.rm = T)) %>%
  ggplot(aes(per_yr, x, group = 1)) +
  facet_wrap(~katobyv_nazev) +
  geom_col()

indikatory %>%
  filter(!per_yr %in% c("2010", "2011", "2012")) %>%
  group_by(per_yr) %>%
  # group_by(katobyv_nazev, add = T) %>%
  summarise(x = mean(rozp_odp, na.rm = T)) %>%
  ggplot(aes(per_yr, x, group = 1)) +
  # facet_wrap(~ katobyv_nazev) +
  geom_col()

dluh %>%
  ggplot(aes(per_yr, dluh)) +
  geom_bar(stat = "sum") +
  facet_wrap(~ katobyv_nazev)
