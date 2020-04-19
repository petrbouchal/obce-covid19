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
katobyv <- sp_get_codelist("katobyv", dest_dir = "data-input")
orgs <- read_rds("data-processed/orgs_selected.rds")
katobyv <- sp_get_codelist("katobyv", dest_dir = "data-input")
nuts <- sp_get_codelist("nuts", dest_dir = "data-input")

# budgeting codelist
polozka <- read_rds("data-processed/polozka.rds")
