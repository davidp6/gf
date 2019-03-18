# --------------------------------------------------
# David Phillips
# 
# 1/26/2019
# Script that loads packages and file names
# Intended to be called by 1_master_file.r
# This exists just for code organizational purposes
# (use /ihme/singularity-images/health_fin/forecasting/shells/health_fin_forecasting_Rterm.sh on IHME's new cluster)
# --------------------------------------------------

# to do
# make this work on the cluster (it fails to load lubridate and other packages)

# ------------------
# Load packages
set.seed(1)
library(data.table)
library(lubridate)
library(readxl)
library(stringr)
library(ggplot2)
library(stats)
library(Rcpp)
library(grid)
library(gridExtra)
library(ggrepel)
library(boot)
library(lavaan)
library(blavaan)
library(viridis)
library(Hmisc)
# library(lavaanPlot)
# library(semPlot)
library(raster)
library(parallel)
# ------------------


# ---------------------------------------------------------------------------------
# Directories

# switch J for portability to cluster
j = ifelse(Sys.info()[1]=='Windows', 'J:', '/home/j')

# directories
dir = paste0(j, '/Project/Evaluation/GF/')
ieDir = paste0(dir, 'impact_evaluation/cod/prepped_data/')
rtDir = paste0(dir, 'resource_tracking/multi_country/mapping/')
mapDir = paste0(dir, '/mapping/multi_country/intervention_categories')
pnlpDir = paste0(dir, 'outcome_measurement/cod/prepped_data/PNLP/post_imputation/')
dhisDir = paste0(dir, 'outcome_measurement/cod/dhis_data/prepped/')
lbdDir = paste0(j, '/WORK/11_geospatial/01_covariates/00_MBG_STANDARD/')
# ---------------------------------------------------------------------------------


# ------------------------------------------------------------------------
# Supporting Files

# code-friendly version of indicator map file
indicatorMapFile = paste0(ieDir, 'DRC Indicator map - to code from.xlsx')

# list of interventions and codes
mfFile = paste0(mapDir, '/intervention_and_indicator_list.xlsx')
# ------------------------------------------------------------------------


# ---------------------------------------------------------------------------------
# Inputs files

# resource tracking files with prepped budgets, expenditures, disbursements
budgetFile = paste0(rtDir, 'final_budgets.rds')
expendituresFile = paste0(rtDir, 'final_expenditures.rds')
fghFile = paste0(rtDir, 'prepped_current_fgh.csv')

# activities/outputs files
pnlpFile = paste0(pnlpDir, 'imputedData_run2_agg_country.rds') # pnlp
pnlpHZFile = paste0(pnlpDir, 'archive/imputedData_run2_agg_hz.rds')
snisBaseFile <- paste0(dhisDir, 'archive/base_services_drc_01_2017_09_2018_prepped.rds') # snis base services
snisSiglFile <- paste0(dhisDir, 'archive/sigl_drc_01_2015_07_2018_prepped.rds') # snis sigl (supply chain)

# outcomes/impact files
mapITNFiles = list.files(paste0(lbdDir, 'mapitncov/mean/1y/'), '*.tif', 
	full.names=TRUE)
mapITNFiles = mapITNFiles[!grepl('tif.',mapITNFiles)]
mapACTFiles = list.files(paste0(lbdDir, 'map_antimalarial/mean/1y/'), '*.tif', 
	full.names=TRUE)
mapACTFiles = mapACTFiles[!grepl('tif.',mapACTFiles)]
mapIncidenceFiles = list.files(paste0(lbdDir, 'map_pf_incidence/mean/1y/'), 
	'*.tif', full.names=TRUE)
mapIncidenceFiles = mapIncidenceFiles[!grepl('tif.',mapIncidenceFiles)]
mapPrevalenceFiles = list.files(paste0(lbdDir, 'map_pf_prevalence/mean/1y/'), 
	'*.tif', full.names=TRUE)
mapPrevalenceFiles = mapPrevalenceFiles[!grepl('tif.',mapPrevalenceFiles)]
mapMortalityFiles = list.files(paste0(lbdDir, '../18_Malaria_GBD/raw/'), 
	'*.tif', full.names=TRUE)
mapMortalityFiles = mapMortalityFiles[!grepl('tif.',mapMortalityFiles)]
popFiles = list.files(paste0(lbdDir, 'worldpop_raked/total/1y/'), '*.tif', 
	full.names=TRUE)

# shapefiles
admin2ShapeFile = paste0(dir, '/mapping/cod/health_zones_who/health2.shp')
# ---------------------------------------------------------------------------------


# ---------------------------------------------------------------------------------
# Intermediate file locations
username = Sys.info()[['user']]
clustertmpDir1 = paste0('/ihme/scratch/users/', username, '/impact_evaluation/combined_files/')
clustertmpDir2 = paste0('/ihme/scratch/users/', username, '/impact_evaluation/parallel_files/')
if (file.exists(clustertmpDir1)!=TRUE) dir.create(clustertmpDir1) 
if (file.exists(clustertmpDir2)!=TRUE) dir.create(clustertmpDir2) 
# ---------------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# Output Files

# output file from 2a_prep_resource_tracking.r
outputFile2a = paste0(ieDir, 'prepped_resource_tracking.RDS')

# output file from 2b_prep_activities_outputs.R
outputFile2b = paste0(ieDir, 'outputs_activites_for_pilot.RDS')
outputFile2b_wide = paste0(ieDir, 'outputs_activities_for_pilot_wide.RDS')

# output file from 2c_prep_outcomes_impact.r
outputFile2c_estimates = paste0(ieDir, 'aggregated_rasters.rds')
outputFile2c = paste0(ieDir, 'outcomes_impact.rds')

# output file from 3_merge_data.R
outputFile3 = paste0(ieDir, 'pilot_data.RDS')

# output file from 4_explore_data.r (graphs)
outputFile4a = paste0(ieDir, '../visualizations/pilot_data_exploratory_graphs.pdf')
outputFile4b = paste0(ieDir, '../visualizations/second_half_exploratory_graphs.pdf')

# output file from 5a_set_up_for_analysis.r
outputFile5a = paste0(ieDir, 'pilot_data_pre_model.rdata')

# output file from 5b_run_analysis.R
outputFile5b = paste0(ieDir, 'pilot_model_results.rdata')

# output file from 5c_set_up_for_second_half_analysis.r
outputFile5c = paste0(ieDir, 'second_half_data_pre_model.rdata')
outputFile5c_scratch = paste0(clustertmpDir1, 'second_half_data_pre_model.rdata')

# output file from 5d_run_second_half_analysis.r
outputFile5d = paste0(ieDir, 'second_half_model_results.rdata')

# output file from 6_display_results.r
outputFile6 = paste0(ieDir, '../visualizations/pilot_model_results.pdf')
# -----------------------------------------------------------------------------
