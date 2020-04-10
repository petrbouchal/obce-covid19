library(tidyverse)
library(statnipokladna)

bb <- read_rds("data-input/budgets_all_bare.rds")
polozka <- read_rds("data-processed/polozka.rds")

druhove_annual <- bb %>%
  filter(per_m == "12") %>%
  group_by(per_yr, per_m, ico, polozka, period_vykaz, vtab) %>%
  summarise_at(vars(starts_with("budget_")), sum, na.rm = T)

nrow(druhove_annual)

write_rds(druhove_annual,
          "data-processed/budgets_druhove_annual.rds", compress = "gz")
write_rds(druhove_annual %>%
            filter(vtab == "000100"),
          "data-processed/budgets_druhove_prijmy_annual.rds",
          compress = "gz")
write_rds(druhove_annual %>%
            filter(vtab == "000200"),
          "data-processed/budgets_druhove_vydaje_annual.rds",
          compress = "gz")
rm("druhove_annual")

druhove <- bb %>%
  group_by(per_yr, per_m, ico, polozka, period_vykaz, vtab) %>%
  summarise_at(vars(starts_with("budget_")), sum, na.rm = T)

nrow(druhove)
write_rds(druhove, "data-processed/budgets_druhove.rds", compress = "gz")
write_rds(druhove %>%
            filter(vtab == "000100"),
          "data-processed/budgets_druhove_prijmy.rds",
          compress = "gz")
write_rds(druhove %>%
            filter(vtab == "000200"),
          "data-processed/budgets_druhove_vydaje.rds",
          compress = "gz")
