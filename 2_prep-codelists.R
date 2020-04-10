polozka_raw <- sp_get_codelist("polozka", dest_dir = "data-input/")
polozka <- polozka_raw %>%
  mutate(for2018 = (end_date >=
                      "2018-12-31" & start_date <= "2018-12-31")) %>%
  group_by(polozka, for2018) %>%
  mutate(n = n(),
         duplicate = n() > 1,
         latest = end_date == max(end_date)) %>%
  # View()
  filter(!(for2018 & duplicate & latest)) %>%
  ungroup() %>%
  select(-for2018, -duplicate, -latest, -n)

write_rds(polozka, "data-processed/polozka.rds")
