library(tidyverse)
library(statnipokladna)

budgets <- sp_get_table("budget-local", c(2013:2016, 2019),
                        c(3,6,9,12), dest_dir = "data-input") %>%
  janitor::remove_constant(na.rm = TRUE)
write_rds(budgets, "data-input/budgets.rds", compress = "gz")

# na webu chybí Q3 2017, zbytek 2017 stáhnout zvlášť
budgets_2017 <- sp_get_table("budget-local", 2017, c(3, 6, 12), dest_dir = "data-input") %>%
  janitor::remove_constant(na.rm = TRUE)

write_rds(budgets_2017, "data-input/budgets_2017.rds", compress = "gz")

# 2018 do zvláštního objektu, abychom mohli pořešit číselníky
budgets_2018 <- sp_get_table("budget-local", 2018,
                             c(3,6,9,12), dest_dir = "data-input") %>%
  janitor::remove_constant(na.rm = TRUE)
write_rds(budgets_2018, "data-input/budgets_2018.rds", compress = "gz")

# před rokem 2013 jsou jen čísla za celý rok
budgets_old <- sp_get_table("budget-local",
                            2010:2012, 12, dest_dir = "data-input") %>%
  janitor::remove_constant(na.rm = TRUE)
write_rds(budgets_old, "data-input/budgets_old.rds", compress = "gz")

budgets_all_bare <- bind_rows(budgets_2017, budgets_2018, budgets_old, budgets)
write_rds(budgets_all_bare, "data-input/budgets_all_bare.rds", compress = "gz")

budgets_income_bare <- budgets_all_bare %>%
  filter(vtab == "000100")
write_rds(budgets_income_bare, "data-input/budgets_income_bare.rds", compress = "gz")
rm("budgets_income_bare")

budgets_expenditure_bare <- budgets_all_bare %>%
  filter(vtab == "000100")
write_rds(budgets_expenditure_bare, "data-input/budgets_expenditure_bare.rds", compress = "gz")
rm("budgets_expenditure_bare")


