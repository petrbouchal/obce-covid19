library(tidyverse)

b_old <- read_rds("data-processed/budgets_old_coded.rds")
b_18 <- read_rds("data-processed/budgets_18_coded.rds")
b_17 <- read_rds("data-processed/budgets_17_coded.rds")
b_new <- read_rds("data-processed/budgets_new_coded.rds")

b_all <- bind_rows(b_old, b_new, b_18, b_17)
rm("b_old", "b_new", "b_17", "b_18")

write_rds(b_all, "data-processed/budgets_all_coded.rds", compress = "gz")

b_obce <- b_all %>%
  filter(druhuj_id == 4)

write_rds(b_obce, "data-processed/budgets_obce_coded.rds", compress = "gz")

rm("b_all")

