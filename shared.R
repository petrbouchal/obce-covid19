library(statnipokladna)
library(readr)
library(arrow)
library(dplyr)
library(ragg)
library(ptrr)


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

ico_obce <- read_rds("data-transfer/ico_obce.rds")
orgs <- read_parquet("data-transfer/orgs_selected_obce.parquet")
kraje <- read_parquet("data-transfer/kraj_codelist.parquet")
okresy <- read_parquet("data-transfer/okres_codelist.parquet")
nuts <- read_parquet("data-transfer/nuts_codelist.parquet")
katobyv <- read_parquet("data-transfer/katobyv_codelist.parquet")
obce_typy <- read_parquet("data-transfer/obce_typy.parquet")

# budgeting codelist
polozka <- read_parquet("data-transfer/polozka.parquet")

add_obce_meta <- function(data) {
  data$period_vykaz <- lubridate::make_date(data$per_yr, "12", "31")
  data %>%
    sp_add_codelist(orgs) %>%
    # select(-kraj) %>%
    sp_add_codelist(nuts, by = "nuts_id") %>%
    sp_add_codelist(katobyv) %>%
    left_join(okresy) %>%
    left_join(kraje) %>%
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

# Plot transfer functions

plot_save <- function(plot, id) {
  pth <- file.path("charts-storage",
                   paste0(scen_stub, "_", outcome_stub, "_", id, ".rds"))
  message(paste("Saving", pth))
  write_rds(plot, pth)
}

plot_load <- function(id) {
  pth <- file.path("charts-storage",
                   paste0(scen_stub, "_", outcome_stub, "_", id, ".rds"))
  message(paste("Loading", pth))
  read_rds(pth)
}

theme_studie <- function(gridlines = "x",
                         base_size = 12,
                         family = "Helvetica",
                         title_family = "Georgia",
                         multiplot = FALSE,
                         tonecol = 'lightgrey',
                         margin_side = 0,
                         margin_bottom = 6,
                         plot.title.position = "plot",
                         axis_titles = FALSE,
                         richtext = FALSE,
                         plot.title = element_text(colour = "#2526A9"),
                         ...) {
  ptrr::theme_ptrr(gridlines = gridlines,
                   base_size = base_size,
                   family = family,
                   title_family = title_family,
                   multiplot = multiplot,
                   tonecol = tonecol,
                   margin_side = margin_side,
                   margin_bottom = margin_bottom,
                   plot.title.position = plot.title.position,
                   axis_titles = axis_titles,
                   richtext = richtext,
                   plot.title = element_text(colour = "#2526A9", size = 14),
                   ...)
}
