library(statnipokladna)
library(tidyverse)
library(CzechData)

if(!file.exists("data-input/orgs.rds")) {
  orgs_raw <- sp_get_codelist("ucjed", dest_dir = "data-input")
  druhuj <- sp_get_codelist("druhuj", dest_dir = "data-input")

  orgs <- orgs_raw %>%
    left_join(druhuj)

  write_rds(orgs, "data-input/orgs.rds", compress = "gz")

} else {
  orgs <- read_rds("data-input/orgs.rds")
}

orgs_selected <- read_rds("data-input/orgs.rds") %>%
  select(ico, start_date, end_date, ucjed_nazev, obec, nuts_id, katobyv_id,
         pocob, kod_pou, kod_rp, zuj, typorg_id, kraj, druhuj_id, druhuj_nazev)
write_rds(orgs_selected, "data-processed/orgs_selected.rds", compress = "gz")

orgs_selected_obce <- read_rds("data-input/orgs.rds") %>%
  select(ico, start_date, end_date, ucjed_nazev, obec, nuts_id, katobyv_id,
         pocob, kod_pou, kod_rp, zuj, typorg_id, kraj, druhuj_id, druhuj_nazev,
         zrizovatel_ico) %>%
  filter(druhuj_id == "4")
write_rds(orgs_selected_obce, "data-processed/orgs_selected_obce.rds", compress = "gz")

ico_obce <- orgs %>%
  filter(druhuj_id == "4" & ico != "00241687") %>%
  distinct(ico) %>%
  pull(ico)
write_rds(ico_obce, "data-processed/ico_obce.rds", compress = "gz")

orp <- CzechData::load_RUIAN_state("orp") %>% pull(spr_ob_kod)
pou <- CzechData::load_RUIAN_state("pou") %>% pull(spr_ob_kod)
krajska_mesta <- CzechData::load_population_settlements(year = 2018) %>%
  filter(is.na(pohlavi_kod), hodnota > 6e4) %>%
  mutate(vuzemi_kod = as.character(vuzemi_kod)) %>%
  pull(vuzemi_kod)

mesta_iti <- c("Praha", "Brno", "Olomouc", "Ostrava", "Pardubice", "Hradec Králové",
               "Jablonec nad Nisou", "Liberec", "Plzeň", "Děčín", "Chomutov", "Most",
               "Teplice", "Ústí nad Labem")

obce_typy <- orgs %>%
  filter(druhuj_id == "4") %>%
  select(zuj, ico) %>%
  mutate(typobce = case_when(zuj %in% krajska_mesta ~ "Krajské město/Praha",
                             zuj %in% orp ~ "S rozšířenou působností",
                             zuj %in% pou ~ "S pověřeným OÚ",
                             TRUE ~ "běžná obec")) %>%
  distinct()
obce_typy %>% distinct() %>% count(typobce)
write_rds(obce_typy, "data-processed/obce_typy.rds", compress = "gz")
