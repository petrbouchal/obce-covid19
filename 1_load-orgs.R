library(statnipokladna)
library(tidyverse)
library(CzechData)
library(arrow)

if(!file.exists("data-input/orgs.parquet")) {
  orgs_raw <- sp_get_codelist("ucjed", dest_dir = "data-input")
  druhuj <- sp_get_codelist("druhuj", dest_dir = "data-input")

  orgs <- orgs_raw %>%
    left_join(druhuj)

  write_parquet(orgs, "data-input/orgs.parquet")

} else {
  orgs <- read_parquet("data-input/orgs.parquet")
}

orgs_selected <- read_parquet("data-input/orgs.parquet") %>%
  select(ico, start_date, end_date, ucjed_nazev, obec, nuts_id, katobyv_id,
         pocob, kod_pou, kod_rp, zuj, typorg_id, kraj, druhuj_id, druhuj_nazev)
write_parquet(orgs_selected, "data-transfer/orgs_selected.parquet")

orgs_selected_obce <- read_parquet("data-input/orgs.parquet") %>%
  select(ico, start_date, end_date, ucjed_nazev, obec, nuts_id, katobyv_id,
         pocob, kod_pou, kod_rp, zuj, typorg_id, kraj, druhuj_id, druhuj_nazev,
         zrizovatel_ico) %>%
  filter(druhuj_id == "4")
write_parquet(orgs_selected_obce, "data-transfer/orgs_selected_obce.parquet")

ico_obce <- orgs %>%
  filter(druhuj_id == "4" & ico != "00241687") %>%
  distinct(ico) %>%
  pull(ico)
write_rds(ico_obce, "data-transfer/ico_obce.rds")

orp <- CzechData::load_RUIAN_state("orp") %>% pull(spr_ob_kod)
pou <- CzechData::load_RUIAN_state("pou") %>% pull(spr_ob_kod)
krajska_mesta <- czso::czso_get_table(dataset_id = "130149") %>%
  filter(rok==2018) %>%
  filter(is.na(pohlavi_kod),
         vuzemi_txt %in% c("Brno", "České Budějovice", "Hradec Králové",
                           "Jihlava", "Karlovy Vary", "Liberec", "Olomouc",
                           "Ostrava", "Pardubice", "Plzeň", "Praha",
                           "Ústí nad Labem",  "Zlín")) %>%
  mutate(vuzemi_kod = as.character(vuzemi_kod)) %>%
  pull(vuzemi_kod)

mesta_iti <- c("Praha", "Brno", "Olomouc", "Ostrava", "Pardubice", "Hradec Králové",
               "Jablonec nad Nisou", "Liberec", "Plzeň", "Děčín", "Chomutov", "Most",
               "Teplice", "Ústí nad Labem")

obce_typy <- orgs %>%
  filter(druhuj_id == "4") %>%
  select(zuj, ico) %>%
  mutate(typobce = case_when(zuj %in% krajska_mesta ~ "Krajská města a Praha",
                             zuj %in% orp ~ "S rozšířenou působností",
                             zuj %in% pou ~ "S pověřeným obecním úřadem",
                             TRUE ~ "Běžná obec") %>%
           as_factor() %>% fct_relevel("Běžná obec", after = Inf)) %>%
  distinct() %>%
  mutate(typobce_wrapped = fct_relabel(typobce, ~str_wrap(.x, 14)))
levels(obce_typy$typobce)
levels(obce_typy$typobce_wrapped)

obce_typy %>% distinct() %>% count(typobce)
write_parquet(obce_typy, "data-transfer/obce_typy.parquet")

katobyv <- sp_get_codelist("katobyv", dest_dir = "data-input/sp/") %>%
  rename(katobyv_nazev = nazev)
write_parquet(okresy, "data-transfer/katobyv_codelist.parquet")

kraje <- nuts_codelist %>%
  filter(str_length(nuts_id) == 5) %>%
  filter(end_date > Sys.Date()) %>%
  select(kraj = nuts_id, kraj_nazev = nuts_nazev)
write_parquet(kraje, "data-transfer/kraj_codelist.parquet")

nuts_codelist <- sp_get_codelist("nuts")
write_parquet(okresy, "data-transfer/nuts_codelist.parquet")

okresy <- nuts_codelist %>%
  filter(str_length(nuts_id) == 6) %>%
  filter(end_date > Sys.Date()) %>%
  select(nuts_id, okres_nazev = nuts_nazev)
write_parquet(okresy, "data-transfer/okres_codelist.parquet")

cohreg <- nuts_codelist %>%
  filter(str_length(nuts_id) == 4) %>%
  filter(end_date > Sys.Date()) %>%
  select(kraj = nuts_id, kraj_nazev = nuts_nazev)

