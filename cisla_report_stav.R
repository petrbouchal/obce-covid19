source("shared.R")
library(tidyverse)

if(is.null(params$rok)) yr_slct <- 2019 else yr_slct <- params$rok

indikatory <- read_parquet("data-processed/scenare_vysledky.parquet")
indik_2019 <- indikatory %>%
  filter(per_yr == yr_slct)

spend <- sum(indik_2019$rozp_p_celkem/1e9)
rud <- sum(indik_2019$rozp_p_rud/1e9)

income <- sum(indik_2019$rozp_v_celkem/1e9)

rud_share <- (sum(indik_2019$rozp_p_rud/1e9)/sum(indik_2019$rozp_p_celkem/1e9))

rezervy <- sum(indik_2019$kratkodoby_fin_majetek/1e9, na.rm = T)
bilance <- sum(indik_2019$bilance/1e9)

kap <- sum(indik_2019$rozp_v_kap/1e9, na.rm = T)
kap_share_mean <- mean(indik_2019$rozp_v_kap_share, na.rm = T)
kap_share_total <- kap/spend



bilance_sum <- sum(indik_2019$bilance/1e9, na.rm = T)
bilance_avg <- mean(indik_2019$bilance_rel, na.rm = T)
bilance_med <- median(indik_2019$bilance_rel, na.rm = T)
bilance_avg_total <- bilance_sum / spend

bil_neg <- indik_2019 %>%
  filter(bilance < 0)

bil_neg_sum <- bil_neg %>%
  count(wt = bilance/1e9) %>% pull() %>% abs()

bil_neg_avg <- bil_neg %>%
  summarise(m = mean(bilance_rel, na.rm = T)) %>% pull() %>% abs()

bil_neg_median <- bil_neg %>%
  summarise(m = median(bilance_rel, na.rm = T)) %>% pull() %>% abs()

bil_pos_share <- indik_2019 %>%
  count(wt = (bilance >= 0)/n()) %>% pull()

bil_pos_count <- indik_2019 %>%
  count(wt = bilance >= 0) %>% pull()
bil_neg_count <- indik_2019 %>%
  count(wt = bilance < 0) %>% pull()



dluh <- sum(indik_2019$dluh/1e9, na.rm = T)

dluh_pos_share <- indik_2019 %>%
  count(wt = (dluh > 0)/n()) %>% pull()

dluh_pos_count <- indik_2019 %>%
  count(wt = dluh > 0) %>% pull()

dluh_breach_share <- indik_2019 %>%
  count(wt = (rozp_odp >= 0.6)/n()) %>% pull()

dluh_breach_count <- indik_2019 %>%
  count(wt = rozp_odp >= 0.6) %>% pull()

dluh_breach_median <- mean(indik_2019$rozp_odp, na.rm = T)
dluh_breach_mean <- mean(indik_2019$rozp_odp, na.rm = T)

dluh_pos_mean <- indik_2019 %>%
  filter(dluh > 0) %>%
  summarise(n = mean(rozp_odp_1yr, na.rm = T)) %>% pull()

dluh_pos_mean_last4 <- indik_2019 %>%
  filter(dluh > 0) %>%
  summarise(n = mean(rozp_odp, na.rm = T)) %>% pull()

rez <- sum(indik_2019$kratkodoby_fin_majetek/1e9, na.rm = T)

rez_to_spend_mean <- indik_2019 %>%
  mutate(share = kratkodoby_fin_majetek/rozp_p_celkem) %>%
  summarise(m = mean(share, na.rm = T)) %>% pull()

rez_to_spend_median <- indik_2019 %>%
  mutate(share = kratkodoby_fin_majetek/rozp_p_celkem) %>%
  summarise(m = median(share, na.rm = T)) %>% pull()

rez_10pc_spend <- indik_2019 %>%
  count(wt = (kratkodoby_fin_majetek > rozp_v_celkem * 0.1)/n()) %>% pull()

rez_2xkap <- indik_2019 %>%
  count(wt = (kratkodoby_fin_majetek > rozp_v_kap * 2)/n()) %>% pull()

rez_pha <- indik_2019 %>%
  filter(ico == "00064581") %>% pull(kratkodoby_fin_majetek) %>% {./1e9}

rez_krajska <- indik_2019 %>%
  filter(ico != "00064581" & typobce == "Krajská města a Praha") %>%
  count(wt = kratkodoby_fin_majetek/1e9) %>%
  pull()

rez_pha_share <- rez_pha/rez
rez_krajska_share <- rez_krajska/rez

kzav <- sum(indik_2019$kratkodobe_zavazky/1e9, na.rm = T)
