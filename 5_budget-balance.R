library(tidyverse)
library(statnipokladna)

source("shared.R")
budget <- read_rds("data-processed/budgets_druhove_annual.rds")

obce_endyear_polozka_cons <- budget %>%
  ungroup() %>%
  filter(ico %in% ico_obce) %>%
  sp_add_codelist(polozka) %>%
  sp_add_codelist(orgs) %>%
  sp_add_codelist("katobyv", dest_dir = "data-input") %>%
  # konsolidovat na urovni ucetni jednotky
  filter(!kon_pol)

obce_bilance <- obce_endyear_polozka_cons %>%
  group_by(per_yr, ico, druh, katobyv_nazev, katobyv_id) %>%
  summarise(rslt = sum(budget_spending, na.rm = T)) %>%
  pivot_wider(names_from = druh, values_from = rslt) %>%
  ungroup() %>%
  mutate(bilance = Příjmy - Výdaje,
         bilance_rel = bilance/Příjmy,
         katobyv_nazev = fct_reorder(katobyv_nazev, as.numeric(katobyv_id)))

write_rds(obce_bilance, "data-processed/budgets_bilance.rds")
