library(remotes)
library(statnipokladna)
library(czso)
library(readxl)
library(tidyverse)
library(stargazer)

# municipality IDs ( mun_database <- list of municipalities and their code, ICO, district,...)

mun_database <- read_excel("rozvaha_vykaz_final/mun_database2.xlsx")
kraje_okresy<-read_excel("rozvaha_vykaz_final/kraje_okresy.xlsx")
mun_database$`NUTS 3`<-kraje_okresy$`NUTS 3`[match(mun_database$`LAU 1`,kraje_okresy$LAU1)]
mun_database$`NUTS 3 name`<-kraje_okresy$`NUTS 3 name`[match(mun_database$`LAU 1`,kraje_okresy$LAU1)]
mun_database$`LAU 1 name`<-kraje_okresy$`LAU1 name`[match(mun_database$`LAU 1`,kraje_okresy$LAU1)]
rm(kraje_okresy)
mun_data <- read_excel("rozvaha_vykaz_final/mun_database.xlsx")
mun_database$ICO<-mun_data$ICO[match(mun_database$mun_id,mun_data$mun_id)]
rm(mun_data)
names(mun_database)<-c("mun_id","ICO","mun","LAU1_id","LAU1","NUTS3_id","NUTS3","SOORP_id","SOORP","mun_type")
mun_database$ICO[c(1285, 2317, 2323, 5309, 5327, 5514)]<-c(04498356,04498682,04498691,04521811,
                                                           04498704,04498712) # correcting missing values
mun_database<-as.data.frame(mun_database)

## ROZVAHA
  # creating dataset "balance_sheet"

# code for 2010-2011 (due to different codelist than other years)
  # download dataset, filter municipalities and main categories of dataset, add names (items and municipalities)
  # loop produces dataset for each year: "bal_2010" etc.

rozvaha_codelist_1011 <- read_excel("rozvaha_vykaz_final/rozvaha_codelist_10-11.xlsx")
for(i in 2010:2011){
  balancesheet<-sp_get_table(table_id = "balance-sheet",dest_dir = ".",year=i)
  balancesheet$mun_id<-mun_database$mun_id[match(balancesheet$ico,mun_database$ICO)] # add municipality id
  balancesheet<-balancesheet[is.na(balancesheet$mun_id)==F,] # filter municipalities
  balancesheet<-balancesheet %>% filter(polvyk %in% c("AKTIVA","A.","A.I.","A.II.","A.III.","A.IV.","B.",
                                                      "B.I.","B.II.","B.III.","PASIVA","C.","C.I.","C.II.",
                                                      "C.III.","C.IV.","D.","D.I.","D.II.","D.III.","D.IV."))

  rozvaha_codelist<-as.data.frame(rozvaha_codelist)
  colnames(balancesheet)[11]<-"polozka"
  balancesheet$polozka<-rozvaha_codelist[match(balancesheet$polvyk,rozvaha_codelist$code),2] # assign names
  rm(rozvaha_codelist)
  balancesheet$mun<-mun_database[match(balancesheet$mun_id,mun_database$mun_id),3] # add municipality name
  balancesheet<-balancesheet[c(3,6,17,18,10:15)]
  assign(paste("bal_",i,sep = ""),balancesheet)
}

# code for 2012 (since the dataset is in one file)
    # same as previous

balancesheet<-sp_get_table(table_id = "balance-sheet",dest_dir = ".",year=2012)
balancesheet$mun_id<-mun_database$mun_id[match(balancesheet$ico,mun_database$ICO)] #add municipality id
balancesheet<-balancesheet[is.na(balancesheet$mun_id)==F,] #filter municipalities
balancesheet<-balancesheet %>% filter(polvyk %in% c("AKTIVA","A.","A.I.","A.II.","A.III.","A.IV.","B.",
                                                      "B.I.","B.II.","B.III.","PASIVA","C.","C.I.","C.II.",
                                                      "C.III.","C.IV.","D.","D.I.","D.II.","D.III."))
rozvaha_codelist <- read_excel("rozvaha_vykaz_final/rozvaha_codelist.xlsx")
rozvaha_codelist<-as.data.frame(rozvaha_codelist)
colnames(balancesheet)[11]<-"polozka"
balancesheet$polozka<-rozvaha_codelist[match(balancesheet$polvyk,rozvaha_codelist$code),2] #assign names
rm(rozvaha_codelist)
balancesheet$mun<-mun_database[match(balancesheet$mun_id,mun_database$mun_id),3]
balancesheet<-balancesheet[c(3,6,17,18,10:15)]
bal_2012<-balancesheet

