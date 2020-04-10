library(tidyverse)
library(statnipokladna)


# org data ----------------------------------------------------------------

source("load_orgs.R")

orgs <- orgs %>%
  select(ico, start_date, end_date, ucjed_nazev, obec, nuts_id, katobyv_id,
         pocob, kod_pou, kod_rp, zuj, typorg_id, kraj, druhuj_id, druhuj_nazev)


# 2010-12 -----------------------------------------------------------------



b_old <- read_rds("data-input/budgets_old.rds")
b_old_coded <- b_old %>%
  select(-kraj) %>%
  sp_add_codelist("polozka", dest_dir = "data-input") %>%
  sp_add_codelist(orgs) %>%
  select(-kraj) %>%
  sp_add_codelist("nuts", dest_dir = "data-input")

rm("b_old")
write_rds(b_old_coded, "data-processed/budgets_old_coded.rds", compress = "gz")
rm("b_old_coded")


# 2013-16 and 2019 --------------------------------------------------------

b_new <- read_rds("data-input/budgets.rds")
b_new_coded <- b_new %>%
  select(-kraj) %>%
  sp_add_codelist("polozka", dest_dir = "data-input") %>%
  sp_add_codelist(orgs) %>%
  select(-kraj) %>%
  sp_add_codelist("nuts", dest_dir = "data-input")

rm("b_new")
write_rds(b_new_coded, "data-processed/budgets_new_coded.rds", compress = "gz")
rm("b_new_coded")


# 2017 --------------------------------------------------------------------

b_17 <- read_rds("data-input/budgets_2017.rds")
b_17_coded <- b_17 %>%
  select(-kraj) %>%
  sp_add_codelist("polozka", dest_dir = "data-input") %>%
  sp_add_codelist(orgs) %>%
  select(-kraj) %>%
  sp_add_codelist("nuts", dest_dir = "data-input")

rm("b_17")
write_rds(b_17_coded, "data-processed/budgets_17_coded.rds", compress = "gz")
rm("b_17_coded")



# 2018 --------------------------------------------------------------------

b_18 <- read_rds("data-input/budgets_2018.rds")
polozka_raw <- sp_get_codelist("polozka", dest_dir = "data-input")

# polozka_duplicates <- polozka_raw %>%
#   group_by(polozka) %>%
#   filter(n() > 1) %>%
#   arrange(polozka, start_date)

this_period <- "2018-12-31"
polozka <- polozka_raw %>%
  mutate(for2018 = (end_date >=
                      "2018-12-31" & start_date <= "2018-12-31")) %>%
  group_by(polozka, for2018) %>%
  mutate(n = n(),
         duplicate = n() > 1,
         latest = end_date == max(end_date)) %>%
  # View()
  filter(!(for2018 & duplicate & latest)) %>%
  ungroup() %>%
  select(-for2018, -duplicate, -latest, -n)

b_18_coded <- b_18 %>%
  sp_add_codelist(polozka) %>%
  select(-kraj) %>%
  sp_add_codelist(orgs) %>%
  select(-kraj) %>%
  sp_add_codelist("nuts", dest_dir = "data-input")

# check that all polozky have a match

nrow(b_18_coded %>% filter(!is.na(polozka) & is.na(polozka_nazev)))

write_rds(b_18_coded, "data-processed/budgets_18_coded.rds", compress = "gz")
