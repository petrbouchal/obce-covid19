library(statnipokladna)
library(readr)


# kody polozek prijmu z dani rozdelovanych pres RUD
polozky_rud <- c("1111", "1112", "1113", "1119", "1121", "1123", "1129",
                 "1219", "1211")
# kod polozky dane z nemovitosti
polozky_dzn <- c("1511")

# balance sheet items to keep
synuc_dluh <- c("281", "282", "283", "289", "322", "326",
                "362", "451", "452", "453", "456", "457")
rozvaha_keep <- c("AKTIVA","A.","A.I.","A.II.","A.III.","A.IV.","B.",
                  "B.I.","B.II.","B.III.","PASIVA","C.","C.I.","C.II.",
                  "C.III.","C.IV.","D.","D.I.","D.II.","D.III.","D.IV.")


# org metadata

ico_obce <- read_rds("data-processed/ico_obce.rds")
orgs <- read_rds("data-processed/orgs_selected_obce.rds")
katobyv <- sp_get_codelist("katobyv", dest_dir = "data-input")
nuts <- sp_get_codelist("nuts", dest_dir = "data-input")
obce_typy <- read_rds("data-processed/obce_typy.rds")

# budgeting codelist
polozka <- read_rds("data-processed/polozka.rds")

add_obce_meta <- function(data) {
  data$period_vykaz <- lubridate::make_date(data$per_yr, "12", "31")
  data %>%
    sp_add_codelist(orgs) %>%
    select(-kraj) %>%
    sp_add_codelist(nuts, by = "nuts_id") %>%
    sp_add_codelist(katobyv) %>%
    select(-period_vykaz) %>%
    left_join(obce_typy) %>%
    ungroup() %>%
    mutate(katobyv_nazev = fct_reorder(katobyv_nazev, as.numeric(katobyv_id)))
}

# colors

cols <- c("#49b7fc", "#ff7b00", "#17d898", "#ff0083", "#0015ff", "#e5d200",
  "#999999")

Sys.setlocale(locale = "cs_CZ.UTF-8")


# Print functions ---------------------------------------------------------

pc <- function(x, accuracy = 1) {
  ptrr::label_percent_cz(accuracy = accuracy)(x)
}

nm <- function(x, accuracy = 1) {
  ptrr::label_number_cz(accuracy = accuracy)(x)
}
