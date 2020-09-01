library(tidyverse)

b_old <- read_parquet("data-processed/budgets_old_coded.parquet")
b_18 <- read_parquet("data-processed/budgets_18_coded.parquet")
b_17 <- read_parquet("data-processed/budgets_17_coded.parquet")
b_new <- read_parquet("data-processed/budgets_new_coded.parquet")

b_all <- bind_rows(b_old, b_new, b_18, b_17)
rm("b_old", "b_new", "b_17", "b_18")

write_parquet(b_all, "data-processed/budgets_all_coded.parquet")

b_obce <- b_all %>%
  filter(druhuj_id == 4)

write_parquet(b_obce, "data-processed/budgets_obce_coded.parquet")

rm("b_all")

