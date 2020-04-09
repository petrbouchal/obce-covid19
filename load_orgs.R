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
