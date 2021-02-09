library(pointblank)
library(arrow)
library(dplyr)
library(magrittr)

indik_slctyr <- read_parquet("data-transfer/indik_slctyr.parquet") %>%
  mutate(pocob = as.integer(pocob))

ag <- create_agent(tbl = indik_slctyr, actions = action_levels(notify_at = 1,
                                                    warn_at = .01, stop_at = .2),
                   embed_report = T) %>%
  rows_distinct(columns = "ico", label = "no ICO repeated") %>%
  rows_distinct(columns = "zuj", label = "no ZUJ repeated") %>%
  col_vals_expr(expr(!is.na(ico) & ico != ""), label = "ICO present") %>%
  col_vals_expr(expr(!is.na(zuj) & zuj != ""), label = "ZUJ present") %>%
  col_vals_gte(dluh, 0) %>%
  col_vals_lt(rozp_p_celkem, 5e9, label = "only a few with income > 5bn",
              actions = action_levels(stop_at = 13)) %>%
  col_vals_expr(expr(rozp_v_bezne <= rozp_v_celkem), actions = action_levels(stop_at = 1)) %>%
  col_vals_expr(expr(rozp_v_kap <= rozp_v_celkem)) %>%
  col_vals_expr(expr(rozp_v_kap < rozp_v_bezne)) %>%
  col_vals_between()
  col_vals_between(pocob, 10, 1.4e6) %>%
  col_vals_regex(ico, "[0-9]{8}") %>%
  col_vals_regex(zuj, "5[0-9]{5}") %>%
  col_vals_gt(rozp_v_celkem, 100000) %>%
  interrogate()

ag

ag %>%
  pointblank::get_data_extracts(8) %>%
  select(orgs_ucjed_nazev, starts_with("rozp_v"))

testthat::test
