#!/usr/bin/env Rscript

source("1_load-orgs.R")
source("2_prep-codelists.R")
source("3_load-budgets.R")
source("4_summarise-budgets-druhove.R")
source("5_budget-balance.R")
source("6_load-balance-sheets.R")
source("7_prep-for-indicators.R")
source("7a_calculate-tax-drop.R")
source("8_calculate-indicators.R")
source("9_calculate-scenarios.R")

source("build_word.R")
rmarkdown::render_site()

source("cisla_report_stav.R")

rmarkdown::render("studie-idea.Rmd", output_format = rmarkdown::word_document())
