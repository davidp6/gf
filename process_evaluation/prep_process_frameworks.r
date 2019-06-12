# ----------------------------------------------
# AUTHOR: Emily Linebarger, based on code written by Irena Chen
# PURPOSE: Prep commonly-formatted coverage indicator sheetf from 
#   PU/DRs across countries. 
# DATE: Last updated June 2019. 
# ----------------------------------------------

prep_coverage_1B =  function(dir, inFile, sheet_name, language) {
  
  #TROUBLESHOOTING HELP
  #Uncomment variables below and run line-by-line. 
  # dir = "J:/Project/Evaluation/GF/resource_tracking/_gf_files_gos/sen/raw_data/active/SEN-H-ANCS/pudrs/"
  # inFile = "SEN-H-ANCS_PUDR (Juil-Dec18) LFA, 15Mar18.xlsx"
  # sheet_name = "Coverage Indicators_1B"
  # language = "fr" 
  # 
  STOP_COL = 6 #What column starts to have sub-names? (After you've dropped out first 2 columns)
  
  # Sanity check: Is this sheet name one you've checked before? 
  verified_sheet_names <- c('Coverage Indicators_1B')
  if (!sheet_name%in%verified_sheet_names){
    print(sheet_name)
    stop("This sheet name has not been run with this function before - Are you sure you want this function? Add sheet name to verified list within function to proceed.")
  }
  
  # Load/prep data
  gf_data <-data.table(read.xlsx(paste0(dir,inFile), sheet=sheet_name, detectDates=TRUE))

  
  #------------------------------------------------------
  # 1. Select columns, and fix names 
  #------------------------------------------------------
  module_col = grep("Module", gf_data)
  stopifnot(length(module_col)==1)
  name_row = grep("Module", gf_data[[module_col]])
  stopifnot(length(name_row)==1)
  
  names = gf_data[name_row, ]
  names = tolower(names)
  names = gsub("\\.", "_", names)
  
  comment_col = grep("comment", names) 
  
  #Drop out first 2 columns, and comments column. 
  gf_data = gf_data[, !comment_col, with=FALSE] 
  gf_data = gf_data[, 3:ncol(gf_data)]
  
  #------------------------------------------------------
  # 2. Reset names after subset above. 
  #------------------------------------------------------
  
  module_col = grep("Module", gf_data)
  stopifnot(length(module_col)==1)
  name_row = grep("Module", gf_data[[module_col]])
  stopifnot(length(name_row)==1)
  
  names = gf_data[name_row, ]
  names = tolower(names)
  names = gsub("\\.", "_", names)
  
  names(gf_data) = names
  #Drop everything before the name row, because it isn't needed 
  gf_data = gf_data[(name_row+1):nrow(gf_data)] #Go ahead and drop out the name row here too because you've already captured it
  sub_names = gf_data[1, ]
  
  #------------------------------------------------------
  # 3. Rename columns 
  #------------------------------------------------------
  
  if (language == "fr"){
    reference_col = grep("référence", names)
    target_col = grep("cible", names)
    result_col = grep("résultats", names)
    lfa_result_col = grep("verified result", names)
    gf_result_col = grep("global fund validated result", names) 
  } 
  reference_col = reference_col[reference_col>STOP_COL]
  target_col = target_col[target_col>STOP_COL]
  result_col = result_col[result_col>STOP_COL]
  lfa_result_col = lfa_result_col[lfa_result_col>STOP_COL]
  gf_result_col = gf_result_col[gf_result_col>STOP_COL]
  
  #Are you only pulling one observation, and do these match the format of files you've seen before? 
  stopifnot(length(reference_col)==1 & reference_col == 7) 
  stopifnot(length(target_col)==1 & target_col==12)
  stopifnot(length(result_col)==1 & result_col==15)
  stopifnot(length(lfa_result_col)==1 & lfa_result_col==21)
  stopifnot(length(gf_result_col)==1 & gf_result_col==28)
  
  #If so, go ahead and reset names. 
  new_names = c("Module", "Indicator", "Geography", "Cumulative Target?", "Reverse Indicator?", "Country", "Baseline: N", "Baseline: D", "Baseline: %", 
            "Baseline: Year", "Baseline: Source", "Target: N", "Target: D", "Target: %", "Result: N", "Result: D", "Result: %", "Result: Source", "Result: Achievement Ratio", 
            "Result: Data validation", "LFA Verified Result: N", "LFA Verified Result: D", "LFA Verified Result: %", "LFA Verified Result: Source", 
            "LFA Verified Result: Achievement Ratio", "LFA verification method", "LFA Verified Result: Data validation", "GF Verified Result: N", 
            "GF Verified Result: D", "GF Verified Result: %", "GF Verified Result: Source", "GF Verified Result: Data Validation")
  stopifnot(length(new_names) == ncol(gf_data))
  names(gf_data) <- new_names
  #------------------------------------------------------
  # 2. Drop out empty rows 
  #------------------------------------------------------
  
  #Drop out rows that have NAs 
  gf_data = gf_data[!(is.na(Module) & is.na(Indicator)), ] 
  
  return(gf_data)
}

