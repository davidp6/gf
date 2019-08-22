# ----------------------------------------------
# AUTHOR: Emily Linebarger 
# PURPOSE: Prep country-level budgets and PUDRs
# DATE: Last updated March 2019 
# ----------------------------------------------

#-------------------------
#To do: 
# Make sure that final files in file list don't have overlapping quarters, NOT just duplicate start dates. 
#--------------------------

#----------------------------------------------------
# Read in file list 
#----------------------------------------------------
if (prep_files == TRUE){
  file_list = read_excel(paste0(dir, "_gf_files_gos/master_file_list.xlsx"))
  setDT(file_list)
  file_list = file_list[order(loc_name, grant_period, grant_period, data_source, file_name)] #So that you always get consistent ordering, even if the excel beneath is filtered. 
  file_list = file_list[loc_name==country]
  file_list = file_list[!is.na(start_date_financial)]
  file_list[, start_date_financial:=excel_numeric_to_date(as.numeric(as.character(start_date_financial)), date_system="modern")] #This is ugly, but I can't find a fix within the readxl package. EL 8/9/2019
  file_list = file_list[, -c('notes')]
  
  #Validate file list 
  desired_cols <- c("file_name", "function_financial", "sheet_financial", "disease", "loc_name", "data_source", "period_financial", "qtr_number_financial", "grant", "primary_recipient", 
                    "secondary_recipient", "language_financial", "grant_period", "grant_status", "start_date_financial", "file_iteration", "geography_detail", 
                    "loc_name", "mod_framework_format", "file_currency", "pudr_semester")
  stopifnot(desired_cols%in%names(file_list))
  stopifnot((unique(file_list$data_source))%in%c("fpm", "pudr", "performance_framework", "document"))
  stopifnot(unique(file_list$file_iteration)%in%c('final', 'initial', 'revision', NA, "NA"))
  
  #Only keep inputs with financial information, and make sure you've kept date column before prioritizing GOS. 
  file_list = file_list[data_source%in%c('fpm', 'pudr') & !is.na(sheet_financial) & function_financial!='unknown'] #Will only keep files where financial sheet, function, and start date (from above) are available. 

  #Prioritize GOS data where we have it
  file_list = prioritize_gos(file_list)

  #Make sure you don't have the same tart date for the same grant (quick check; it would be better )
  file_list[file_iteration=='final', date_dup:=sequence(.N), by=c('grant', 'start_date_financial', 'data_source', 'pudr_semester')] #EMILY NEED TO RETHINK THIS. 
  file_list[, date_dup:=date_dup-1]#This indexes at one, so you need to decrement it

  if ( nrow(file_list[date_dup>0])!=0){
    print(file_list[date_dup > 0, .(file_name, file_iteration, grant, grant_period, start_date_financial)][order(grant, grant_period, start_date_financial)])
    print("There are duplicates in final files - review file list.")
  }
  
  file_list[data_source=="pudr" & file_iteration=="final", pudr_dup:=sequence(.N), by=c('grant', 'grant_period', 'pudr_semester')]
  file_list[, pudr_dup:=pudr_dup-1] #This variable indexes at 1.
  if (nrow(file_list[pudr_dup>0 & !is.na(pudr_dup)])>0){
    print(file_list[pudr_dup>0 & !is.na(pudr_dup)])
    stop("There are duplicates in PUDRs between semesters - review file list.")
  }
  
  #At this moment in time, don't process initial versions of files. EL 8/9/2019 
  file_list = file_list[file_iteration%in%c('final', 'revision')]
  
}

