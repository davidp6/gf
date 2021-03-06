# Final cleaning on PNLS
# Use this to manually aggregate the final variables
# --------------------
# Set up R
rm(list=ls())
library(data.table)
library(ggplot2)
library(dplyr)
library(stringr) 
library(openxlsx)
# --------------------

# shell script for working on the cluster
# sh /share/singularity-images/rstudio/shells/rstudio_qsub_script.sh -p 1247 -s 2 

# --------------------
# set working directories

# detect if operating on windows or on the cluster 
j = ifelse(Sys.info()[1]=='Windows', 'J:', '/home/j')

# set the directory for input and output
dir = paste0(j, '/Project/Evaluation/GF/outcome_measurement/cod/dhis_data/')
setwd(dir)

#---------------------------------------
# load the file that represents a subset (no sex or )

# I think I have changed this to the correct file for you - Caitlin 
dt = readRDS(paste0(dir, 'prepped/pnls_sets/pnls_drug_2017_01_01_2019_02_01.rds'))

#-----------------------------
# export the abbreviated elements for translation

# to do this on the cluster, you must export as an RDS, then use local code to save
# elements = dt[ ,.(element = unique(element)), by=.(element_id)]
set = dt[ ,tolower(unique(pnls_set))]
# 
# # save the list as an excel file 
# write.xlsx(elements, paste0(dir,'meta_data/translate/pnls_elements_to_translate_', set, '.xlsx' )) #Leaving in for documentation; don't need to write over this file. 

# translate using onlinedoctranslator.com and save as file path below
#---------------------

# import the translated elements
new_elements = read.xlsx(paste0(dir,'meta_data/translate/pnls_elements_translations_', set, '.xlsx' ))
setDT(new_elements)

# be sure 
x = merge(elements, new_elements, by=c('element_id', 'element'), all.x=T )
stopifnot(nrow(x[is.na(element_eng)])==0)
setDT(x)
#---------------------------------------

#---------------------------------------------------------------------
# Merge the data and the new English elements together 
new_elements = new_elements[, .(element_id, element_eng, eev_test)]
new_elements[, element_eng:=trimws(element_eng)]
dt = dt[, -c('element_eng')] #Not sure why this is already in here? 

dt = merge(dt, new_elements, by='element_id', all.x = TRUE)
#---------------------------------------------------------------------


#--------------------------------------------------------------------
# Make sure that the totals are correct for the new file 
unique(dt[, .(subpop, element_eng)][order(subpop, element_eng)]) #Visual checks
unique(dt[, .(element_eng)])

#Check what's going on with 'service' variable, and then drop it.
dt[element=='"Femmes enc. ou allaitantes informées des résultats-service', sum(value, na.rm = TRUE)]
dt[element=="Femmes enc. ou allaitantes informées des résultats", sum(value, na.rm = TRUE)]

dt[element=='Femmes enc. ou allaitantes testées-service', sum(value, na.rm = TRUE)] #Flag - these are different values!
dt[element=='Femmes enceintes ou allaitantes testées', sum(value, na.rm = TRUE)]

#Do a deeper dive
table(dt[element=='Femmes enceintes ou allaitantes testées', .(value, level)])
table(dt[element=='Femmes enc. ou allaitantes testées-service', .(value, level)])

#One more pair 
dt[element=='Femmes enc. ou allaitantes conseillées-service', sum(value, na.rm=TRUE)] #These are also slightly off. 
dt[element=='Femmes enceintes ou allaitantes conseillées', sum(value, na.rm = TRUE)]


#Drop out the variables with "service" at the end - doing this by element ID because they don't all have hyphens. 
unique(dt[grep("service", element), .(element, element_id)])
dt = dt[!(element_id == "PnwLDzr2HX8" | element_id == "sIauzwAH8Oo" | element_id == "umSBpgIOOU1" | element_id == "vRJFy0MuKiw" | element_id == "wlm4P0V0ySD")]
unique(dt[grep("service", element), .(element, element_id)])
#---------------------------------------------------------------------

#Save the final file 
saveRDS(dt, paste0(dir, 'prepped/pnls_sets/pnls_pmtct_prepped_2017_01_01_2018_12_01.rds'))


