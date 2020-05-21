indikatory %>%
  filter(per_yr %in% 2019:2022) %>%
  # filter(ico == "00064581") %>%
  group_by(ico) %>%
  filter(min(kratkodoby_fin_majetek) == 0) %>%
  select(per_yr, scenario, bilance, bilance_rel, dluh,
         kratkodoby_fin_majetek, cash_drain_to_sum) %>%
  arrange(ico, scenario, per_yr) %>% View()

indikatory %>%
  filter(per_yr > 2017) %>%
  count(per_yr, scenario, scenario_name, wt = kratkodoby_fin_majetek/1e9) %>%
  spread(per_yr, n) %>%
  View()

indikatory %>%
  filter(per_yr %in% 2019:2020) %>%
  group_by(per_yr, scenario, scenario_name, dph_change, rud_change, borrowing_ratio,
           kraj) %>%
  summarise(n = sum(kratkodoby_fin_majetek == 0)/n()) %>%
  View()

indikatory %>%
  filter(per_yr %in% 2019:2020, dph_change == rud_change) %>%
  drop_na() %>%
  group_by(per_yr, scenario, scenario_name, rud_change, borrowing_ratio,
           typobce
           ) %>%
  summarise(n = sum(kratkodoby_fin_majetek == 0)/n()) %>%
  ggplot(aes(n, as.factor(typobce))) +
  geom_col() +
  facet_grid(rud_change ~ borrowing_ratio)
