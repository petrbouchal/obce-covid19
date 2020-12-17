knitr::opts_chunk$set(echo = FALSE, warning = F, message = F,
                      dev = "ragg_png", dpi = 300, fig.asp = .6,
                      fig.width = (21-2*2.205)/2.54)

Sys.setlocale(locale = "cs_CZ.UTF-8")

library(tidyverse)
library(ptrr)

library(statnipokladna)

source("cisla_report_stav.R")


okresy_polygons <- CzechData::load_RUIAN_state("okresy")
kraje_polygons <- CzechData::load_RUIAN_state("kraje")
obce_polygons <- CzechData::load_RUIAN_state("obce")

dluh_kraje <- indik_slctyr %>%
  left_join(CzechData::okresy, by = c('nuts_id' = 'lau1_kod')) %>%
  group_by(grp = nuts3_kod, typobce) %>%
  summarise(podil = mean(bilance < 0, na.rm = T), .groups = "drop",
            pocet = n())

dluh_okresy <- indik_slctyr %>%
  left_join(CzechData::okresy, by = c('nuts_id' = 'lau1_kod')) %>%
  group_by(grp = nuts_id, typobce) %>%
  summarise(podil = mean(bilance < 0, na.rm = T), .groups = "drop",
            pocet = n())

okresy_rich <- okresy_polygons %>%
  left_join(dluh_okresy, by = c('lau1_kod' = 'grp'))

kraje_rich <- kraje_polygons %>%
  left_join(dluh_kraje, by = c('nuts3_kod' = 'grp'))

obce_rich <- obce_polygons %>%
  left_join(indik_slctyr, by = c('kod' = 'zuj'))

ggplot(okresy_rich) +
  geom_sf(aes(fill = podil)) +
  facet_wrap(~typobce)

ggplot(kraje_rich) +
  geom_sf(aes(fill = podil)) +
  facet_wrap(~typobce)

ggplot(obce_rich) +
  geom_sf(aes(fill = bilance/rozp_p_celkem), colour = NA) +
  facet_wrap(~typobce) +
  scale_fill_viridis_b() +
  coord_sf(crs = 4326)

