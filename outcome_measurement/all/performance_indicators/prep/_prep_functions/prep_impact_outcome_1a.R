# ----------------------------------------------
# AUTHOR: Emily Linebarger, based on code written by Irena Chen
# PURPOSE: Prep commonly-formatted coverage indicator sheet from 
#   PU/DRs across countries. 
# DATE: Last updated June 2019. 
# ----------------------------------------------

prep_impact_outcome_1A =  function(dir, inFile, sheet_name, language) {
  
  #TROUBLESHOOTING HELP
  # #Uncomment variables below and run line-by-line.
  # folder = "budgets"
  # folder = ifelse (file_list$data_source[i] == "pudr", "pudrs", folder)
  # if (file_list$file_iteration[i]=="initial"){
  #   version = "iterations"
  # } else if (file_list$file_iteration[i]=="revision"){
  #   version= "revisions"
  # } else {
  #   version = ""
  # }
  # grant_period = file_list$grant_period[i]
  # 
  # dir = paste0(master_file_dir, file_list$grant_status[i], "/", file_list$grant[i], "/", grant_period, "/", folder, "/")
  # if (version != ""){
  #   dir = paste0(dir, version, "/")
  # }
  # inFile = file_list$file_name[i]
  # sheet_name = file_list$sheet_impact_outcome_1a[i]
  # language = file_list$language_1a[i]

  # Sanity check: Is this sheet name one you've checked before? 
  verified_sheet_names <- c('Impact Outcome Indicators_1A', 'Indicateurs Impact Effet_1A')
  if (!sheet_name%in%verified_sheet_names){
    print(sheet_name)
    stop("This sheet name has not been run with this function before - Are you sure you want this function? Add sheet name to verified list within function to proceed.")
  }
  
  # Load/prep data
  gf_data <-data.table(read.xlsx(paste0(dir,inFile), sheet=sheet_name, detectDates=TRUE))
  
  #------------------------------------------------------
  # 1. Select columns, and fix names 
  #------------------------------------------------------
  impact_col = grep("Impact/Outcome", gf_data)
  if (length(impact_col)==0 & language=="esp"){
    impact_col = grep("Impacto/Resultados", gf_data)
  } else if (length(impact_col)==0 & language=="fr"){
    impact_col = grep("Impact / Effet", gf_data)
  }
  if (length(impact_col)>1){
    impact_col = impact_col[1]
  }
  stopifnot(length(impact_col)==1)
  name_row = grep("Impact / Effet|Impact / Outcome|Impacto/Resultados", gf_data[[impact_col]])
  stopifnot(length(name_row)==1)
  
  names = gf_data[name_row, ]
  names = tolower(names)
  names = gsub("\\.", "_", names)
  
  #Drop out the comments column, and record ID column. 
  # If the impact/outcome column is 2, remove the first column. 
  comment_col = grep("comment|comentarios", names) 
  record_id_col = grep("record id", tolower(gf_data))
  stopifnot(length(record_id_col)==1 | is.na(record_id_col)) #Just don't drop more than one column here. 
  gf_data = gf_data[, !c(comment_col, record_id_col), with=FALSE] 
  if (impact_col==2){
    gf_data = gf_data[, 2:ncol(gf_data)] #Drop the first two columns in this case, they're unnecessary. 
  }
  
  #------------------------------------------------------
  # 2. Reset names after subset above. 
  #------------------------------------------------------
  
  impact_col = grep("Impact/Outcome Indicators|Impacto/Resultados|Indicateurs d'impact/d'effet|Indicateurs d'impact / d'effet", gf_data)
  stopifnot(length(impact_col)==1)
  name_row = grep("Impact / Effet|Impact / Outcome|Impacto/Resultados", gf_data[[impact_col]])
  stopifnot(length(name_row)==1)
  
  names = gf_data[name_row, ]
  names = tolower(names)
  names = gsub("\\.", "_", names)
  
  names(gf_data) = names

  #Drop everything before the name row, because it isn't needed 
  gf_data = gf_data[(name_row+1):nrow(gf_data)] #Go ahead and drop out the name row here too because you've already captured it
  sub_names = as.character(gf_data[1, ])
  
  #------------------------------------------------------
  # 3. Rename columns 
  #------------------------------------------------------
  
  #Remove diacritical marks from names to make grepping easier
  names = fix_diacritics(names)
  names = gsub("\\n", "", names)
  
  if (language == "fr"){
    reference_col = grep("reference", names)
    target_col = grep("cible", names)
    result_col = grep("resultat", names)
    lfa_result_col = grep("verified result", names)
    gf_result_col = grep("global fund validated result", names) 
  } else if (language == "eng"){
    reference_col = grep("baseline", names) 
    target_col = grep("target", names)
    result_col = grep("result", names) 
    lfa_result_col = grep("verified result", names)
    gf_result_col = grep("global fund validated result|validated result", names)
  } else if (language=="esp"){
    reference_col = grep("linea de base", names) 
    target_col = grep("meta", names)
    result_col = grep("resultado", names) 
    lfa_result_col = grep("verified result", names)
    gf_result_col = grep("global fund validated result", names)
  }
  
  #Fix result col by language
  if (length(result_col)>1 & language=="eng"){ #The word 'result' appears several times for English files, and you just want the first column here. 
    result_col = result_col[1]
  } else if (length(result_col)>1 & language=="esp" & 1%in%result_col){ #For some Spanish files, the first column has the word "resultados" in it. 
    result_col = result_col[2]
  } else if (length(result_col)>1 & language=="fr"){
    result_col = result_col[1]
  }
  
  #Fix target col
  if (length(target_col)>1){
    target_col = target_col[1]
  }
  
  #Validate that you grabbed exactly 5 columns. 
  flagged_col_list = c(reference_col, target_col, result_col, lfa_result_col, gf_result_col)
  
  #Sometimes, sheets don't have gf_result_col, so if this is the only one that's NA then it's ok. 
  if (length(gf_result_col)==0){
    stopifnot(length(flagged_col_list)==4)
  } else {
    stopifnot(length(flagged_col_list)==5)
  }
  
  #------------------------------------------------------------
  # DYNAMICALLY RE-ASSIGN NAMES (DUE TO MULTIPLE FILE FORMATS)
  #------------------------------------------------------------
  #1. Tag the names that you currently have. 
  #2. Match them from a list of previously tagged names. 
  #3. Build up a list of correctly named vectors in the order in which it appears. 
  # 4. Reset names 
  
  #---------------------------------------------
  # MAIN NAMES 
  #---------------------------------------------
  
  #Acceptable raw column names - will be matched to corrected names below. 
  impact_names = c('impact / effet ', "impact / outcome ", "impacto/resultados")
  standard_ind_names = c('indicateurs', "impact/outcome indicator", "standard impact/outcome indicator", "indicador ")
  custom_ind_names = c("custom impact/outcome indicator", "custom coverage indicator")
  geography_names = c('geographic area', 'geographie', 'geografia')
  cumulative_target_names = c('targets cumulative?', "cibles cumulatives ?")
  reverse_ind_names = c("reverse indicator?")
  
  baseline_names = c('baseline (if applicable)', "baseline _x000d_(if applicable)", "reference", "reference (le cas echeant)",  "linea de base(si corresponde)")
  target_names = c('target', 'cible', 'meta')
  target_date_names = c('echeance de rapport', 'report due date', "fecha de presentacion del informe")
  result_names = c('result', 'resultats', 'resultat', "resultado ")
  lfa_result_names = c('verified result')
  gf_result_names = c('validated result', "global fund validated result")
  
  #Correct these matched names. 
  names[which(names%in%impact_names)] = "indicator_type"
  names[which(names%in%standard_ind_names)] = "indicator"
  names[which(names%in%custom_ind_names)] = "custom_indicator"
  names[which(names%in%geography_names)] = "geography"
  names[which(names%in%cumulative_target_names)] = "cumulative_target"
  names[which(names%in%reverse_ind_names)] = "reverse_indicator"
  
  names[which(names%in%baseline_names)] = "baseline"
  names[which(names%in%target_names)] = "target"
  names[which(names%in%target_date_names)] = "report_due_date"
  names[which(names%in%result_names)] = "pr_result"
  names[which(names%in%lfa_result_names)] = "lfa_result"
  names[which(names%in%gf_result_names)] = "gf_result"
  
  
  #Where 'verification method' exists in the names vector, move to the sub-names vector 
  verification_method_names = c('verification method', "data validation checks on pr data", "data validation checks on lfa data", "data validation checks on gf data")
  ver_method_indices = which(names%in%verification_method_names)
  stopifnot(is.na(unique(sub_names[ver_method_indices])))
  sub_names[ver_method_indices] = "verification_method"
  names[ver_method_indices] = NA
  
  #Where 'source' exists in the names vector, move to the sub-names vector 
  data_source_names = c('source', "source de donnees des resultats", "fuente de datos de los resultados")
  source_indices = which(names%in%data_source_names)
  stopifnot(is.na(unique(sub_names[source_indices])))
  sub_names[source_indices] = "source"
  names[source_indices] = NA
  
  #Where 'year' exists in the names vector, move to the sub-names vector 
  year_names = c('year of target', 'anee du resultat', 'annee du resultat', 'year of result',
                 "annee de la cible", "aoo de resultado", "aoo de meta")
  year_indices = which(names%in%year_names)
  stopifnot(is.na(unique(sub_names[year_indices])))
  sub_names[year_indices] = "year"
  names[year_indices] = NA
  
  names = trimws(names)
  #Make sure you've tagged all names correctly so far. 
  accepted_names = c("indicator_type", "indicator", "custom_indicator", "geography", 
                     "cumulative_target", "reverse_indicator", "baseline", "target", "report_due_date", "pr_result", "lfa_result", "gf_result")
  if (verbose){
    print("These are the variable names that haven't been correctly tagged.")
    print(names[!names%in%c(accepted_names, NA)])
  }
  stopifnot(names%in%accepted_names | is.na(names))
  
  #----------------------------------
  # SUB-NAMES 
  #----------------------------------
  num_names = c("N#")
  denom_names = c("D#")
  proportion_names = c("%")
  year_names = c("Year", "Année")
  verification_source_names = c("Source", "source")
  value_names = c("Value", "Valeur", "Valor")
  
  sub_names[which(sub_names%in%num_names)] = "n"
  sub_names[which(sub_names%in%denom_names)] = "d"
  sub_names[which(sub_names%in%proportion_names)] = "%"
  sub_names[which(sub_names%in%year_names)] = "year"
  sub_names[which(sub_names%in%verification_source_names)] = "source"
  sub_names[which(sub_names%in%value_names)] = "value"
  
  #Certain column names are okay to change to NA here. 
  na_names = c("If sub-national, please specify under the \"Comments\" Column", "Si infranationale, veuillez préciser dans la colonne des commentaires")
  sub_names[which(sub_names%in%na_names)] = ""
  
  #The sub-names under the baseline don't adequately name the columns. 
  #Only run this for cases you've verified. 
  if (reference_col==3 & target_col==5){
    sub_names[3]="value"
    sub_names[4]="year"
  } else if (!(reference_col==3 & target_col==5)){
    warning("Check that baseline data is being tagged correctly with the sub-names vector!")
  }
  
  accepted_sub_names = c('n', 'd', '%', 'year', 'source', 'achievement_ratio', 'verification_method', 'value')
  if (verbose){
    print("These are the sub-names that haven't been correctly tagged.")
    print(sub_names[!sub_names%in%c(accepted_sub_names, NA)])
  }
  stopifnot(sub_names%in%accepted_sub_names | is.na(sub_names))
  
  #------------------------------------------
  # REASSIGN NAMES USING CORRECTED VECTORS
  
  #First, extend each of the 'flag' column names to cover the whole span. 
  target_date_col = grep("report_due_date", names)
  stopifnot(length(target_date_col)==1)
  
  names[reference_col:(target_col-1)] = "baseline"
  names[target_col:(target_date_col-1)] = "target"
  names[result_col:(lfa_result_col-1)] = "pr_result"
  
  if (length(gf_result_col)!=0){
    names[lfa_result_col:(gf_result_col-1)] = "lfa_result"
    names[gf_result_col:length(names)] = "gf_result"
  } else {
    names[lfa_result_col:length(names)] = "lfa_result"
  }
  
  stopifnot(!is.na(names))
  
  #Second, append names and subnames. 
  stopifnot(length(names)==length(sub_names))
  final_names = names
  for (i in 1:length(sub_names)){
    if (!is.na(sub_names[i])){
      final_names[i] = paste0(names[i], "_", sub_names[i])
    }
  }
  
  #Make sure your name vector still matches the length of the data! 
  stopifnot(length(final_names)==ncol(gf_data))
  names(gf_data) = final_names
  #------------------------------------------------------
  # 2. Drop out empty rows 
  #------------------------------------------------------
  
  #Drop out rows that have NAs, and drop the sub names column. 
  gf_data = gf_data[-c(1)] 
  gf_data = gf_data[!(is.na(indicator_type) & is.na(indicator)), ] 
  
  return(gf_data)
}


