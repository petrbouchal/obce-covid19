library(tidyverse)
library(statnipokladna)

source("shared.R")

rozvaha_1 <- statnipokladna::sp_get_table("balance-sheet",
                                              year = 2010:2019,
                                              ico = ico_obce,
                                              dest_dir = "data-input")

rozvaha_1_processed <- rozvaha_1 %>%
  sp_add_codelist("polvyk") %>%
  select(-kraj) %>%
  sp_add_codelist(orgs, by = "ico")

rozvaha_2 <- statnipokladna::sp_get_table("balance-sheet-2",
                                            year = 2013:2019,
                                            ico = ico_obce, dest_dir = "data-input")

rozvaha_2 %>%
  group_by(per_yr) %>%
  summarise(n_2 = n_distinct(ico)) %>%
  right_join(rozvaha_1 %>%
              group_by(per_yr) %>%
              summarise(n_1 = n_distinct(ico))) %>%
  replace_na(list(n_2 = 0)) %>%
  mutate(n = n_1 + n_2)

rozvaha_2_processed <- rozvaha_2 %>%
  sp_add_codelist("polvyk") %>%
  select(-kraj) %>%
  sp_add_codelist(orgs, by = "ico")

rozvaha_processed <- bind_rows(rozvaha_1_processed, rozvaha_2_processed) %>%
  filter(polvyk %in% rozvaha_keep | synuc %in% synuc_dluh) %>%
  sp_add_codelist("katobyv")

rozvaha_processed_unfiltered <- bind_rows(rozvaha_1_processed, rozvaha_2_processed) %>%
  sp_add_codelist("katobyv")

write_parquet(rozvaha_processed, "data-processed/rozvaha_filtered.parquet")
write_parquet(rozvaha_processed_unfiltered, "data-processed/rozvaha.parquet")
