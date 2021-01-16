polozka_raw <- sp_get_codelist("polozka")
polozka <- polozka_raw %>%
  # fix codes where end date is before start date
  mutate(end_date = if_else(polozka %in% c("1381", "2326") & end_date == "2018-09-30",
                            as.Date("9999-12-31"), end_date),
  # detect codes in problematic 2018 periods
         for2018 = (end_date >=
                      "2018-12-31" & start_date <= "2018-12-31")) %>%
  group_by(polozka, for2018) %>%
  mutate(n = n(),
         duplicate = n() > 1,
         latest = end_date == max(end_date)) %>%
  # View()
  # filter duplicates out
  filter(!(for2018 & duplicate & latest)) %>%
  ungroup() %>%
  # fix lines where no relevant code line exists for 2019 data because the *_date columns are wrong
  mutate(end_date = ifelse(start_date == "2019-01-01" & start_date > end_date,
                           as.Date("9999-12-31"), end_date)) %>%
  select(-for2018, -duplicate, -latest, -n)

write_parquet(polozka, "data-shared/polozka.parquet")
