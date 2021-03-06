#-------------------------------------------
# AUTHOR: Emily Linebarger 
# DATE: January 2020 
# PURPOSE: Compare old and new modular frameworks, 
# and merge so that old codes can be converted to new ones
#-------------------------------------------

rm(list=ls())
library(data.table) 
library(readxl)

#----------------------------------
# LOAD DATA 
#----------------------------------
old = readRDS("J:/Project/Evaluation/GF/resource_tracking/modular_framework_mapping/all_interventions.rds")
old = old[, .(module_eng, intervention_eng, disease, code)]
setnames(old, c('module_eng', 'intervention_eng'), c('module', 'intervention'))

new_hiv = data.table(read_xlsx("J:/Project/Evaluation/GF/resource_tracking/modular_framework_mapping/2020-2022 Modular Framework.xlsx", sheet="HIV Interventions"))
new_hiv[, disease:="hiv"]
new_tb = data.table(read_xlsx("J:/Project/Evaluation/GF/resource_tracking/modular_framework_mapping/2020-2022 Modular Framework.xlsx", sheet="TB Interventions"))
new_tb[, disease:="tb"]
new_malaria = data.table(read_xlsx("J:/Project/Evaluation/GF/resource_tracking/modular_framework_mapping/2020-2022 Modular Framework.xlsx", sheet="Malaria Interventions"))
new_malaria[, disease:="malaria"]
new_rssh = data.table(read_xlsx("J:/Project/Evaluation/GF/resource_tracking/modular_framework_mapping/2020-2022 Modular Framework.xlsx", sheet="RSSH Interventions"))
new_rssh[, disease:="rssh"]

new = rbindlist(list(new_hiv, new_tb, new_malaria, new_rssh), fill=T, use.names=T)
new = new[, .(module, intervention, population, disease, code)]

setnames(old, c('disease', 'code'), c('disease_old', 'code_old'))
setnames(new, c('disease', 'code'), c('disease_new', 'code_new'))


# Create a modified copy to merge onto the new file 
#------------------------------------
# OLD FRAMEWORK 
#------------------------------------
old_modified = copy(old) 

#-----------------------------
# GENERAL 
old_modified = old_modified[!(intervention=="Unspecified" | intervention=="Performance Based Financing")] #These were added to MF by IHME. 

#-----------------------------
# HIV
old_modified[grepl("Addressing stigma, discrimination and violence", intervention), intervention:="Addressing stigma, discrimination, and violence"]
old_modified[grepl("Behavioral interventions|Behavioral change", intervention), intervention:="Behavior change interventions"]
old_modified[grepl("Community empowerment for", intervention), intervention:="Community empowerment"]
old_modified[grepl("Condoms and lubricant programming", intervention), intervention:="Condom and lubricant programming"]
old_modified[grepl("Diagnosis and treatment of sexually transmitted infections", intervention), intervention:="Sexual and reproductive health services, including STIs"]
old_modified[grepl("Pre-exposure prophylaxis", intervention), intervention:="Pre-exposure prophylaxis"]
old_modified[grepl("Prevention and management of coinfections|Prevention and management of co-infections", intervention), intervention:="Prevention and management of co-infections and co-morbidities"]
old_modified[grepl("Needle and syringe programs", intervention), intervention:="Needle and syringe programs"]
old_modified[grepl("Opiod substitution therapy", intervention), intervention:="Opiod substitution therapy and other medically assisted drug dependence treatment"]
old_modified[intervention=="Interventions for young people who inject drugs", intervention:="Interventions for young Key Populations"]
old_modified[module=="Prevention of mother-to-child transmission", module:="PMTCT"]
old_modified[module=="Prevention programs for adolescents and youth, in and out of school", 
             module:="Comprehensive prevention programs for adolescents and youth, in and out of school"]
old_modified[module=="Comprehensive programs for people in prisons and other closed settings", 
             module:="Comprehensive prevention programs for people in prisons and other closed settings"]
old_modified[module=="Prevention programs for general population",
             module:="Comprehensive prevention programs for non-specified population groups"]
old_modified[module=="Prevention programs for other vulnerable populations", 
             module:="Comprehensive prevention programs for other vulnerable populations"]
old_modified[intervention=="Opioid substitution therapy and other drug- dependence treatment for people who inject drugs", 
             intervention:="Opiod substitution therapy and other medically assisted drug dependence treatment"]
old_modified[grepl("Interventions for young", intervention), intervention:="Interventions for young Key Populations"]
old_modified[grepl("Harm reduction interventions", intervention), intervention:="Harm reduction interventions for drug use"]
old_modified[module=="Programs to reduce human rights-related barriers to HIV services", 
             module:="Reducing human rights-related barriers to HIV/TB services"]
old_modified[intervention=="HIV and HIV/TB-related legal services", intervention:="HIV and HIV/TB related legal services"]

#-----------------------------
# TB
old_modified[module=="Multidrug-resistant TB", module:="MDR-TB"]
old_modified[, intervention:=gsub(": MDR-TB", "", intervention)]
old_modified[, intervention:=gsub(" \\(MDR\\-TB\\)", "", intervention)]
old_modified[, intervention:=gsub(" \\(TB/HIV\\)", "", intervention)]

#-----------------------------
# Malaria
old_modified[module=="Case management" & intervention=="Ensuring drug and other health product quality", intervention:="Ensuring drug quality"]
old_modified[module=="Case management" & intervention=="Information, education, communication/behavior change communication (case management)", intervention:="IEC/BCC"]
old_modified[intervention=="Other case management intervention(s)", intervention:="Other case management interventions"]
old_modified[intervention=="Removing human rights- and gender- related barriers to case management", intervention:="Removing human rights and gender related barriers to case management"]

#------------------------------
# RSSH
old_modified[module=="Community responses and systems", module:="Community systems strengthening"]
old_modified[intervention=="Community-led advocacy", intervention:="Community-led advocacy and research"]
old_modified[intervention=="Social mobilization, building community linkages, collaboration and coordination", 
             intervention:="Social mobilization, building community linkages, and coordination"]
old_modified[module=="Health management information system and monitoring and evaluation", module:="Health management information systems and M&E"]
old_modified[intervention=="Administrative and financial data sources", intervention:="Administrative and finance data sources"]
old_modified[intervention=="Analysis, review and transparency", intervention:="Analysis, evaluations, reviews and transparency"]

old_modified = unique(old_modified)
#--------------------

# Make a new copy to manually edit modules/interventions. 
new_modified = copy(new) 
new_modified[module=="Prevention", module:=paste0("Comprehensive prevention programs for ", tolower(population))]
new_modified = unique(new_modified) 

#Merge this modified dataset
merge = merge(old_modified, new_modified, by=c('module', 'intervention'), all=T)
nrow(merge[is.na(code_new), .(module, intervention, population, disease_new)][order(module, intervention, population, disease_new)])
View(merge[is.na(code_new) & disease_old=="rssh", .(module, intervention, population, disease_new)][order(module, intervention, population, disease_new)])


## How many modules/interventions and indicators are there? 

## What are the main new modules/interventions? 

## Did any modules/interventions get dropped? 