# code for 2013-2019 (dataset separated to 2 files)
    #same as previous

for(i in 2013:2019){
balancesheet<-sp_get_table(table_id = "balance-sheet",dest_dir = ".",year=i)
balancesheet2<-sp_get_table(table_id = "balance-sheet-2",dest_dir = ".",year=i)
balancesheet<-rbind(balancesheet,balancesheet2)
rm(balancesheet2)
balancesheet$mun_id<-mun_database$mun_id[match(balancesheet$ico,mun_database$ICO)] #add municipality id
balancesheet<-balancesheet[is.na(balancesheet$mun_id)==F,] #filter municipalities
balancesheet<-balancesheet %>% filter(polvyk %in% c("AKTIVA","A.","A.I.","A.II.","A.III.","A.IV.","B.",
                                                    "B.I.","B.II.","B.III.","PASIVA","C.","C.I.","C.II.",
                                                    "C.III.","C.IV.","D.","D.I.","D.II.","D.III."))
rozvaha_codelist <- read_excel("rozvaha_vykaz_final/rozvaha_codelist.xlsx")
rozvaha_codelist<-as.data.frame(rozvaha_codelist)
colnames(balancesheet)[11]<-"polozka"
balancesheet$polozka<-rozvaha_codelist[match(balancesheet$polvyk,rozvaha_codelist$code),2] #assign names
rm(rozvaha_codelist)
balancesheet$mun<-mun_database[match(balancesheet$mun_id,mun_database$mun_id),3]
balancesheet<-balancesheet[c(3,6,17,18,10:15)]
assign(paste("bal_",i,sep = ""),balancesheet)
}

# merging into one dataset "balance_sheet"

balance_sheet<-rbind(bal_2010,bal_2011,bal_2012,bal_2013,
                     bal_2014,bal_2015,bal_2016,bal_2017,
                     bal_2018,bal_2019)
rm(bal_2010,bal_2011,bal_2012,bal_2013,
   bal_2014,bal_2015,bal_2016,bal_2017,
   bal_2018,bal_2019,balancesheet)
balance_sheet<-as.data.frame(balance_sheet)

# adding inhabitants and inhab. category

inhab_categ<-read_excel("rozvaha_vykaz_final/inhabitants_category.xlsx")
inhab_categ<-as.data.frame(inhab_categ)
names(inhab_categ)<-c("per_yr","mun_id","categ","inhabitants","katobyv_id")
balance_sheet$inhab<-inhab_categ[match(paste(balance_sheet$mun_id,balance_sheet$per_yr),
                                             paste(inhab_categ$mun_id,inhab_categ$per_yr)),4]

balance_sheet$inhab_categ_id<-inhab_categ[match(paste(balance_sheet$mun_id,balance_sheet$per_yr),
                                             paste(inhab_categ$mun_id,inhab_categ$per_yr)),5]
rm(inhab_categ)
kat_obyv<-sp_get_codelist("katobyv")
kat_obyv<-as.data.frame(kat_obyv)
balance_sheet$inhab_categ<-kat_obyv[match(balance_sheet$inhab_categ_id,kat_obyv$katobyv_id),2]
rm(kat_obyv)

# ukazatele (nov? dataset na ukazatele: Pod?l ciz?ch zdroju a Celkov? likvidita)
    # prvn? polozku beru jako subset balance_sheet a d?l pres match prid?v?m dals? promenn?
    # ukazatele <- hodnoty ukazatelu a promenn? potrebn? k jejich v?poctu (pro vsechny roky a vsechny obce)
ukazatele<-balance_sheet[balance_sheet$polvyk=="D.",c(1:4,11:13,9)]
colnames(ukazatele)[8]<-"cizi_zdroje_netto"
ukazatele$aktiva_celkem_brutto<-
  balance_sheet[match(paste(ukazatele$mun_id,ukazatele$per_yr,"AKTIVA"),
                      paste(balance_sheet$mun_id, balance_sheet$per_yr,balance_sheet$polvyk)),7]
ukazatele$podil_cizich_zdroju<-ukazatele$cizi_zdroje_netto/ukazatele$aktiva_celkem_brutto
ukazatele<-as.data.frame(ukazatele)

ukazatele$obezna_aktiva<- balance_sheet[match(paste(ukazatele$mun_id,ukazatele$per_yr,"B."),
                                                  paste(balance_sheet$mun_id, balance_sheet$per_yr,
                                                        balance_sheet$polvyk)),9]
