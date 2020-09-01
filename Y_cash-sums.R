library(tidyverse)
library(statnipokladna)

source("shared.R")

orgs <- read_parquet("data-processed/orgs_selected.parquet")

rzv <- sp_get_table("balance-sheet", 2019) %>%
  bind_rows(sp_get_table("balance-sheet-2", 2019))

rzv_coded <- rzv %>%
  sp_add_codelist("polvyk") %>%
  select(-kraj) %>%
  sp_add_codelist(orgs) %>%
  sp_add_codelist("druhuj")

rzv %>%
  group_by(ico, per_yr) %>%
  summarise(pocet = n()) %>%
  ungroup() %>%
  skimr::skim()

rzv_coded %>%
  filter(druhuj_nazev %in% c("Obce", "Kraje")) %>%
  filter(str_detect(polvyk, "B.III.")) %>%
  # filter(polvyk_polvyk_nazev == "Oběžná aktiva") %>%
  # filter(polvyk_polvyk_nazev == "Krátkodobý finanční majetek") %>%
  # filter(polvyk_polvyk_nazev == "Běžný účet") %>%
  # filter(polvyk_polvyk_nazev == "Základní běžný účet územních samosprávných celků") %>%
  count(polvyk, polvyk_polvyk_nazev, wt = current_net/1e9) %>%
  arrange(polvyk)

rzv_coded %>%
  filter(druhuj_nazev %in% c("Obce")) %>%
  filter(polvyk_polvyk_nazev == "Oběžná aktiva") %>%
  arrange(desc(current_net)) %>%
  add_count(wt = current_net, name = "current_net_sum") %>%
  mutate(rank_net = rank(desc(current_net))) %>%
  mutate(rank_group = case_when(rank_net == 1 ~ 1,
                                rank_net <= 10 ~ 10,
                                rank_net <= 100 ~ 100,
                                rank_net <= 1000 ~ 1000,
                                TRUE ~ 10000)) %>%
  group_by(rank_group) %>%
  summarise(cash_in_rank = sum(current_net)/mean(current_net_sum)) %>%
  ungroup() %>%
  arrange(rank_group) %>%
  mutate(cash_in_rank_cum = cumsum(cash_in_rank))