#----------------------------------------------------
# 1. Rerun prep functions, or read in prepped files
#----------------------------------------------------
if (rerun_filelist == TRUE){ #Save the prepped files, but only if all are run
  
  pudr_mod_approach_sheet_financials <- c('LFA Expenditure_7B', 'LFA AFR_7B', 'PR Expenditure_7A', 'RFA ALF_7B', 'ALF RFR_7')
  general_detailed_budget_sheet_financials <- c('Detailed Budget', 'Detailed budget', 'DetailedBudget', 'Recomm_Detailed Budget', '1.Detailed Budget', "Detailed Budget Revise",
                                      'DETAIL', 'Detailed _ budget AGYW', 'Detailed Budget _ Human rights')
  
  budget_cols = c("activity_description", "budget", "cost_category", "implementer", "intervention", "module", "quarter", "start_date", "year") #These are the only columns that should be returned from a budget function. 
  pudr_cols = c("budget", "expenditure", "intervention", "module", "quarter", "start_date", "year") #These are the only columns that should be returned from a pudr function. 
  
  for(i in 1:nrow(file_list)){
    # Set up file path 
    folder = "budgets"
    folder = ifelse (file_list$data_source[i] == "pudr", "pudrs", folder)
    if (file_list$file_iteration[i]=="initial"){
      version = "iterations"
    } else if (file_list$file_iteration[i]=="revision"){
      version= "revisions"
    } else {
      version = ""
    }
    grant_period = file_list$grant_period[i]
    
    file_dir = paste0(master_file_dir, file_list$grant_status[i], "/", file_list$grant[i], "/", grant_period, "/", folder, "/")
    if (version != ""){
      file_dir = paste0(file_dir, version, "/")
    }
    
    args = list(file_dir, file_list$file_name[i], file_list$sheet_financial[i], file_list$start_date_financial[i], file_list$period_financial[i])
    
    if(file_list$function_financial[i] == 'detailed' & file_list$sheet_financial[i]%in%general_detailed_budget_sheet_financials){ #Prep standardized detailed budgets. 
      args[length(args)+1] = file_list$qtr_number_financial[i]
      args[length(args)+1] = file_list$language_financial[i]
      tmpData = do.call(prep_general_detailed_budget, args)
      
      stopifnot(sort(names(tmpData)) == budget_cols)
      
    } else if (file_list$function_financial[i] == 'pudr' & file_list$sheet_financial[i]%in%pudr_mod_approach_sheet_financials){ #Prep standardized 'modular approach' PUDRs. 
      args[length(args)+1] = file_list$qtr_number_financial[i]
      tmpData = do.call(prep_modular_approach_pudr, args)
      
      stopifnot(pudr_cols%in%names(tmpData))
      tmpData$currency = file_list[i]$currency # Want to add currency columnn from file list ONLY for PUDRs. For budgets, this is extracted from file. 
      
    } else if (file_list$function_financial[i]=='pudr' & file_list$loc_name=="gtm" & file_list$sheet_financial[i]%in%c('INTEGRACION', "LFA EFR_7")){ #Prep more general Guatemala PUDRs. 
      args = list(file_dir, file_list$file_name[i], file_list$sheet_financial[i], file_list$start_date_financial[i], file_list$qtr_number_financial[i], file_list$period_financial[i])
      tmpData = do.call(prep_pudr_gtm, args)
      
      stopifnot(sort(names(tmpData)) == pudr_cols)
      tmpData$currency = file_list[i]$currency # Want to add currency columnn from file list ONLY for PUDRs. For budgets, this is extracted from file. 
      
    } else if (file_list$function_financial[i]=='pudr' & file_list$loc_name=="gtm" & file_list$sheet_financial[i]%in%c('PR EFR_7A')){
      args[length(args)+1] = file_list$qtr_number_financial[i]
      tmpData = do.call(prep_gtm_pudr2, args)
      
      stopifnot(sort(names(tmpData)) == pudr_cols)
      tmpData$currency = file_list[i]$currency # Want to add currency columnn from file list ONLY for PUDRs. For budgets, this is extracted from file. 
    } else if (file_list$function_financial[i] == 'summary' & file_list$loc_name[i] == 'cod'){ #Prep summary budgets from DRC. 
      args[length(args)+1] = file_list$qtr_number_financial[i]
      tmpData = do.call(prep_summary_budget_cod, args)
      
      stopifnot(sort(names(tmpData)) == c('budget', 'intervention', 'module', 'quarter', 'start_date', 'year'))
      
    } else if (file_list$function_financial[i] == 'summary' & file_list$loc_name[i]=='gtm') {
      args = list(file_dir, file_list$file_name[i], file_list$sheet_financial[i], file_list$start_date_financial[i], file_list$qtr_number_financial[i])
      tmpData = do.call(prep_summary_budget_gtm, args)
      
      stopifnot(sort(names(tmpData)) == c('budget', 'intervention', 'module', 'quarter', 'start_date', 'year'))
    } else if (file_list$function_financial[i]=='old_detailed' & file_list$loc_name[i]=="gtm"){ 
      args = list(file_dir, file_list$file_name[i], file_list$sheet_financial[i], file_list$start_date_financial[i], file_list$qtr_number_financial[i])
      tmpData = do.call(prep_other_budget_gtm, args)
      
      stopifnot(sort(names(tmpData)) == c('activity_description', 'budget', "expenditure", 'module', 'quarter', 'start_date', 'year'))
    } else if (file_list$function_financial[i]=='summary' & file_list$loc_name[i]=='uga'){
      args[length(args)+1] = file_list$qtr_number_financial[i]
      args[length(args)+1] = file_list$grant[i]
      tmpData = do.call(prep_summary_uga_budget, args)
      
      stopifnot(sort(names(tmpData)) == budget_cols)
    } else {
      print(paste0("File not being processed: ", file_list$file_name[i]))
      print(paste0("Check logic conditions. This file has the function_financial: ", file_list$function_financial[i],
            " and the sheet_financial name: ", file_list$sheet_financial[i]))
    }
    
    #Add indexing data
    append_cols = file_list[i, .(data_source, grant_period, primary_recipient, secondary_recipient, file_name, grant_status, disease, grant, 
                                 mod_framework_format, file_iteration, language_financial, file_currency, pudr_semester, period_financial, update_date)]
    for (col in names(append_cols)){
      tmpData[, (col):=append_cols[, get(col)]]
    }  
    tmpData$year <- year(tmpData$start_date)
    tmpData[, file_start_date:=min(start_date), by='file_name']
    
    #Bind data together 
    if(i==1){
      resource_database = tmpData
    } else {
      resource_database = rbind(resource_database, tmpData, use.names=TRUE, fill = TRUE)
    }
    print(paste0(i, " ", file_list$data_source[i], " ", file_list$function_financial[i], " ", file_list$grant[i])) ## if the code breaks, you know which file it broke on
  }
  
  saveRDS(resource_database, paste0(export_dir, "raw_bound_gf_files.RDS"))
  
  #If you don't have lfa_exp_adjustment in any of the files for this country, add it as NA so checks later will work. 
  if (!'lfa_exp_adjustment'%in%names(resource_database)){
    resource_database[, lfa_exp_adjustment:=NA]
  }
  
} else {
  resource_database <- readRDS(paste0(dir, "_gf_files_gos/", country, "/prepped_data/raw_bound_gf_files.RDS"))
  resource_database = resource_database[file_name%in%file_list$file_name]
}

