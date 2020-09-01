library(readr)
library(arrow)
library(stringr)

fls_dp <- fs::dir_ls("data-processed", glob = "*.parquet")

rds_converted_dp <- c()
for(fl in fls_dp) {
  fl_new <- str_replace(fl, "\\.rds$", ".parquet")

  dt <- read_rds(fl)
  print(fl)
  if(is.data.frame(dt)) {
    write_parquet(dt, fl_new)
    print(fl_new)
    rds_converted_dp <- c(rds_converted_dp, fl)
  }
}

fls_di <- fs::dir_ls("data-input", glob = "*.parquet")

rds_converted_di <- c()
for(fl in fls_di) {
  fl_new <- str_replace(fl, "\\.rds$", ".parquet")

  dt <- read_rds(fl)
  print(fl)

  if(is.data.frame(dt)) {
    write_parquet(dt, fl_new)
    print(fl_new)
    rds_converted_di <- c(rds_converted_di, fl)
  }
}

rds_converted_di
rds_converted_dp

fs::file_delete(rds_converted_di)
fs::file_delete(rds_converted_dp)

