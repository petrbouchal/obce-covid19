library(tidyverse)
library(statnipokladna)

budgets <- sp_get_table("budget-local", c(2013:2017, 2019),
                        c(3,6,9,12)) %>%
  janitor::remove_constant(na.rm = TRUE)
write_parquet(budgets, "data-input/budgets.parquet")

# 2018 do zvláštního objektu, abychom mohli pořešit číselníky
budgets_2018 <- sp_get_table("budget-local", 2018,
                             c(3,6,9,12)) %>%
  janitor::remove_constant(na.rm = TRUE)
write_parquet(budgets_2018, "data-input/budgets_2018.parquet")

# před rokem 2013 jsou jen čísla za celý rok
budgets_old <- sp_get_table("budget-local",
                            2010:2012, 12) %>%
  janitor::remove_constant(na.rm = TRUE)
write_parquet(budgets_old, "data-input/budgets_old.parquet")

budgets_all_bare <- bind_rows(budgets_2017, budgets_2018, budgets_old, budgets)
write_parquet(budgets_all_bare, "data-input/budgets_all_bare.parquet")

budgets_income_bare <- budgets_all_bare %>%
  filter(vtab == "000100")
write_parquet(budgets_income_bare, "data-input/budgets_income_bare.parquet")
rm("budgets_income_bare")

budgets_expenditure_bare <- budgets_all_bare %>%
  filter(vtab == "000100")
write_parquet(budgets_expenditure_bare, "data-input/budgets_expenditure_bare.parquet")
rm("budgets_expenditure_bare")

budgets2020 <- sp_get_table("budget-local", 2020, 2)
unique(budgets2020$ico) %>% length()