#------------------------------------------------------------------
# 2. Run some checks to make sure this data was prepped correctly. 
#-----------------------------------------------------------------
original_db <- copy(resource_database)
#Make sure all budget data pulled is actually numeric- this is an easy check to see if prep functions are working correctly. 
verify_numeric_budget = resource_database[, .(budget=gsub("[[:digit:]]", "", budget))]
verify_numeric_budget = verify_numeric_budget[, .(budget=gsub("[[:punct:]]", "", budget))]
verify_numeric_budget = verify_numeric_budget[!is.na(budget) & budget != ""]
stopifnot(nrow(verify_numeric_budget)==0)

# Make sure there are no overlapping quarters for the same grant (duplicate files. )
fpm_overlap <- duplicated(resource_database[data_source == "fpm" & file_iteration == "final", .(grant, start_date)])
pudr_overlap <- duplicated(resource_database[data_source == "pudr" & file_iteration == "final", .(grant, start_date)])
stopifnot(nrow(fpm_overlap)==0 & nrow(pudr_overlap)==0)

rm(fpm_overlap, pudr_overlap)

#Make sure all budget and expenditure variables are numeric. 
resource_database$budget <- as.numeric(resource_database$budget)
resource_database$expenditure <- as.numeric(resource_database$expenditure)
resource_database$disbursement <- as.numeric(resource_database$disbursement)

