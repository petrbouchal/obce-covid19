library(tidyverse)
library(arrow)
library(statnipokladna)

bb <- read_parquet("data-input/budgets_all_bare.parquet")
polozka <- read_parquet("data-transfer/polozka.parquet")

druhove_annual <- bb %>%
  filter(per_m == "12") %>%
  group_by(per_yr, per_m, ico, polozka, period_vykaz, vtab) %>%
  summarise_at(vars(starts_with("budget_")), sum, na.rm = T)

nrow(druhove_annual)

write_parquet(druhove_annual,
          "data-processed/budgets_druhove_annual.parquet")
write_parquet(druhove_annual %>%
            filter(vtab == "000100"),
          "data-processed/budgets_druhove_prijmy_annual.parquet",
          compress = "gz")
write_parquet(druhove_annual %>%
            filter(vtab == "000200"),
          "data-processed/budgets_druhove_vydaje_annual.parquet",
          compress = "gz")
rm("druhove_annual")

druhove <- bb %>%
  group_by(per_yr, per_m, ico, polozka, period_vykaz, vtab) %>%
  summarise_at(vars(starts_with("budget_")), sum, na.rm = T)

nrow(druhove)
write_parquet(druhove, "data-processed/budgets_druhove.parquet")
write_parquet(druhove %>%
            filter(vtab == "000100"),
          "data-processed/budgets_druhove_prijmy.parquet",
          compress = "gz")
write_parquet(druhove %>%
            filter(vtab == "000200"),
          "data-processed/budgets_druhove_vydaje.parquet",
          compress = "gz")


# Capital x current spend -------------------------------------------------

b_v <- read_parquet("data-processed/budgets_druhove_vydaje_annual.parquet")

table(b_v$ico %in% ico_obce)

b_v_f <- b_v %>%
  ungroup() %>%
  mutate(per_yr = as.numeric(per_yr)) %>%
  filter(ico %in% ico_obce)

b_v_f_coded <- b_v_f %>%
  sp_add_codelist(polozka)

b_v_f_coded %>%
  filter(is.na(trida))

# detect and explore lines which had no match in codelist:

# b_v_f_coded %>%
#   filter(is.na(trida)) %>%
#   group_by(ico) %>%
#   count(sort = T)
#
# polozky_na <- b_v_f_coded %>%
#   filter(is.na(trida)) %>%
#   group_by(polozka) %>%
#   count(sort = T) %>%
#   pull(polozka)
#
# polozky_na %in% polozka$polozka
#
# polozka %>%
#   filter(polozka %in% polozky_na) %>% write_csv("polozky_chyba.csv")

spend_trida <- b_v_f_coded %>%
  group_by(per_yr, ico, trida) %>%
  summarise_at(vars(starts_with("budget_")), sum, na.rm = T) %>%
  select(per_yr, ico, trida, budget_spending) %>%
  spread(trida, budget_spending) %>%
  select(rozp_v_bezne = `Běžné výdaje`, rozp_v_kap = `Kapitálové výdaje`) %>%
  # handle places with zero capital spend
  replace_na(list(rozp_v_kap = 0)) %>%
  mutate(rozp_v_kap_share = rozp_v_kap/(rozp_v_bezne + rozp_v_kap)) %>%
  replace_na(list(rozp_v_kap = 0, rozp_v_kap_share = 0))

nrow(spend_trida %>% filter(is.na(rozp_v_kap)))
nrow(spend_trida %>% filter(is.na(rozp_v_kap_share)))
nrow(spend_trida %>% filter(is.na(rozp_v_bezne)))

write_parquet(spend_trida, "data-processed/budgets_capital.parquet")

