
# This code generates data and one-number objects needed in index.Rmd, stav.Rmd and studie-idea.Rmd
# Normally it is run from within those docs when they are knitted and will therefore use the `rok` parameter set in the header of those documents

source("shared.R")
library(tidyverse)
library(arrow)


# set param if not run from within a parameterised Rmd --------------------

if(!exists("params")) yr_slct <- 2019 else yr_slct <- params$rok


# Load data ---------------------------------------------------------------

indik_file <- here::here("data-processed", "scenare_vysledky.parquet")
indik_subset_file <- here::here("data-transfer", "indik_slctyr.parquet")

if(file.exists(indik_file)) {
  indikatory <- read_parquet(indik_file)
  indik_slctyr <- indikatory %>%
    filter(per_yr == yr_slct) %>%
    mutate(pocob = as.numeric(pocob))
  if(!file.exists(indik_subset_file)) write_parquet(indik_slctyr, indik_subset_file)
} else {
  indik_slctyr <- read_parquet(indik_subset_file)
  if(unique(indik_slctyr$per_yr != yr_slct)) stop("Roky nesedí.")
}

indik_last3 <- indikatory %>%
  filter(per_yr %in% 2017:2019)

#Population ---------------------------------------------------------------
obec_info <- indik_slctyr %>% filter(typobce_wrapped == "Běžná obec") %>%
    summarize(obyv_avg = mean(as.numeric(pocob), na.rm = T), pocet = n())

kraj_info <- indik_slctyr %>% filter(typobce_wrapped == "Krajská města\na Praha") %>%
  summarize(obyv_avg = mean(as.numeric(pocob), na.rm = T), pocet = n())
# Income ------------------------------------------------------------------

spend <- sum(indik_slctyr$rozp_v_celkem/1e9)
rud <- sum(indik_slctyr$rozp_p_rud/1e9)

income <- sum(indik_slctyr$rozp_p_celkem/1e9)

rud_share <- (sum(indik_slctyr$rozp_p_rud/1e9)/sum(indik_slctyr$rozp_p_celkem/1e9))

# Spending ----------------------------------------------------------------

kap <- sum(indik_slctyr$rozp_v_kap/1e9, na.rm = T)
kap_share_mean <- mean(indik_slctyr$rozp_v_kap_share, na.rm = T)
kap_share_total <- kap/spend

# Bilance -----------------------------------------------------------------

bilance <- sum(indik_slctyr$bilance/1e9)

bilance_sum <- sum(indik_slctyr$bilance/1e9, na.rm = T)
bilance_avg <- mean(indik_slctyr$bilance_rel, na.rm = T)
bilance_med <- median(indik_slctyr$bilance_rel, na.rm = T)
bilance_avg_total <- bilance_sum / spend

bil_neg <- indik_slctyr %>%
  filter(bilance < 0)

bil_pos <- indik_slctyr %>%
  filter(bilance >= 0)

bil_neg_sum <- bil_neg %>%
  count(wt = bilance/1e9) %>% pull() %>% abs()

bil_pos_sum <- bil_pos %>%
  count(wt = bilance/1e9) %>% pull() %>% abs()

bil_neg_avg <- bil_neg %>%
  summarise(m = mean(bilance_rel, na.rm = T)) %>% pull() %>% abs()

bil_pos_avg <- bil_pos %>%
  summarise(m = mean(bilance_rel, na.rm = T)) %>% pull() %>% abs()

bil_neg_median <- bil_neg %>%
  summarise(m = median(bilance_rel, na.rm = T)) %>% pull() %>% abs()

bil_pos_share <- indik_slctyr %>%
  count(wt = (bilance >= 0)/n()) %>% pull()

bil_pos_count <- indik_slctyr %>%
  count(wt = bilance >= 0) %>% pull()
bil_neg_count <- indik_slctyr %>%
  count(wt = bilance < 0) %>% pull()


# Dluh --------------------------------------------------------------------

dluh <- sum(indik_slctyr$dluh/1e9, na.rm = T)

dluh_pos_share <- indik_slctyr %>%
  count(wt = (dluh > 0)/n()) %>% pull()

dluh_pos_count <- indik_slctyr %>%
  count(wt = dluh > 0) %>% pull()

dluh_breach_share <- indik_slctyr %>%
  count(wt = (rozp_odp >= 0.6)/n()) %>% pull()

dluh_breach_count <- indik_slctyr %>%
  count(wt = rozp_odp >= 0.6) %>% pull()

dluh_breach_median <- mean(indik_slctyr$rozp_odp, na.rm = T)
dluh_breach_mean <- mean(indik_slctyr$rozp_odp, na.rm = T)

dluh_pos_mean <- indik_slctyr %>%
  filter(dluh > 0) %>%
  summarise(n = mean(rozp_odp_1yr, na.rm = T)) %>% pull()

dluh_pos_mean_last4 <- indik_slctyr %>%
  filter(dluh > 0) %>%
  summarise(n = mean(rozp_odp, na.rm = T)) %>% pull()

# Rezervy -----------------------------------------------------------------

rezervy <- sum(indik_slctyr$kratkodoby_fin_majetek/1e9, na.rm = T)

rez <- sum(indik_slctyr$kratkodoby_fin_majetek/1e9, na.rm = T)

rez_to_spend_mean <- indik_slctyr %>%
  mutate(share = kratkodoby_fin_majetek/rozp_p_celkem) %>%
  summarise(m = mean(share, na.rm = T)) %>% pull()