ukazatele$kratkodob_zavazky<- balance_sheet[match(paste(ukazatele$mun_id,ukazatele$per_yr,"Kr?tkodob? z?vazky"),
                                              paste(balance_sheet$mun_id, balance_sheet$per_yr,
                                                    balance_sheet$polozka)),9]
ukazatele$celkova_likvidita<-ukazatele$obezna_aktiva/ukazatele$kratkodob_zavazky

## V?KAZ ZISKU A ZTR?T
    # loop na stazen? vsech datasetu, vyhod? dataset pro kazd? rok: "vyk_2010" atd.
    # d?le je dataset zpracov?n podobne jako Rozvaha (akor?t pouz?v?m ofic. c?seln?k na jm?na polozek)

for(i in 2010:2019){
  vykaz<-sp_get_table(table_id = "profit-and-loss",dest_dir = ".",year=i)
  vykaz$mun_id<-mun_database$mun_id[match(vykaz$ico,mun_database$ICO)] #add municipality id
  vykaz<-vykaz[is.na(vykaz$mun_id)==F,] #filter municipalities
  assign(paste("vyk_",i,sep = ""),vykaz)
}
#merge datasets
vykaz<-rbind(vyk_2010,vyk_2011,vyk_2012,vyk_2013,vyk_2014,vyk_2015,vyk_2016,vyk_2017,vyk_2018,vyk_2019)
rm(vyk_2010,vyk_2011,vyk_2012,vyk_2013,vyk_2014,vyk_2015,vyk_2016,vyk_2017,vyk_2018,vyk_2019)
vykaz<-vykaz%>%sp_add_codelist("polvyk") # assign names to items
inhab_categ<-read_excel("rozvaha_vykaz_final/inhabitants_category.xlsx") # dataset with numbers of inhabitants
inhab_categ<-as.data.frame(inhab_categ)
names(inhab_categ)<-c("per_yr","mun_id","categ","inhabitants","katobyv_id")
vykaz$inhab<-inhab_categ[match(paste(vykaz$mun_id,vykaz$per_yr),
                                       paste(inhab_categ$mun_id,inhab_categ$per_yr)),4]
vykaz$inhab_categ_id<-inhab_categ[match(paste(vykaz$mun_id,vykaz$per_yr),
                                                paste(inhab_categ$mun_id,inhab_categ$per_yr)),5]
rm(inhab_categ) # inhabitants added
kat_obyv<-sp_get_codelist("katobyv")
kat_obyv<-as.data.frame(kat_obyv)
vykaz$inhab_categ<-kat_obyv[match(vykaz$inhab_categ_id,kat_obyv$katobyv_id),2] # number of inhab. category
rm(kat_obyv)
vykaz$mun<-mun_database[match(vykaz$mun_id,mun_database$mun_id),3]
vykaz<-vykaz[c(3,6,17,26,10,18,12:15,23:25)] # reorganise columns (consistently with balance_sheet)





# vec nav?c: grafy ukazatelu co jsem pos?lal mailem
  # Pod?l ciz?ch zdroju
ukazatele %>%filter(podil_cizich_zdroju<0.3&podil_cizich_zdroju>-0.05)%>%
  ggplot(aes(x=per_yr,y=podil_cizich_zdroju,group=per_yr))+geom_boxplot(alpha=.1)+
  facet_wrap(~inhab_categ_id)

ukazatele %>%filter(podil_cizich_zdroju<1&podil_cizich_zdroju>-0.2&per_yr==2019)%>%ggplot(aes(x=inhab,y=podil_cizich_zdroju))+
  geom_point(size=0.1)+ scale_x_continuous("velikost obce", trans = "log",breaks = c(100,1000,11000,70000,1000000))+
  scale_y_continuous("Podil cizich zdroju")
  # Celkov? likvidita
ukazatele %>% filter(celkova_likvidita<100&celkova_likvidita>-10) %>%
  ggplot(aes(x=per_yr,y=celkova_likvidita,group=per_yr))+geom_boxplot(alpha=.1)+
  facet_wrap(~inhab_categ_id)

ukazatele %>%filter(celkova_likvidita<200&celkova_likvidita>-10&per_yr==2019)%>%
  ggplot(aes(x=inhab,y=celkova_likvidita))+
  geom_point(size=0.1)+ scale_x_continuous("velikost obce", trans = "log",breaks = c(100,1000,11000,70000,1000000))+
  scale_y_continuous("celkova likvidita")

