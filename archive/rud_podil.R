library(tidyverse)
library(statnipokladna)

budgets <- read_parquet("data-input/budgets_all_bare.parquet")
polozka <- read_parquet("data-transfer/polozka.parquet")
orgs <- read_parquet("data-input/orgs.parquet") %>%
  select(ico, start_date, end_date, ucjed_nazev, obec, nuts_id, katobyv_id,
         pocob, kod_pou, kod_rp, zuj, typorg_id, kraj, druhuj_id, druhuj_nazev)
katobyv <- sp_get_codelist("katobyv")

ico_obce <- orgs %>%
  filter(druhuj_id == "4") %>%
  distinct(ico) %>%
  pull(ico)

# kody polozek prijmu z dani rozdelovanych pres RUD
polozky_rud <- c("1111", "1112", "1113", "1119", "1121", "1123", "1129", "1219")
# kod polozky dane z nemovitosti
polozky_dzn <- c("1511")

# table(str_detect(bb$polozka, "^1"))

obce_income_endyear_polozka_cons <- budgets %>%
  filter(ico %in% ico_obce & per_m == "12") %>%
  # filter to keep only income
  filter(str_detect(polozka, "^1")) %>%
  sp_add_codelist(polozka) %>%
  # konsolidovat na urovni ucetni jednotky
  filter(!kon_pol)

bb2 <- obce_income_endyear_polozka_cons %>%
  mutate(rud = polozka %in% polozky_dzn) %>%
  group_by(ico, rud, period_vykaz, per_yr) %>%
  summarise_at(vars(starts_with("budget_")), sum, na.rm = T) %>%
  group_by(ico, period_vykaz, per_yr) %>%
  mutate(podil_rud = budget_spending/sum(budget_spending)) %>%
  filter(rud) %>%
  sp_add_codelist(orgs) %>%
  select(-kraj) %>%
  sp_add_codelist("nuts") %>%
  left_join(katobyv) %>%
  mutate(katobyv_nazev = as.factor(katobyv_nazev) %>%
           fct_reorder(as.integer(katobyv_id)),
         rok = as.numeric(per_yr)) %>%
  filter(TRUE)

bb2 %>%
  filter(podil_rud > 0) %>%
  ggplot(aes(per_yr, podil_rud)) +
  geom_boxplot(alpha = .1) +
  facet_wrap(~ katobyv_nazev)