#Add files here that had a sum total for 0 in raw file. 
verified_0_budget <- c('UGD-708-G08-M_PUDR 30Nov2011.xls', 'UGD-708-G08-M_PUDR_30June2012.xls', "Core_SANRU_PU_P3141116.xlsm",
                       "PSI PU NFM S1 2016 09102016.xlsm", "Core_PUDR_P30_HivosGT_231116_ LFA Signed.xlsx", 
                       "Core_PUDR_MALARIA_P12_03-03-17_Revisado ALF.xlsx")
#Add PUDRs here that did not report any expenditure.
verified_0_expenditure <- c("UGA-C-TASO_PU_PEJune2017_LFA_30Nov17.xlsx", "UGA-M-TASO_PU_PEJune2017_LFA_30Nov17.xlsx", 
                            "UGA-S-TASO_PU_PEJune2017_LFA_30Nov17.xlsx", "GTM-T-MSPAS_Progress Report_31Dec2017 LFA REVIEW.xlsx", 
                            "GTM-T-MSPAS_Progress Report jul _31Dec2018_v2  rev LFA.xlsx", "GTM-H-HIVOS_Progress Report_31Dec2018_v1.xlsx", 
                            "GTM-T-MSPAS_Progress Report_LFA18Mar19.xlsx", "Core_SANRU_PU_P3141116.xlsm", "PSI PU NFM S1 2016 09102016.xlsm", 
                            "Core_PUDR_P30_HivosGT_231116_ LFA Signed.xlsx", "Core_PUDR_MALARIA_P12_03-03-17_Revisado ALF.xlsx",  
                            "GTM-T-MSPAS_Progress Report_31Dec2017 LFA REVIEW.XLSX") #These files have 0 for all expenditure.

#Make sure that no files have a total sum of 0; this would indicate an error in the prep code. 
check_0_budgets <- resource_database[, .(budget = sum(budget, na.rm = TRUE)), by=.(file_name)]
check_0_budgets = check_0_budgets[budget == 0 & !file_name%in%verified_0_budget]
check_0_expenditure <- resource_database[data_source == 'pudr', .(expenditure = sum(expenditure, na.rm = TRUE)), by=.(file_name)]
check_0_expenditure <- check_0_expenditure[expenditure == 0 & !file_name%in%verified_0_expenditure]
stopifnot(nrow(check_0_budgets)==0 & nrow(check_0_expenditure)==0)

#Hacky fix - this should be fixed earlier in the prep functions, but remove anything at this point that has NAs for module, intervention, and budget OR expenditure. 
resource_database[module=='all', module:='unspecified']
resource_database[tolower(intervention)=='all', intervention:='unspecified']
resource_database[is.na(module), module:='unspecified'] 
resource_database[is.na(intervention), intervention:='unspecified']
resource_database = resource_database[!(module=='unspecified' & intervention=='unspecified' & budget == 0 & expenditure == 0)]

#check for duplicates, and sum their values if they exist:
dups<-resource_database[duplicated(resource_database) | duplicated(resource_database, fromLast=TRUE)]
print(paste0(nrow(dups), " duplicates found in database; values will be summed"))
byVars = names(resource_database)[!names(resource_database)%in%c('budget', 'expenditure', 'disbursement')]
resource_database= resource_database[, list(budget=sum(na.omit(budget)) ,expenditure=sum(na.omit(expenditure)), disbursement=sum(na.omit(disbursement))), by=byVars]

#Make sure you have all the files here that you started with in your filelist. 
rt_files <- unique(resource_database$file_name)
warning1 = (length(unique(file_list$file_name)) == length(rt_files))
if (!warning1){
  warning("The length of the original file list is not the same as the number of processed files.")
}
warning2 = sort(rt_files) == sort(unique(file_list$file_name))
if (!warning2){
  warning("The files in the processed data are not the same as the files in the file list.")
}

print("Step B: Prep GF files completed.")