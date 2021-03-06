library(tidyverse)
library(statnipokladna)

source("shared.R")
budget <- read_parquet("data-processed/budgets_druhove_annual.parquet")

obce_endyear_polozka_cons <- budget %>%
  ungroup() %>%
  filter(ico %in% ico_obce) %>%
  sp_add_codelist(polozka) %>%
  sp_add_codelist(orgs) %>%
  # select(-kraj) %>%
  sp_add_codelist(nuts, by = "nuts_id") %>%
  sp_add_codelist(katobyv) %>%
  # konsolidovat na urovni ucetni jednotky
  filter(!kon_pol)

obce_bilance <- obce_endyear_polozka_cons %>%
  group_by(per_yr, ico, druh, katobyv_nazev, katobyv_id, nuts_id, orgs_ucjed_nazev,
           obec, pocob, kraj, zuj, kod_pou, kod_rp) %>%
  summarise(rslt = sum(budget_spending, na.rm = T)) %>%
  pivot_wider(names_from = druh, values_from = rslt) %>%
  ungroup() %>%
  mutate(bilance = Příjmy - Výdaje,
         bilance_rel = bilance/Příjmy,
         katobyv_nazev = fct_reorder(katobyv_nazev, as.numeric(katobyv_id))) %>%
  ungroup()

write_parquet(obce_bilance, "data-processed/budgets_bilance.parquet")
