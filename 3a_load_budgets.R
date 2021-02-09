library(statnipokladna)
library(dplyr)
library(arrow)
library(tidyr)
library(purrr)

yrs <- 2010:2019
arrow_paths <- as.character(yrs)

## create an Arrow dataset for each time period

dir.create(file.path("data-input", "budgets-arrow-partial"))

walk(yrs, ~{
  table <- sp_get_table("budget-local", .x, 12)
  print(table)
  write_dataset(table %>%
                  drop_na(vtab) %>%
                  select(-vykaz, -polozka_typ),
                file.path("data-input", "budgets-arrow-partial", .x),
                partitioning = c("period_vykaz", "per_yr", "per_m", "vtab"),
                format = "parquet")
})

## Load all dataset into one multidataset

arrow_datasets <- map(file.path("data-input", "budgets-arrow-partial", yrs),
                      open_dataset, format = "parquet")
arrow_combined <- open_dataset(arrow_datasets)

## Write

write_dataset(arrow_combined, path = file.path("data-input", "budgets-arrow-all"),
              partitioning = c("period_vykaz", "per_yr", "per_m", "vtab"),
              format = "parquet")

## re-read to check

x <- open_dataset(file.path("data-input", "budgets-arrow-all"),
                  partitioning = hive_partition(period_vykaz = arrow::date32(),
                                                per_yr = int16()))
x
y <- x %>% select(-budget_amended, -budget_adopted) %>% collect()
y

## delete single-period datasets from disk

fs::dir_delete(file.path("data-input", "budgets-arrow-partial"))

