# read in all of the imputed data files by dps created by run_amelia and 
# calculate mean and upper/lower quantiles to condense the rounds of imputation
# do this across the 50 imputations, by hz, dps, and at the country level

# TO DO : healthFacilitiesProportion variable is NA for a lot
# ----------------------------------------------     


# --------------------  
# Set up R / install packages
library(data.table)
library(stringr)
library(reshape2)
library(ggplot2)
# --------------------  


# ----------------------------------------------
# Overview - Files and Directories

# data directory
# when run on Unix, data directory needs to be set to /home/j (to run on the cluster), so set this here:
j = ifelse(Sys.info()[1]=='Windows', 'J:', '/home/j')
dir = paste0(j, '/Project/Evaluation/GF/outcome_measurement/cod/prepped_data/PNLP/')

# input file:
dt <- readRDS(paste0(dir, 'imputedData_run2.rds'))

# output files:
  imputed_data_long <- "imputedData_run2_long.rds"
  imputed_data_long_corrected <- "imputedData_run2_long_corrected.rds"
  condensed_imputed_data_dps <- "imputedData_run2_condensed_dps.rds"
  condensed_imputed_data_country <- "imputedData_run2_condensed_country.rds"
  condensed_imputed_data_hz <- "imputedData_run2_condensed_hz.rds"
  
all_vars <- c(colnames(dt))
id_vars <- c("province", "dps", "health_zone", "date")
indicators <- all_vars[!all_vars %in% id_vars] 
indicators <- indicators[!indicators %in% c("V1")]
indicators <- indicators[!indicators %in% c("imputation_number")]
# ----------------------------------------------


# ----------------------------------------------    
# Set up a data table for graphing:
imputed_id_vars <- c('province', 'dps', 'health_zone', 'date', 'id', 'imputation_number')

# reshape imputed data long
imputedDataLong <- melt(dt, id.vars=c(imputed_id_vars))
imputedDataLong$id <- NULL
imputedDataLongSplit <- imputedDataLong[, c("indicator", "subpopulation") := tstrsplit(variable, "_", fixed=TRUE)]

# save data in this format (since it takes a while to run), so it can be used later on if the code breaks somewhere before all versions of the dt are produced
saveRDS(imputedDataLongSplit, paste0(dir, imputed_data_long))
# ----------------------------------------------


# ----------------------------------------------
# original data to merge to fix zeroes in the data
# read in data table prepped by prep_for_MI.R
input <- "final_data_for_impuation.csv"
dtOrig <- fread(paste0(dir, input)) 
dtOrig <- dtOrig[, V1:=NULL]

for (i in indicators) {
  dtOrig$i <- as.double(dtOrig$i)
}

missMatrixMelt <- melt(dtOrig, id.vars=c(id_vars, "id"))
missMatrixMelt[, isMissing:=is.na(value)]
missMatrixMelt$date <- as.Date(missMatrixMelt$date)

test <- merge(imputedDataLongSplit, missMatrixMelt, all=T, by= c(id_vars, "variable"))

# when the original value was 0, set the imputed values to be zero:
setnames(test, "value.x", "imp_value")
setnames(test, "value.y", "orig_value")
test[orig_value==0, imp_value:=0]

saveRDS(test, paste0(dir, imputed_data_long_corrected ))

# if starting from here, read in the long imputed data, with zeroes corrected
dt <- readRDS(paste0(dir, imputed_data_long_corrected))
# ----------------------------------------------

# # ----------------------------------------------
# Calculate by health_zone

# for some reason there are NAs in these variables (i was just an index var?), but there shouldn't be NAs
# in imputed data, and there can't be to calculate quantile unless na.rm=T; but to make sure there aren't
# NAs present in the other data that we don't, I'll just remove these two variables and not use na.rm=T
dt2 <- dt[variable != "healthFacilitiesProportion"]
dt3 <- dt2[variable != "i"]

# compute upper middle and lower for the imputed points for the error bars in the graphs
graphData <- dt3[, .(mean=mean(imp_value),
                    lower=quantile(imp_value, .05),
                    upper=quantile(imp_value, .95)), by=c(id_vars, "variable", "indicator", "subpopulation")]

# get rid of lower and upper values for values that were NOT missing, so these don't show up on the graph
graphDataComplete <- graphDataComplete[isMissing==F, lower:= NA ]
graphDataComplete <- graphDataComplete[isMissing==F, upper:= NA ]

# export graphDataComplete
# write.csv(graphDataComplete, "J:/Project/Evaluation/GF/outcome_measurement/cod/prepped_data/Imputed Data.csv")
saveRDS(graphDataComplete, paste0(output_dir, condensed_imputed_data_hz))
# # ----------------------------------------------


# ----------------------------------------------
# Aggregate first and then calculate mean and variance by DPS

# aggregate all indicator/intervention data by dps, within each imputation
aggData  <- dt3[, .(aggValue = sum(imp_value)), by=c( "date", "province", "dps", "indicator", "subpopulation", "imputation_number" )]

# then compute the mean, upper and lower across all imputations for each unique dps/date
aggData <- aggData[, .(mean=mean(aggValue), 
                       lower=quantile(aggValue, .05), 
                       upper=quantile(aggValue, .95)), by=c("date", "province", "dps", "indicator", "subpopulation")]

# set upper and lower values to NA where the value was not imputed (where mean==lower and mean==upper)
aggData <- aggData[mean==lower, lower := NA]
aggData <- aggData[mean==upper, upper := NA]

# export data
# write.csv(graphDataComplete, "J:/Project/Evaluation/GF/outcome_measurement/cod/prepped_data/Imputed Data.csv")

saveRDS(aggData, paste0(dir, condensed_imputed_data_dps))
# ----------------------------------------------


# ----------------------------------------------    
# Aggregate and calculate at the country level to graph national values

# aggregate all indicator/intervention data by dps, within each imputation
fullCountryData  <- dt3[, .(aggValue = sum(imp_value)), by=c( "date", "indicator", "subpopulation", "imputation_number" )]

# then compute the mean, upper and lower across all imputations for each unique dps/date
fullCountryData <- fullCountryData[, .(mean=mean(aggValue), 
                                       lower=quantile(aggValue, .05), 
                                       upper=quantile(aggValue, .95)), by=c("date", "indicator", "subpopulation")]

# set upper and lower values to NA where the value was not imputed (where mean==lower and mean==upper)
fullCountryData <- fullCountryData[mean==lower, lower := NA]
fullCountryData <- fullCountryData[mean==upper, upper := NA]

# export data
# write.csv(graphDataComplete, "J:/Project/Evaluation/GF/outcome_measurement/cod/prepped_data/Imputed Data.csv")
saveRDS(fullCountryData, paste0(dir, condensed_imputed_data_country))
# ----------------------------------------------          