
# This code generates data and one-number objects needed in index.Rmd, stav.Rmd and studie-idea.Rmd
# Normally it is run from within those docs when they are knitted and will therefore use the `rok` parameter set in the header of those documents

source("shared.R")
library(tidyverse)


# set param if not run from within a parameterised Rmd --------------------

if(!exists("params")) yr_slct <- 2019 else yr_slct <- params$rok


# Load data ---------------------------------------------------------------

indik_file <- here::here("data-processed", "scenare_vysledky.parquet")
indik_subset_file <- here::here("data-transfer", "indik_slctyr.parquet")

if(file.exists(indik_file)) {
  indikatory <- read_parquet(indik_file)
  indik_slctyr <- indikatory %>%
    filter(per_yr == yr_slct)
  if(!file.exists(indik_subset_file)) write_parquet(indik_slctyr, indik_subset_file)
} else {
  indik_slctyr <- read_parquet(indik_subset_file)
  if(unique(indik_slctyr$per_yr != yr_slct)) stop("Roky nesedí.")
}

# Spending ----------------------------------------------------------------

spend <- sum(indik_slctyr$rozp_p_celkem/1e9)
rud <- sum(indik_slctyr$rozp_p_rud/1e9)

income <- sum(indik_slctyr$rozp_v_celkem/1e9)

rud_share <- (sum(indik_slctyr$rozp_p_rud/1e9)/sum(indik_slctyr$rozp_p_celkem/1e9))

rezervy <- sum(indik_slctyr$kratkodoby_fin_majetek/1e9, na.rm = T)
bilance <- sum(indik_slctyr$bilance/1e9)

kap <- sum(indik_slctyr$rozp_v_kap/1e9, na.rm = T)
kap_share_mean <- mean(indik_slctyr$rozp_v_kap_share, na.rm = T)
kap_share_total <- kap/spend


# Bilance -----------------------------------------------------------------

bilance_sum <- sum(indik_slctyr$bilance/1e9, na.rm = T)
bilance_avg <- mean(indik_slctyr$bilance_rel, na.rm = T)
bilance_med <- median(indik_slctyr$bilance_rel, na.rm = T)
bilance_avg_total <- bilance_sum / spend

bil_neg <- indik_slctyr %>%
  filter(bilance < 0)

bil_neg_sum <- bil_neg %>%
  count(wt = bilance/1e9) %>% pull() %>% abs()

bil_neg_avg <- bil_neg %>%
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
