p_obce <- 0.2358
p_kraje <- 0.0892
hdp_pokles <- 5.6

if (!file.exists("data-input/fs_inkaso.xls")) {
  fs_inkaso_excel <- curl::curl_download("https://www.financnisprava.cz/assets/cs/prilohy/d-danova-statistika/Inkasa_dani_1993-2019_grafy.xls",
                                         "data-input/fs_inkaso.xls")
}
inkaso_fs <- readxl::read_excel(fs_inkaso_excel, skip = 3)

dane_meta <- tribble(
  ~dan,                                             ~rud, ~dzn,   ~podil_obce, ~podil_kraje, ~elasticita,
  "Daň z příjmů právnických osob",                   TRUE,  FALSE, p_obce,      p_kraje,      1.23,
  "Daň z přidané hodnoty celkem*)",                  TRUE,  FALSE, p_obce,      p_kraje,      1,
  "Daň z příjmů fyzických osob z přiznání",          TRUE,  FALSE, p_obce,      p_kraje,      2.23,
  "Daň z příjmů fyzických osob ze závislé činnosti", TRUE,  FALSE, p_obce,      p_kraje,      2.23,
  "Daň z příjmů vybíraná srážkou § 36",              TRUE,  FALSE, p_obce,      p_kraje,      2.23,
  "Daň z nemovitých věcí",                           TRUE,  FALSE, 1,           0,            0
) %>%
  mutate(podil_stat = 1 - (podil_obce + podil_kraje))

elasticate <- function(inkaso_fs, dane_meta, hdp_pokles) {
  inkaso_fs_2019 <- inkaso_fs %>%
    select(dan = `D R U H   P Ř Í J M U`, inkaso = `2019`) %>%
    left_join(dane_meta) %>%
    pivot_longer(cols = matches("podil_"), names_to = "sektor", values_to = "podil") %>%
    mutate(prijem = inkaso * podil,
           after_shock = prijem * (100 - hdp_pokles * elasticita) / 100,
           sektor = str_remove(sektor, "podil_")) %>%
    filter(!is.na(elasticita)) %>%
    group_by(sektor) %>%
    summarise(prijem = sum(prijem), prijem_shocked = sum(after_shock)) %>%
    mutate(drop = prijem_shocked - prijem, drop_pct = drop/prijem,
           hdp_drop = hdp_pokles)
}

inputs <- seq(from = 0, to = 100, by = 10) %>%
  purrr::set_names(seq(from = 0, to = 100, by = 10))

propady <- purrr::map_dfr(inputs,  ~elasticate(inkaso_fs, dane_meta, .x))

propady %>%
  select(sektor, drop_pct, hdp_drop) %>%
  spread(sektor, drop_pct)

write_parquet(propady, "data-input/gdp-to-tax.parquet")