rez_to_spend_median <- indik_slctyr %>%
  mutate(share = kratkodoby_fin_majetek/rozp_p_celkem) %>%
  summarise(m = median(share, na.rm = T)) %>% pull()

rez_10pc_spend <- indik_slctyr %>%
  count(wt = (kratkodoby_fin_majetek > rozp_v_celkem * 0.1)/n()) %>% pull()

rez_2xkap <- indik_slctyr %>%
  count(wt = (kratkodoby_fin_majetek > rozp_v_kap * 2)/n()) %>% pull()

rez_pha <- indik_slctyr %>%
  filter(ico == "00064581") %>% pull(kratkodoby_fin_majetek) %>% {./1e9}

rez_krajska <- indik_slctyr %>%
  filter(ico != "00064581" & typobce == "Krajská města a Praha") %>%
  count(wt = kratkodoby_fin_majetek/1e9) %>%
  pull()

rez_pha_share <- rez_pha/rez
rez_krajska_share <- rez_krajska/rez

kzav <- sum(indik_slctyr$kratkodobe_zavazky/1e9, na.rm = T)

# Aglomerace ----------------------------------------------------------------------------
list_metropole <- c("Pražská metropolitní oblast", "Ostravská metropolitní oblast", "Brněnská metropolitní oblast")

ohrozene_oblasti <- read_parquet("data-transfer/ohrozene_oblasti.parquet")
ohrozene_obce <- read_parquet("data-transfer/uap_gis_obce.parquet") %>% rename(kod_orp = KODORP, kodobce_ohroz = KODOBCE) %>%
                          inner_join(ohrozene_oblasti, by="kod_orp") %>%
                          mutate(kodobce_ohroz = as.character(kodobce_ohroz)) %>%
                          select(kod_orp, kodobce_ohroz, NAZEV)

metro_oblasti <- read_parquet("data-transfer/metropolitni_oblasti.parquet") %>% mutate(zuj = as.character(zuj))

indik_geo <- indik_slctyr %>% left_join(metro_oblasti, by= 'zuj') %>%
                  left_join(ohrozene_obce, by = c('zuj' = 'kodobce_ohroz'), keep=TRUE) %>%
                  mutate(is_aglo = !is.na(aglomerace)) %>%
                  mutate(metropole = aglomerace %in% list_metropole) %>%
                  mutate(soc_eco = !is.na(kodobce_ohroz))  %>%
                  mutate(pocob = as.integer(pocob)) %>%
                  mutate(typobce_aglomerace = case_when(is_aglo  & typobce_wrapped != "Krajská města\na Praha" ~ "Obec v aglomeraci",
                                                        soc_eco == TRUE ~ "Sociálně a hospodářsky vyloučené oblasti",
                                                        typobce_wrapped == "Krajská města\na Praha" ~  "Krajská města\na Praha",
                                                        TRUE ~ "Obec mimo aglomeraci"))

indik_aglo <- indik_geo %>% filter(is_aglo) %>%
                            mutate(typ_aglomerace = case_when(
                                                      metropole ~ "Obec v metropolitní oblasti",
                                                      typobce_wrapped == "Krajská města\na Praha" ~  "Krajská města\na Praha",
                                                      TRUE ~ "Obec v běžné aglomeraci"))


aglo_areas <- indik_geo %>% filter(is_aglo)
metropole <- indik_geo %>% filter(metropole & typobce_wrapped != "Krajská města\na Praha")
metro_cele <- indik_geo %>% filter(metropole)
aglo_obec <- indik_geo %>% filter(is_aglo & typobce_wrapped != "Krajská města\na Praha")
soceco_obec <- indik_geo %>% filter(soc_eco)
krajska <- indik_geo %>% filter(typobce_wrapped == "Krajská města\na Praha")


# Pocet obyvatel
pocob_aglo_share <- sum(aglo_areas$pocob) / sum(as.integer(indik_slctyr$pocob))
pocob_aglo_obec_share <- sum(aglo_obec$pocob)/sum(as.integer(indik_slctyr$pocob))
pocob_metro_share <- sum(metropole$pocob)/sum(as.integer(indik_slctyr$pocob))
pocob_krajska_share <- sum(krajska$pocob)/sum(as.integer(indik_slctyr$pocob))

spend_aglo <- sum(aglo_areas$rozp_v_celkem/1e9)
spend_aglo_share <- spend_aglo / spend
spend_aglo_obec_share <- sum(aglo_obec$rozp_v_celkem/1e9) / spend
spend_metro_share <- sum(metropole$rozp_v_celkem/1e9) / spend
spend_krajska_share <- sum(krajska$rozp_v_celkem/1e9) / spend

rud_aglo <- sum(aglo_areas$rozp_p_rud/1e9)
rud_aglo_share <- rud_aglo / rud
rud_aglo_obec_share <- sum(aglo_obec$rozp_p_rud/1e9) / rud
rud_metro_share  <-  sum(metropole$rozp_p_rud/1e9) / rud

income_aglo <- sum(aglo_areas$rozp_p_celkem/1e9)
income_aglo_obec_share <- sum(aglo_obec$rozp_p_celkem/1e9) / income
income_aglo_share <- income_aglo / income
income_metro_share <- sum(metropole$rozp_p_celkem/1e9) / income
income_krajska_share <- sum(krajska$rozp_p_celkem/1e9) / income

dluh_aglo <- sum(aglo_areas$dluh/1e9, na.rm = T)
dluh_aglo_share <- dluh_aglo/dluh
dluh_aglo_obec_share <- sum(aglo_obec$dluh/1e9) /dluh
dluh_krajska_share <- sum(krajska$dluh/1e9) / dluh
