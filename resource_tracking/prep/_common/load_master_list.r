#-----------------------------------------------
# AUTHOR: Emily Linebarger 
# PURPOSE: Load and validate Master GF File List 
# DATE: August 2019 
# ----------------------------------------------

#---------------------------------------
# TO-DO: Add a check to make sure primary and secondary recipients are standardized across grants. 


load_master_list = function(purpose=NULL) {
  require(data.table)
  require(readxl) 
  
  if (is.null(purpose)) stop("Please specify the 'purpose' option. Options are 'financial' or 'performance indicators'")
  stopifnot(purpose%in%c('financial', 'performance indicators'))
  
  if (Sys.info()[1]=='Windows'){
    dir = paste0(box) #Change to the root of your repository
    j_dir = "\\\\ihme.washington.edu/ihme/snfs/Project/Evaluation/GF/resource_tracking/_gf_files_gos/" #On windows, you'll want to pull the file list off of Box. 
  } else {
    dir = "/home/j/Project/Evaluation/GF/resource_tracking/_gf_files_gos/"
    j_dir = copy(dir) #On the cluster, these will be the same 
  }
  
  #Read in data.
  dt = data.table(read_excel(paste0(dir, "master_file_list.xlsx")))
  #*** Note that NA's entered by hand in the excel will be imported as strings! ("NA")
  
  #------------------------------------------------
  #Run some validation checks before you start. 
  #------------------------------------------------
  #Certain columns should never have missing values. 
  core_cols = c('loc_name', 'grant_period', 'grant_status', 'file_name', 'disease', 'data_source', 'primary_recipient', 
                'file_currency', 'file_iteration', 'grant') #Note that secondary_recipient and geography_detail aren't included in this list at the moment, 
                                                  # because they aren't really used in the prep pipeline at the moment. EL 9.9.2019
                                                  # I added 'grant' back into core_cols because it is necessary later in the prep code
  
  for (col in core_cols[1:9]) { # don't want to check for grant currently because we know some will be missing
    if ('verbose'%in%ls() & verbose){
      print(paste0('Checking for NAs in ', col))
    } 
    stopifnot(nrow(dt[is.na(get(col))])==0)
  } 
  
  stopifnot(nrow(dt[is.na(grant) & data_source != 'funding_request',])==0)
  
  #Certain columns should only have specific values. 
  #First, check data source and function columns so they can be used to filter rows. 
  stopifnot(unique(dt$data_source)%in%c('budget', 'pudr', 'document', 'performance_framework', 'funding_request_narrative',
                                        'funding_request', 'funding_landscape', 'paar', 'programmatic_gap_table'))
  stopifnot(unique(dt$function_financial)%in%c('detailed', 'detailed_other', 'module', 'old_detailed', 'pudr', 'summary', 'unknown', 'NA'))
  stopifnot(unique(dt$function_programmatic)%in%c('master', 'unknown', 'NA'))
  
  #Then, drop out data types that aren't being processed. 
  if (purpose=="financial") dt = dt[data_source%in%c('budget', 'pudr', 'funding_request') & !function_financial%in%c('NA', 'unknown')]
  if (purpose=="performance indicators") dt = dt[data_source%in%c('pudr', 'performance_framework') & !function_programmatic%in%c('NA', 'unknown')]
  #*** Note that 'unknown' typed into a column means data is there, but there's not a function that can process it yet. 
  # 'NA' typed into a column means that extraction type doesn't apply here. 
  
  #Check remaining columns - you should have no NA values for these now. 
  stopifnot(unique(dt$loc_name)%in%c('cod', 'uga', 'gtm', 'sen'))
  stopifnot(unique(dt$grant_status)%in%c('active', 'not_active'))
  stopifnot(unique(dt$disease%in%c('hiv', 'tb', 'malaria', 'rssh', 'hiv/tb', 'tb/malaria')))
  stopifnot(unique(dt$file_currency)%in%c('USD', 'EUR', 'LOC'))
  stopifnot(unique(dt$geography_detail)%in%c('NATIONAL', 'SUBNATIONAL', 'NA'))
  stopifnot(unique(dt$file_iteration)%in%c("approved_gm", 'initial', 'revision', 'unclear'))
  stopifnot(unique(dt$lfa_verified)%in%c('NA', 'TRUE', 'FALSE', 'UNKNOWN'))
  
  #Correct date formats
  dt[, start_date_financial:=as.Date(as.numeric(start_date_financial), origin="1899-12-30")] #NA's introduced here are ok because some of the documents don't have a start date finacial
  dt[, start_date_programmatic:=as.Date(as.numeric(start_date_programmatic), origin="1899-12-30")]
  dt[, end_date_programmatic:=as.Date(as.numeric(end_date_programmatic), origin="1899-12-30")]
  dt[, cumul_exp_start_date:=as.Date(as.numeric(cumul_exp_start_date), origin="1899-12-30")]
  dt[, cumul_exp_end_date:=as.Date(as.numeric(cumul_exp_end_date), origin="1899-12-30")]
  dt[, version_date:=as.Date(version_date)]
  
  #Check for duplicate sheet names in files. 
  if (purpose=="financial"){
    sheet_check = unique(dt[, .(file_name, sheet_financial)])
    names(sheet_check) = c('file_name', 'sheet')
  } else {
    sheet_check = unique(dt[, .(file_name, sheet_impact_outcome_1a)])
    names(sheet_check) = c('file_name', 'sheet')
  }
  sheet_check = sheet_check[, .N, by=c('file_name', 'sheet')]
  stopifnot(nrow(sheet_check[N>1])==0)
  #Validate columns based on the type of extraction you're doing. 
  #-------------------------------
  # Financial 
  #-------------------------------
  if (purpose=="financial") {
    keep_cols = c('budget_version', 'revision_type', 'gf_revision_type', 'version_date', 'function_financial', 'sheet_financial', 'start_date_financial', 'period_financial', 'qtr_number_financial', 'language_financial', 
                  'pudr_semester_financial', 'update_date', 'mod_framework_format', 'cumul_exp_start_date', 'cumul_exp_end_date', 'lfa_verified')
    keep_cols = c(core_cols, keep_cols)
    dt = dt[, c(keep_cols), with=F]
    
    for (col in names(dt)[!names(dt)%in%c('budget_version', 'revision_type', 'gf_revision_type', 'version_date', 'start_date_financial', 'update_date', 'pudr_semester_financial', 
                                          'cumul_exp_start_date', 'cumul_exp_end_date', 'lfa_verified', 'grant', 'primary_recipient')]){ #Check all applicable string columns. PUDR semester is OK to be NA if the line-item is a budget.  
      if ('verbose'%in%ls() & verbose){
        print(paste0("Checking for NA values in ", col))
      }
      stopifnot(nrow(dt[get(col)=="NA" | is.na(get(col))])==0)
    }
    
    #Check date variables, and special string variables. 
    stopifnot(nrow(dt[is.na(start_date_financial)])==0)
    stopifnot(nrow(dt[is.na(version_date) & is.na(update_date) & file_iteration=="revision"])==0)
    stopifnot(nrow(dt[data_source=="pudr" & (pudr_semester_financial=="NA" | is.na(pudr_semester_financial))])==0) #Check PUDR semester. 
  }
  
  
  #-------------------------------
  # Performance indicators 
  #-------------------------------
  
  if (purpose=="performance indicators") {
    keep_cols = c('function_programmatic', 'sheet_impact_outcome_1a', 'sheet_impact_outcome_1a_disagg', 'sheet_coverage_1b', 'sheet_coverage_1b_disagg', 
                  'start_date_programmatic', 'end_date_programmatic', 'language_1a', 'language_1a_disagg', 'language_1b', 'language_1b_disagg', 'pudr_semester_programmatic', 'lfa_verified')
    keep_cols = c(core_cols, keep_cols)
    dt = dt[, c(keep_cols), with=F]
    
    for (col in names(dt)[!names(dt)%in%c('start_date_programmatic', 'end_date_programmatic', 'sheet_impact_outcome_1a_disagg', 
                                          'sheet_coverage_1b_disagg', 'lfa_verified')]){ #Check all applicable string columns. PUDR semester is OK to be NA if the line-item is a budget.  
      if ('verbose'%in%ls() & verbose){
        print(paste0("Checking for NA values in ", col))
      }
      stopifnot(nrow(dt[get(col)=="NA" | is.na(get(col))])==0)
    }
    
    #Check that no disaggregated sheet names are NA - "NA" as a string is fine; that was entered intentionally. 
    stopifnot(nrow(dt[is.na(sheet_impact_outcome_1a_disagg)])==0)
    stopifnot(nrow(dt[is.na(sheet_coverage_1b_disagg)])==0)
    
    #Check date variables, and special string variables. 
    stopifnot(nrow(dt[is.na(start_date_programmatic)])==0)
    stopifnot(nrow(dt[is.na(end_date_programmatic)])==0)
    
  }
  
  
  #--------------------------------------------------------
  # Make sure that hand-entered information matches with GF metadata. 
  #--------------------------------------------------------
  metadata = fread(paste0(j_dir, "metadata/grant_agreement_implementation_periods_dataset_201963.csv"))
  correct_periods = metadata[GeographicAreaCode_ISO3%in%c('COD', 'GTM', 'SEN', 'UGA'), .(GrantAgreementNumber, ImplementationPeriodStartDate, ImplementationPeriodEndDate)]
  names(correct_periods) = c('grant', 'grant_period_start', 'grant_period_end')
  
  #Format dates correctly 
  correct_periods[, grant_period_start:=tstrsplit(grant_period_start, " ", keep=1)][, grant_period_start:=as.Date(grant_period_start, format="%m/%d/%Y")]
  correct_periods[, grant_period_end:=tstrsplit(grant_period_end, " ", keep=1)][, grant_period_end:=as.Date(grant_period_end, format="%m/%d/%Y")]
  
  #Extract grant period 
  correct_periods[, grant_period:=paste0(year(grant_period_start), "-", year(grant_period_end))]
  correct_periods[, correct_grant_period:=grant_period]

  #Merge data together
  if (purpose=="financial"){
    our_periods = unique(dt[data_source%in%c('fpm', 'pudr', 'performance_framework'), .(grant, grant_period, start_date_financial)])
  } else {
    our_periods = unique(dt[data_source%in%c('fpm', 'pudr', 'performance_framework'), .(grant, grant_period, start_date_programmatic)])
  }
  names(our_periods) = c('grant', 'grant_period', 'ihme_start_date')
  
  #EMILY WE SHOULD FLAG WHEN GRANT PERIODS ARE NA!! 
  our_periods = our_periods[!is.na(grant_period)]
  check = merge(our_periods, correct_periods, by=c('grant', 'grant_period'), all.x=T)
  if (nrow(check[is.na(correct_grant_period)]) != 0){
    print(check[is.na(correct_grant_period), .(grant, grant_period)])
    warning("These grant periods are incorrectly tagged. Match grant periods in Global Fund metadata. (correct_periods)")
  }
  
  incorrect_grants = unique(our_periods$grant[!our_periods$grant%in%correct_periods$grant])
  if (length(incorrect_grants)>0) { 
    print(incorrect_grants) 
    stop("There are grant names that don't match with GF metadata.")
  }
  
  #------------------------------------------------------------
  # Make sure that you've entered PUDR semester correctly. 
  correct_periods[, ip_start_month:=month(grant_period_start)]
  correct_periods[, ip_end_month:=month(grant_period_end)]
  correct_periods[, ip_start_year:=year(grant_period_start)]
  correct_periods[, ip_end_year:=year(grant_period_end)]
  
  #Merge files together and compare
  dt1 = merge(dt, correct_periods, all.x=T, by=c('grant', 'grant_period'))
  
  #Using these new correct months, figure out what the correct PUDR semesters are. 
  pudr_semesters = correct_periods[, .(grant, grant_period, grant_period_start, grant_period_end)] #Only will care about the PUDRs from 2015 on. 
  melt = melt(pudr_semesters, id.vars=c('grant', 'grant_period'), value.var='date')
  melt = melt[order(grant, grant_period, variable)]
  melt[, concat:=paste0(grant, grant_period)]
  
  pudr_sequence = c('1-A', '1-B', '2-A', '2-B', '3-A', '3-B', '4-A', '4-B', '5-A', '5-B', '6-A', '6-B', '7-A', '7-B', '8-A', '8-B', '9-A', '9-B', '10-A', '10-B')
  
  correct_pudr_sem = data.table()
  for (g in unique(melt$concat)){
    subset = melt[concat==g]
    stopifnot(nrow(subset)==2)
    start = as.Date(subset[variable=="grant_period_start", value])
    end = as.Date(subset[variable=="grant_period_end", value])
    frame = data.table(grant=subset$grant, grant_period=subset$grant_period, 
                       value=seq(start, end, by='6 months'))
    frame[, pudr_semester:=pudr_sequence[1:nrow(frame)]]
    correct_pudr_sem = rbind(correct_pudr_sem, frame)
  }
  if ('10-B'%in%unique(correct_pudr_sem$pudr_semester)) stop("Expand PUDR sequence within load_master_list() function! Max has been reached.")
  
  #Check that you've entered the correct PUDR semesters by hand! 
  if (purpose=="financial") { 
    pudrs = dt1[data_source%in%c('pudr') & !is.na(start_date_financial), .(grant, grant_period, start_date_financial, period_financial, pudr_semester_financial)]
    setnames(pudrs, 'pudr_semester_financial', 'hand_coded_semester')
    setnames(correct_pudr_sem, 'value', 'start_date_financial')
    
    pudrs = merge(pudrs, correct_pudr_sem, by=c('grant', 'grant_period', 'start_date_financial'), all.x=T)
    
    #Check. 
    pudrs[, hand_code_start:=substr(hand_coded_semester, 1, 3)] # If you have a semester like "1-AB", that's ok, just check that it matches 1-A. AKA the start dates are correct. 
    error = pudrs[hand_code_start!=pudr_semester| is.na(hand_code_start) | hand_code_start=="NA"]
    
    #Hand-code any unique cases - initial and date. 
    error = error[!(grant=="GTM-M-MSPAS" & grant_period=="2018-2018" & start_date_financial=="2018-07-01")] #EL 9/12/2019

    #Print a stop message if errors remain. 
    if (nrow(error)!=0){
      print(error) 
      stop("Some PUDR semesters were entered incorrectly. Review variable 'pudr_semester_financial'.")
    }
    
  } else if (purpose=="performance indicators"){
    pudrs = dt1[data_source%in%c('pudr') & !is.na(start_date_programmatic), .(grant, grant_period, start_date_programmatic, end_date_programmatic, pudr_semester_programmatic)]
    setnames(pudrs, 'pudr_semester_programmatic', 'hand_coded_semester')
    setnames(correct_pudr_sem, 'value', 'start_date_programmatic')
    
    pudrs = merge(pudrs, correct_pudr_sem, by=c('grant', 'grant_period', 'start_date_programmatic'), all.x=T)
    
    #Check. 
    pudrs[, hand_code_start:=substr(hand_coded_semester, 1, 3)] # If you have a semester like "1-AB", that's ok, just check that it matches 1-A. AKA the start dates are correct. 
    error = pudrs[hand_code_start!=pudr_semester | is.na(hand_code_start) | hand_code_start=="NA"]
    
    #Hand-code any unique cases - initial and date. 
    error = error[!(grant=="GTM-M-MSPAS" & grant_period=="2018-2018" & start_date_programmatic=="2018-07-01")] #EL 9/12/2019
    error = error[!(grant=="GTM-H-HIVOS" & grant_period=="2018-2018" & start_date_programmatic=="2018-07-01")] #EL 9/12/2019

    #Print a stop message if errors still remain. 
    if (nrow(error)!=0){
      print(error) 
      stop("Some PUDR semesters were entered incorrectly. Review variable 'pudr_semester_programmatic'.")
    }
  }
  
  
  
  #----------------------------------------------------------------------------------
  #So that you always get consistent ordering, even if the excel beneath is filtered. 
  #----------------------------------------------------------------------------------
  dt = dt[order(loc_name, grant_period, grant_period, data_source, file_name)] 
  
  return(dt) 
}