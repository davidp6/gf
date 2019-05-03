# Prep & remove outliers from the COD DHIS2 PNLS Viral Load data 
# Impute missing data in DHIS2 SIGL data
# ----------------------------------------------
# Caitlin O'Brien-Carelli / Audrey Batzel (3-7-19)
#
# 4/1/2019
# The current working directory should be the root of this repository
# This code must be run on the cluster

# ----------------------------------------------

# --------------------
# Manual set up on the cluster
#---------------------

# --------------------
# make sure qr_results exists
# cd /ihme/scratch/users/ccarelli/

# set the working directory in the qlogin by navigating to it
# cd /ihme/code/ccarelli/gf/
# cd /ihme/code/abatzel/gf/

# print the contents
# ls

# once you navigate to the directory, git pull R
# make sure you have pushed from github desktop

# then call R

#------------------------------------

# --------------------
# Set up R
# --------------------
rm(list=ls())
library(data.table)
library(quantreg)
library(fst) # to save data tables as .fst for faster read/write and full random access

# detect the user operating on the cluster
user = Sys.info()[['user']]

# choose the data set you want to load
set = 'base'

# ------------------------------------------------
# before starting the process, delete the existing files on the cluster
# this allows us to avoid duplication or aggregating old files 

system(paste0('rm /ihme/scratch/users/', user, '/qr_results/*'))
system(paste0('rm /ihme/scratch/users/', user, '/quantreg_output/*'))
system(paste0('rm /ihme/scratch/users/', user, '/array_table_for_qr.csv'))
system(paste0('rm /ihme/scratch/users/', user, '/data_for_qr.fst'))
# ------------------------------------------------

#------------------------------------
# set directories, switchs, arguments  
#------------------------------------
# detect if operating on windows or on the cluster 
j = ifelse(Sys.info()[1]=='Windows', 'J:', '/home/j')

# set the directory for input and output
dir = paste0(j, '/Project/Evaluation/GF/outcome_measurement/cod/dhis_data/')
PATH = paste0('/ihme/scratch/users/', user, '/quantreg_output')
scratchDir = paste0('/ihme/scratch/users/', user, '/quantreg/')
parallelDir = paste0(scratchDir, 'parallel_files/')
if (!file.exists(scratchDir)) dir.create(scratchDir)
if (!file.exists(parallelDir)) dir.create(parallelDir)

# place for cluster output/error files
oeDir = paste0(scratchDir, 'errors_output/')
if (!file.exists(oeDir)) dir.create(oeDir)

#------------------------------------
# input file and location to copy it to
# initial file is read off of j 
# output file is the aggregate of the files from /ihme/scratch

if (set=='sigl') {inFile = paste0(dir, 'sigl_for_qr.rds') 
outFile = paste0(dir, 'sigl_quantreg_imputation_results.rds') }

if (set=='base') {inFile = paste0(dir, 'outliers/base_to_screen.rds')
scratchInFile = paste0(scratchDir, 'data_for_qr.fst')}

#------------------------------------
# interim files
arrayFile = paste0(scratchDir, 'array_table_for_qr.csv')

# output file
outFile = paste0(dir, 'outliers/base_quantreg_results.rds')

# whether or not to resubmit jobs that have completed already
resubmitAll = TRUE

# whether or not to delete all files from parallel runs at the end
cleanup = TRUE

# whether or not to impute missing data as part of the qr 
# (set as a character TRUE/FALSE so it can be read as a command arg)
impute = TRUE

#------------------------------------
# read in the data and create the array table

dt = readRDS(inFile)

# sort the data table so the indexing works correctly when retrieving data using fst
dt = setorder(dt, org_unit_id)

# make array table to set up for submitting an array job
array_table = data.table(expand.grid(unique(dt$org_unit_id)))
setnames(array_table, "Var1", "org_unit_id")
array_table[ ,org_unit_id:=as.character(org_unit_id)]

# save the array table and the data with IDs to /ihme/scratch/
write.csv(array_table, arrayFile)
write.fst(dt, scratchInFile)

#--------------------------------------------------------------------------------

#----------------------------------------
# run quantregScript.r as separate qsubs
#-----------------------------------------
# file pathways are now relative to the root of the repository

# determine the number of rows in the array job
N = nrow(array_table)

# base data set: run value~date on each org_unit and element
if (set=='base') system(paste0('qsub -e ', oeDir, ' -o ', oeDir,' -N base_jobs -cwd -t 1:', N, ' ./core/r_shell.sh ./outcome_measurement/all/cod/dhis/outlier_removal/quantregScript_base.R'))

# sigl data set: run value~date on each org_unit, element, and variable
if (set=='sigl') system(paste0('qsub -e ', PATH, ' -o ', PATH,' -N all_quantreg_jobs -cwd -t 1:', N, ' ./core/r_shell.sh ./outcome_measurement/all/cod/dhis/outlier_removal/quantregScript_sigl.r'))

#----------------------------------------------------------
#------------------------------------
# wait for files to be done
#------------------------------------

i = N-1
numFiles = length(list.files(parallelDir))
while(numFiles<i) { 
  print(paste0(numFiles, ' of ', i, ' jobs complete, waiting 5 seconds...'))
  numFiles = length(list.files(parallelDir))
  Sys.sleep(5)
}
#------------------------------------

#------------------------------------
# once all files are done, collect all output into one data table
#------------------------------------
fullData = data.table()

for (j in seq(N)) {
  tmp = read.fst(paste0(parallelDir, 'quantreg_output', j, '.fst'), as.data.table=TRUE)
  if(j==1) fullData = tmp
  if(j>1) fullData = rbind(fullData, tmp)
  cat(paste0('\r', j))
  flush.console() 
}

# save full data
saveRDS(fullData, outFile)
#------------------------------------

#------------------------------------
# clean up parallel files
#------------------------------------
if (cleanup==TRUE) { 
  system(paste0('rm /ihme/scratch/users/', user_name, '/qr_results/*'))
  system(paste0('rm /ihme/scratch/users/', user_name, '/quantreg_output/*'))
  system(paste0('rm /ihme/scratch/users/', user_name, '/array_table_for_qr.csv'))
  system(paste0('rm /ihme/scratch/users/', user_name, '/data_for_qr.fst'))
}
#------------------------------------