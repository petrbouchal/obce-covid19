library(tidyverse)

source("shared.R")


# Load data ---------------------------------------------------------------

rozvaha <- read_rds("data-processed/rozvaha.rds") %>%
  ungroup() %>%
  mutate(per_yr = as.numeric(per_yr))
rozp <- read_rds("data-processed/budget_for_scenarios.rds") %>%
  ungroup() %>%
  mutate(per_yr = as.numeric(per_yr))

# Extract measures --------------------------------------------------------

cizi_zdroje <- rozvaha %>%
  filter(polvyk == "D.") %>%
  rename(cizi_zdroje_netto = current_net) %>%
  select(ico, per_yr, cizi_zdroje_netto)

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

kratkodoby_fin_majetek <- rozvaha  %>%
  filter(polvyk_polvyk_nazev == "Krátkodobý finanční majetek") %>%
  rename(kratkodoby_fin_majetek = current_net) %>%
  select(ico, per_yr, kratkodoby_fin_majetek)

dluh <- rozvaha %>%
  filter(synuc %in% synuc_dluh) %>%
  group_by(ico, per_yr) %>%
  summarise(dluh = sum(current_net))

# Put measures together ---------------------------------------------------

indik_base <- rozp %>%
  left_join(cizi_zdroje) %>%
  left_join(aktiva_brutto) %>%
  left_join(obezna_aktiva) %>%
  left_join(kratkodobe_zavazky) %>%
  left_join(kratkodoby_fin_majetek) %>%
  left_join(dluh) %>%
  ungroup()

write_rds(indik_base, "data-processed/indikatory.rds")
