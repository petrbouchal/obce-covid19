library(statnipokladna)
library(tidyverse)

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

ico_obce <- orgs %>%
  filter(druhuj_id == "4") %>%
  distinct(ico) %>%
  pull(ico)
write_rds(ico_obce, "data-processed/ico_obce.rds", compress = "gz")

