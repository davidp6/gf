
# ----------------------------------------------
# function to prep the DRC PNLP data
  prep_data <- function(dataSheet, sheetname, index){
    
  # column names
  # ----------------------------------------------
      columnNames2016 <- c("province", "dps", "health_zone", "donor", "operational_support_partner", "population", "quarter", "month", 
                               "totalCasesAllDiseases_under5", "totalCasesAllDiseases_5andOlder", "totalCasesAllDiseases_pregnantWomen", 
                               "suspectedMalaria_under5", "suspectedMalaria_5andOlder", "suspectedMalaria_pregnantWomen",
                               "newCasesMalariaMild_under5", "newCasesMalariaMild_5andOlder", "newCasesMalariaMild_pregnantWomen", 
                               "totalHospAllDiseases_under5", "totalHospAllDiseases_5andOlder", "totalHospAllDiseases_pregnantWomen",
                               "newCasesMalariaSevere_under5", "newCasesMalariaSevere_5andOlder", "newCasesMalariaSevere_pregnantWomen",
                               "mildMalariaTreated_under5", "mildMalariaTreated_5andOlder", "mildMalariaTreated_pregnantWomen",
                               "severeMalariaTreated_under5", "severeMalariaTreated_5andOlder", "severeMalariaTreated_pregnantWomen",
                               "totalDeathsAllDiseases_under5", "totalDeathsAllDiseases_5andOlder", "totalDeathsAllDiseases_pregnantWomen",
                               "malariaDeaths_under5", "malariaDeaths_5andOlder", "malariaDeaths_pregnantWomen",  
                               "ANC_1st", "ANC_2nd", "ANC_3rd", "ANC_4th", "SP_1st", "SP_2nd","SP_3rd", 
                               "ITN_received", "ITN_distAtANC", "ITN_distAtPreschool", "VAR_0to11mos", 
                               "ASAQ_received_2to11mos", "ASAQ_received_1to5yrs", "ASAQ_received_6to13yrs", "ASAQ_received_14yrsAndOlder",
                               "ASAQ_used_2to11mos", "ASAQ_used_1to5yrs", "ASAQ_used_6to13yrs", "ASAQ_used_14yrsAndOlder", "ASAQ_used_total",
                               "ArtLum_received", "ArtLum_used",
                               "stockOut_SP", "stockOut_ASAQ_2to11mos", "stockOut_ASAQ_1to5yrs", "stockOut_ASAQ_6to13yrs", "stockOut_ASAQ_14yrsAndOlder", 
                               "stockOut_qui_pill", "stockOut_qui_inj", "stockOut_ASAQ_inj", "stockOut_RDT", "stockOut_artLum",
                               "smearTest_completedUnder5", "smearTest_completed5andOlder", "smearTest_positiveUnder5", "smearTest_positive5andOlder", 
                               "RDT_received", "RDT_completedUnder5", "RDT_completed5andOlder", "RDT_positiveUnder5", "RDT_positive5andOlder",
                               "PMA_ASAQ", "PMA_TPI", "PMA_ITN", "PMA_complete",
                               "reports_received", "reports_expected", "healthFacilities_total", "healthFacilities_numReported", "healthFacilities_numReportedWithinDeadline",
                               "hzTeam_supervisors_numPlanned", "hzTeam_supervisors_numActual", "hzTeam_employees_numPlanned", "hzTeam_employees_numActual",
                               "awarenessTrainings_numPlanned", "awarenessTrainings_numActual",
                               "SSC_fevers", "SSC_RDT_completed", "SSC_RDT_positive", 
                               "SSC_ACT", "SSC_casesReferred", "SSC_casesCrossReferred")
      
      columnNames2015 <- c("province", "dps", "health_zone", "donor", "operational_support_partner", "population", "quarter", "month", 
                           "totalCasesAllDiseases_under5", "totalCasesAllDiseases_5andOlder", "totalCasesAllDiseases_pregnantWomen", 
                           "suspectedMalaria_under5", "suspectedMalaria_5andOlder", "suspectedMalaria_pregnantWomen",
                           "newCasesMalariaMild_under5", "newCasesMalariaMild_5andOlder", "newCasesMalariaMild_pregnantWomen", 
                           "totalHospAllDiseases_under5", "totalHospAllDiseases_5andOlder", "totalHospAllDiseases_pregnantWomen",
                           "newCasesMalariaSevere_under5", "newCasesMalariaSevere_5andOlder", "newCasesMalariaSevere_pregnantWomen",
                           "mildMalariaTreated_under5", "mildMalariaTreated_5andOlder", "mildMalariaTreated_pregnantWomen",
                           "severeMalariaTreated_under5", "severeMalariaTreated_5andOlder", "severeMalariaTreated_pregnantWomen",
                           "totalDeathsAllDiseases_under5", "totalDeathsAllDiseases_5andOlder", "totalDeathsAllDiseases_pregnantWomen",
                           "malariaDeaths_under5", "malariaDeaths_5andOlder", "malariaDeaths_pregnantWomen",  
                           "ANC_1st", "ANC_2nd", "ANC_3rd", "ANC_4th", "SP_1st", "SP_2nd","SP_3rd", 
                           "ITN_received", "ITN_distAtANC", "ITN_distAtPreschool", "VAR_0to11mos", 
                           "ASAQ_received_2to11mos", "ASAQ_received_1to5yrs", "ASAQ_received_6to13yrs", "ASAQ_received_14yrsAndOlder",
                           "ASAQ_used_2to11mos", "ASAQ_used_1to5yrs", "ASAQ_used_6to13yrs", "ASAQ_used_14yrsAndOlder", "ASAQ_used_total",
                           "ArtLum_received", "ArtLum_used",
                           "stockOut_SP", "stockOut_ASAQ_2to11mos", "stockOut_ASAQ_1to5yrs", "stockOut_ASAQ_6to13yrs", "stockOut_ASAQ_14yrsAndOlder", 
                           "stockOut_qui_pill", "stockOut_qui_inj", "stockOut_ASAQ_inj", "stockOut_RDT", "stockOut_artLum",
                           "smearTest_completedUnder5", "smearTest_completed5andOlder", "smearTest_positiveUnder5", "smearTest_positive5andOlder", 
                           "RDT_received", "RDT_completedUnder5", "RDT_completed5andOlder", "RDT_positiveUnder5", "RDT_positive5andOlder",
                           "PMA_ASAQ", "PMA_TPI", "PMA_ITN", "PMA_complete",
                           "reports_received", "reports_expected", "healthFacilities_total", "healthFacilities_numReported", "healthFacilities_numReportedWithinDeadline",
                           "hzTeam_supervisors_numPlanned", "hzTeam_supervisors_numActual", 
                           "awarenessTrainings_numPlanned", "awarenessTrainings_numActual",
                           "SSC_fevers", "SSC_RDT_completed", "SSC_RDT_positive", 
                           "SSC_ACT", "SSC_casesReferred", "SSC_casesCrossReferred")
      
      columnNamesComplete <- c("province", "dps", "health_zone", "donor", "operational_support_partner", "population", "quarter", "month", 
                               "totalCasesAllDiseases_under5", "totalCasesAllDiseases_5andOlder", "totalCasesAllDiseases_pregnantWomen", 
                               "suspectedMalaria_under5", "suspectedMalaria_5andOlder", "suspectedMalaria_pregnantWomen",
                               "presumedMalaria_under5", "presumedMalaria_5andOlder", "presumedMalaria_pregnantWomen",
                               "newCasesMalariaMild_under5", "newCasesMalariaMild_5andOlder", "newCasesMalariaMild_pregnantWomen", 
                               "totalHospAllDiseases_under5", "totalHospAllDiseases_5andOlder", "totalHospAllDiseases_pregnantWomen",
                               "newCasesMalariaSevere_under5", "newCasesMalariaSevere_5andOlder", "newCasesMalariaSevere_pregnantWomen",
                               "mildMalariaTreated_under5", "mildMalariaTreated_5andOlder", "mildMalariaTreated_pregnantWomen",
                               "severeMalariaTreated_under5", "severeMalariaTreated_5andOlder", "severeMalariaTreated_pregnantWomen",
                               "totalDeathsAllDiseases_under5", "totalDeathsAllDiseases_5andOlder", "totalDeathsAllDiseases_pregnantWomen",
                               "malariaDeaths_under5", "malariaDeaths_5andOlder", "malariaDeaths_pregnantWomen",  
                               "ANC_1st", "ANC_2nd", "ANC_3rd", "ANC_4th", "SP_1st", "SP_2nd","SP_3rd", 
                               "ITN_received", "ITN_distAtANC", "ITN_distAtPreschool", "VAR_0to11mos", 
                               "ASAQ_received_2to11mos", "ASAQ_received_1to5yrs", "ASAQ_received_6to13yrs", "ASAQ_received_14yrsAndOlder",
                               "ASAQ_used_2to11mos", "ASAQ_used_1to5yrs", "ASAQ_used_6to13yrs", "ASAQ_used_14yrsAndOlder", "ASAQ_used_total",
                               "ArtLum_received", "ArtLum_used",
                               "stockOut_SP", "stockOut_ASAQ_2to11mos", "stockOut_ASAQ_1to5yrs", "stockOut_ASAQ_6to13yrs", "stockOut_ASAQ_14yrsAndOlder", 
                               "stockOut_qui_pill", "stockOut_qui_inj", "stockOut_ASAQ_inj", "stockOut_RDT", "stockOut_artLum",
                               "smearTest_completedUnder5", "smearTest_completed5andOlder", "smearTest_positiveUnder5", "smearTest_positive5andOlder", 
                               "RDT_received", "RDT_completedUnder5", "RDT_completed5andOlder", "RDT_positiveUnder5", "RDT_positive5andOlder",
                               "peopleTested_under5", "peopleTested_5andOlder",
                               "PMA_ASAQ", "PMA_TPI", "PMA_ITN", "PMA_complete",
                               "reports_received", "reports_expected", "healthFacilities_total", "healthFacilities_numReported", "healthFacilities_numReportedWithinDeadline",
                               "hzTeam_supervisors_numPlanned", "hzTeam_supervisors_numActual", "hzTeam_employees_numPlanned", "hzTeam_employees_numActual",
                               "awarenessTrainings_numPlanned", "awarenessTrainings_numActual",
                               "SSC_fevers_under5", "SSC_fevers_5andOlder", "SSC_RDT_completedUnder5", "SSC_RDT_completed5andOlder", "SSC_RDT_positiveUnder5", "SSC_RDT_positive5andOlder",
                               "SSC_ACT_under5", "SSC_ACT_5andOlder", "SSC_casesReferred_under5", "SSC_casesReferred_5andOlder",
                               "SSC_casesCrossReferred_under5", "SSC_casesCrossReferred_5andOlder")
      
      columnNames2014 <- c("province", "dps", "health_zone", "donor", "operational_support_partner", "population", "quarter", "month", 
                           "totalCasesAllDiseases_under5", "totalCasesAllDiseases_5andOlder", "totalCasesAllDiseases_pregnantWomen", 
                           "suspectedMalaria_under5", "suspectedMalaria_5andOlder", "suspectedMalaria_pregnantWomen",
                           "newCasesMalariaMild_under5", "newCasesMalariaMild_5andOlder", "newCasesMalariaMild_pregnantWomen", 
                           "totalHospAllDiseases_under5", "totalHospAllDiseases_5andOlder", "totalHospAllDiseases_pregnantWomen",
                           "newCasesMalariaSevere_under5", "newCasesMalariaSevere_5andOlder", "newCasesMalariaSevere_pregnantWomen",
                           "mildMalariaTreated_under5", "mildMalariaTreated_5andOlder", "mildMalariaTreated_pregnantWomen",
                           "severeMalariaTreated_under5", "severeMalariaTreated_5andOlder", "severeMalariaTreated_pregnantWomen",
                           "totalDeathsAllDiseases_under5", "totalDeathsAllDiseases_5andOlder", "totalDeathsAllDiseases_pregnantWomen",
                           "malariaDeaths_under5", "malariaDeaths_5andOlder", "malariaDeaths_pregnantWomen",  
                           "ANC_1st", "SP_1st", "SP_2nd","SP_3rd", 
                           "ITN_received", "ITN_distAtANC", "ITN_distAtPreschool",  
                           "ASAQ_received_2to11mos", "ASAQ_received_1to5yrs", "ASAQ_received_6to13yrs", "ASAQ_received_14yrsAndOlder",
                           "ASAQ_used_2to11mos", "ASAQ_used_1to5yrs", "ASAQ_used_6to13yrs", "ASAQ_used_14yrsAndOlder", "ASAQ_used_total",
                           "stockOut_SP", "stockOut_ASAQ_2to11mos", "stockOut_ASAQ_1to5yrs", "stockOut_ASAQ_6to13yrs", "stockOut_ASAQ_14yrsAndOlder", 
                           "stockOut_qui_pill", "stockOut_qui_inj", "stockOut_ASAQ_inj",
                           "smearTest_completed", "smearTest_positive", "thinSmearTest", 
                           "RDT_received", "RDT_completed", "RDT_positive",
                           "PMA_ASAQ", "PMA_TPI", "PMA_ITN", "PMA_complete",
                           "reports_received", "reports_expected", "healthFacilities_total", "healthFacilities_numReported",
                           "hzTeam_supervisors_numPlanned", "hzTeam_supervisors_numActual",
                           "awarenessTrainings_numPlanned", "awarenessTrainings_numActual"
                          )
      
      columnNames2011to2013 <- c("province", "dps", "health_zone", "donor", "operational_support_partner", "population", "quarter", "month", 
                           "totalCasesAllDiseases_under5", "totalCasesAllDiseases_5andOlder", "totalCasesAllDiseases_pregnantWomen", 
                           "newCasesMalariaMild_under5", "newCasesMalariaMild_5andOlder", "newCasesMalariaMild_pregnantWomen", 
                           "totalHospAllDiseases_under5", "totalHospAllDiseases_5andOlder", "totalHospAllDiseases_pregnantWomen",
                           "newCasesMalariaSevere_under5", "newCasesMalariaSevere_5andOlder", "newCasesMalariaSevere_pregnantWomen",
                           "totalDeathsAllDiseases_under5", "totalDeathsAllDiseases_5andOlder", "totalDeathsAllDiseases_pregnantWomen",
                           "malariaDeaths_under5", "malariaDeaths_5andOlder", "malariaDeaths_pregnantWomen",  
                           "ANC_1st", "SP_1st", "SP_2nd",
                           "ITN_received", "ITN_distAtANC", "ITN_distAtPreschool",
                           "ASAQ_received_2to11mos", "ASAQ_received_1to5yrs", "ASAQ_received_6to13yrs", "ASAQ_received_14yrsAndOlder",
                           "ASAQ_used_2to11mos", "ASAQ_used_1to5yrs", "ASAQ_used_6to13yrs", "ASAQ_used_14yrsAndOlder", "ASAQ_used_total",
                           "stockOut_SP", "stockOut_ASAQ_2to11mos", "stockOut_ASAQ_1to5yrs", "stockOut_ASAQ_6to13yrs", "stockOut_ASAQ_14yrsAndOlder", 
                           "stockOut_qui_pill", "stockOut_qui_inj", 
                           "smearTest_completed", "smearTest_positive", 
                           "RDT_received", "RDT_completed", "RDT_positive",
                           "PMA_ASAQ", "PMA_TPI", "PMA_ITN", "PMA_complete",
                           "reports_received", "reports_expected", "healthFacilities_total", "healthFacilities_numReported"
                          )
      
      columnNames2010 <- c("province", "dps", "health_zone", "donor", "operational_support_partner", "population", "quarter", "month", 
                                   "totalCasesAllDiseases_under5", "totalCasesAllDiseases_5andOlder", "totalCasesAllDiseases_pregnantWomen", 
                                   "newCasesMalariaMild_under5", "newCasesMalariaMild_5andOlder", "newCasesMalariaMild_pregnantWomen", 
                                   "totalHospAllDiseases_under5", "totalHospAllDiseases_5andOlder", "totalHospAllDiseases_pregnantWomen",
                                   "newCasesMalariaSevere_under5", "newCasesMalariaSevere_5andOlder", "newCasesMalariaSevere_pregnantWomen",
                                   "totalDeathsAllDiseases_under5", "totalDeathsAllDiseases_5andOlder", "totalDeathsAllDiseases_pregnantWomen",
                                   "malariaDeaths_under5", "malariaDeaths_5andOlder", "malariaDeaths_pregnantWomen",  
                                   "ANC_1st", "SP_1st", "SP_2nd",
                                   "ITN_received", "ITN_distAtANC", "ITN_distAtPreschool",
                                   "ASAQ_received_2to11mos", "ASAQ_received_1to5yrs", "ASAQ_received_6to13yrs", "ASAQ_received_14yrsAndOlder",
                                   "ASAQ_used_2to11mos", "ASAQ_used_1to5yrs", "ASAQ_used_6to13yrs", "ASAQ_used_14yrsAndOlder", "ASAQ_used_total",
                                   "stockOut_SP", "stockOut_ASAQ_2to11mos", "stockOut_ASAQ_1to5yrs", "stockOut_ASAQ_6to13yrs", "stockOut_ASAQ_14yrsAndOlder", 
                                   "stockOut_qui_pill", "stockOut_qui_inj", 
                                   "smearTest_completed", "smearTest_positive", 
                                   "RDT_received", "RDT_completed", "RDT_positive",
                                   "PMA_ASAQ", "PMA_TPI", "PMA_ITN", "PMA_complete",
                                   "reports_received", "reports_expected", "healthFacilities_total", "healthFacilities_numReported")
     
       columnNames2010KINKOR <- c("province", "dps", "health_zone", "donor", "operational_support_partner", "population", "quarter", "month", 
                           "totalCasesAllDiseases_under5", "totalCasesAllDiseases_5andOlder", "totalCasesAllDiseases_pregnantWomen", 
                           "newCasesMalariaMild_under5", "newCasesMalariaMild_5andOlder", "newCasesMalariaMild_pregnantWomen", 
                           "totalHospAllDiseases_under5", "totalHospAllDiseases_5andOlder", "totalHospAllDiseases_pregnantWomen",
                           "newCasesMalariaSevere_under5", "newCasesMalariaSevere_5andOlder", "newCasesMalariaSevere_pregnantWomen",
                           "totalDeathsAllDiseases_under5", "totalDeathsAllDiseases_5andOlder", "totalDeathsAllDiseases_pregnantWomen",
                           "malariaDeaths_under5", "malariaDeaths_5andOlder", "malariaDeaths_pregnantWomen",  
                           "ANC_1st", "SP_1st", "SP_2nd",
                           "ITN_received", "ITN_distAtANC", "ITN_distAtPreschool",
                           "ASAQ_received_2to11mos", "ASAQ_received_1to5yrs", "ASAQ_received_6to13yrs", "ASAQ_received_14yrsAndOlder",
                           "ASAQ_used_2to11mos", "ASAQ_used_1to5yrs", "ASAQ_used_6to13yrs", "ASAQ_used_14yrsAndOlder", "ASAQ_used_total",
                           "stockOut_SP", "stockOut_ASAQ_2to11mos", "stockOut_ASAQ_1to5yrs", "stockOut_ASAQ_6to13yrs", "stockOut_ASAQ_14yrsAndOlder", 
                           "stockOut_qui_pill", "stockOut_qui_inj", 
                           "smearTest_completed", "smearTest_positive", 
                           "RDT_received", "RDT_completed", "RDT_positive",
                           "PMA_ASAQ", "PMA_TPI", "PMA_ITN", "PMA_complete",
                           "reports_received", "reports_expected")
      
      
  # ----------------------------------------------
    # fix various issues in spelling/typos or extra columns in the data sheet:
      
      if ( PNLP_files$year[index] == 2015 & sheetname == "NK" ) {
        dataSheet <- dataSheet[ , -c("X__71", "X__72", "X__73") ]
      }
      
      if ( PNLP_files$year[index] == 2010 & sheetname == "BC" ) {
        dataSheet <- dataSheet[ , -c("X__62") ]
      }
      
      if ( PNLP_files$year[index] == 2010 ) {
        dataSheet <- dataSheet[ , -c("X__14") ]
      }
      
      if ( PNLP_files$year[index] == 2011 & sheetname != "OR" ) {
        dataSheet <- dataSheet[ , -c("X__14") ]
      }
      
      if ( PNLP_files$year[index] == 2011 & sheetname == "OR" ) {
        dataSheet <- dataSheet[ , -c("X__11", "X__15", "X__25", "X__39") ]
      }
      
      if ((PNLP_files$year[index] == 2014 | PNLP_files$year[index] == 2013 | PNLP_files$year[index] == 2012 | PNLP_files$year[index] == 2011)
          & sheetname == "BC") {
        #dataSheet <- dataSheet[,names(dataSheet)[-length(names(dataSheet))], with=F]
        dataSheet <- dataSheet[, -ncol(dataSheet), with=F ]
      }
      
      if ( PNLP_files$year[index] == 2016 & sheetname == "KIN") {
        dataSheet <- dataSheet[ , -c("X__72", "X__73", "X__74") ]
      }
      
      if (PNLP_files$year[index] == 2010 & sheetname == "BDD") {
        #dataSheet <- dataSheet[,names(dataSheet)[-length(names(dataSheet))], with=F]
        dataSheet <- dataSheet[ , !apply( dt , 2 , function(x) all(is.na(x))), with=F ]
        dataSheet <- dataSheet[, -ncol(dataSheet), with=F ]
      }
      
      if ((PNLP_files$year[index] == 2011) & sheetname == "BDD") {
        #dataSheet <- dataSheet[,names(dataSheet)[-length(names(dataSheet))], with=F]
        dataSheet <- dataSheet[ , !apply( dt , 2 , function(x) all(is.na(x))), with=F ]
        dataSheet <- dataSheet[, -ncol(dataSheet), with=F ]
        dataSheet <- dataSheet[, -ncol(dataSheet), with=F ]
      }
  
    # set column names, depending on differences in years and/or sheets
      if ( PNLP_files$year[index] == 2014 ) {
        columnNames <- columnNames2014
      } else if (PNLP_files$year[index] < 2014 & PNLP_files$year[index] != 2010) {
        columnNames <- columnNames2011to2013
      } else if (PNLP_files$year[index] == 2010 & sheetname != "KIN" & sheetname != "KOR" ) {
        columnNames <- columnNames2010
      } else if (PNLP_files$year[index] == 2016) {
        columnNames <- columnNames2016
      } else if (PNLP_files$year[index] == 2015) {
        columnNames <- columnNames2015
      } else if (PNLP_files$year[index] == 2010 & ( sheetname == "KIN" | sheetname == "KOR")) {
        columnNames <- columnNames2010KINKOR
      } else {
        columnNames <- columnNamesComplete
      }
     
      names(dataSheet) <- columnNames
        
    if (PNLP_files$year[index] == 2012 & sheetname == "EQ"){
      dataSheet <- dataSheet[(totalCasesAllDiseases_under5=="971" & totalCasesAllDiseases_5andOlder=="586" & totalCasesAllDiseases_pregnantWomen=="99"), 
                    province:="Equateur"]
      dataSheet <- dataSheet[(totalCasesAllDiseases_under5=="971" & totalCasesAllDiseases_5andOlder=="586" & totalCasesAllDiseases_pregnantWomen=="99"), 
                             dps:="Sud Uban"]
      dataSheet <- dataSheet[(totalCasesAllDiseases_under5=="971" & totalCasesAllDiseases_5andOlder=="586" & totalCasesAllDiseases_pregnantWomen=="99"), 
                             health_zone:="Libenge"]
      dataSheet <- dataSheet[(totalCasesAllDiseases_under5=="971" & totalCasesAllDiseases_5andOlder=="586" & totalCasesAllDiseases_pregnantWomen=="99"), 
                             month:= "Janvier"]
      dataSheet <- dataSheet[(totalCasesAllDiseases_under5=="977" & totalCasesAllDiseases_5andOlder=="816" & totalCasesAllDiseases_pregnantWomen=="242"), 
                             month:= "Janvier"]
      dataSheet <- dataSheet[(totalCasesAllDiseases_under5=="977" & totalCasesAllDiseases_5andOlder=="816" & totalCasesAllDiseases_pregnantWomen=="242"), 
                             health_zone:="Mawuya"]
      dataSheet <- dataSheet[(health_zone=="Mawuya" & !is.na(population)), health_zone:=NA]
      dataSheet <- dataSheet[!is.na(health_zone)]
      }
      
    # add a column for the "year" to keep track of this variable as we add dataSheets to this one
      dataSheet$year <- PNLP_files$year[index]
      
      # ----------------------------------------------
      # Get rid of rows you don't need- "subset"
      
      # delete rows where the month column is NA (totals rows or any trailing rows)
      dataSheet <- dataSheet[!is.na(month)]
      dataSheet <- dataSheet[!month==0]
      
      # clean "Province" column in BDD datasheet for 2016 and 2015 because
      # it has some missing/"0" values that should be "BDD" - doesn't work
      
      if (sheetname == "BDD"){
        dataSheet <- dataSheet[province==0, province := sheetname]
        dataSheet <- dataSheet[is.na(province), province := sheetname]
      }
      
      if (sheetname == "KOR"){
        dataSheet <- dataSheet[province==0, province := "K.Or"]
        dataSheet <- dataSheet[is.na(province), province := "K.Or"]
      }
      
      if (sheetname == "SK"){
        dataSheet <- dataSheet[province==0, province := "SK"]
        dataSheet <- dataSheet[is.na(province), province := "SK"]
      }
      
      # delete first row if it's first value is "NA" or "PROVINCE" as a way to
      # only delete those unnecessary rows, and not any others accidentally - these
      # were the column headers in the original datasheet in excel.
      dataSheet <- dataSheet[!province %in% c('PROVINCE', 'Province')]
      
        # BDD 2016 sheet has total row in the middle of the data, the other sheets have it
        # in the last row of the sheet, sometimes in the first column, sometimes in the second;
        # sometimes as "Total" and sometimes "TOTAL"
         dataSheet <- dataSheet[!grepl(("TOTAL"), (dataSheet$province)),]
         dataSheet <- dataSheet[!grepl(("Total"), (dataSheet$province)),]
         dataSheet <- dataSheet[!grepl(("total"), (dataSheet$province)),]
         dataSheet <- dataSheet[!grepl(("TOTAL"), (dataSheet$dps)),]
         dataSheet <- dataSheet[!grepl(("Total"), (dataSheet$dps)),]
         dataSheet <- dataSheet[!grepl(("total"), (dataSheet$province)),]

      # ----------------------------------------------
      # translate french to numeric version of month Janvier=1
      # dataSheet[month=='Janvier', month:="01"]
      # grepl() to make sure that any that may have trailing white space are also changed
      dataSheet[grepl("Janvier", month), month:="01"]
      dataSheet[grepl("F�vrier", month), month:="02"]
      dataSheet[grepl("Mars", month), month:="03"]
      dataSheet[grepl("Avril", month), month:="04"]
      dataSheet[grepl("Mai", month), month:="05"]
      dataSheet[grepl("Juin", month), month:="06"]
      dataSheet[grepl("Juillet", month), month:="07"]
      dataSheet[grepl("Ao�t", month), month:="08"]
      dataSheet[grepl("Septembre", month), month:="09"]
      dataSheet[grepl("Octobre", month), month:="10"]
      dataSheet[grepl("Novembre", month), month:="11"]
      dataSheet[grepl("D�cembre", month), month:="12"]
      dataSheet[grepl("janvier", month), month:="01"]
      dataSheet[grepl("f�vrier", month), month:="02"]
      dataSheet[grepl("mars", month), month:="03"]
      dataSheet[grepl("avril", month), month:="04"]
      dataSheet[grepl("mai", month), month:="05"]
      dataSheet[grepl("juin", month), month:="06"]
      dataSheet[grepl("juillet", month), month:="07"]
      dataSheet[grepl("ao�t", month), month:="08"]
      dataSheet[grepl("septembre", month), month:="09"]
      dataSheet[grepl("octobre", month), month:="10"]
      dataSheet[grepl("novembre", month), month:="11"]
      dataSheet[grepl("d�cembre", month), month:="12"]    
      
      # accounting for spelling mistakes/typos/other variations
      dataSheet[grepl("fevrier", month), month:="02"]
      dataSheet[grepl("Fevrier", month), month:="02"]
      dataSheet[grepl("JUIN", month), month:="06"]
      dataSheet[grepl("Aout", month), month:="08"]
      dataSheet[grepl("Septembr", month), month:="09"]
      dataSheet[grepl("Decembre", month), month:="12"]
      
      
      # make string version of the date
      dataSheet[, stringdate:=paste('01', month, year, sep='/')]
      
      # combine year and month into one variable
      dataSheet[, date:=as.Date(stringdate, "%d/%m/%Y")]
      
      # make names of health zones consistent (change abbreviatons to full name in select cases)
      if (PNLP_files$year[index] == 2017 & sheetname == "KOR"){
        dataSheet <- dataSheet[(health_zone=="5" & month=="03" & totalCasesAllDiseases_under5=="3297"), health_zone:= "Kole"]
      }
      
      if (PNLP_files$year[index] == 2015 & sheetname == "EQ"){
        dataSheet <- dataSheet[(health_zone=="Libenge" & month=="01" & totalCasesAllDiseases_under5=="1375"), health_zone:= "Mawuya"]
      }
      
      if (PNLP_files$year[index] == 2017 & sheetname == "EQ"){
        dataSheet <- dataSheet[(health_zone=="Libenge" & month=="01" & totalCasesAllDiseases_under5=="1838"), health_zone:= "Mawuya"]
      }
      
      if (PNLP_files$year[index] == 2016 & sheetname == "EQ"){
        dataSheet <- dataSheet[(health_zone=="Libenge" & month=="01" & totalCasesAllDiseases_under5=="2213"), health_zone:= "Mawuya"]
      }
      
      if (PNLP_files$year[index] == 2014 & sheetname == "EQ"){
        dataSheet <- dataSheet[(health_zone=="Libenge" & month=="01" & totalCasesAllDiseases_under5=="754"), health_zone:= "Mawuya"]
      }
      
      if (PNLP_files$year[index] == 2013 & sheetname == "EQ"){
        dataSheet <- dataSheet[(health_zone=="Libenge" & month=="01" & totalCasesAllDiseases_under5=="1628"), health_zone:= "Mawuya"]
      }
      
      if ((PNLP_files$year[index] == 2014 | PNLP_files$year[index] == 2015 | PNLP_files$year[index] == 2016 | PNLP_files$year[index] == 2017) & sheetname == "KAT"){
        dataSheet <- dataSheet[health_zone=="Mutshat", health_zone:= "Mutshatsha"]
        dataSheet <- dataSheet[health_zone=="Malem Nk", health_zone:= "Malemba Nkulu"]
      }
      
      if (PNLP_files$year[index] == 2013 & sheetname == "BDD"){
        dataSheet <- dataSheet[health_zone=="Koshiba", health_zone:= "Koshibanda"]
      }
      
      if ((PNLP_files$year[index] == 2013 | PNLP_files$year[index] == 2012 )& sheetname == "KOR"){
        dataSheet <- dataSheet[health_zone=="Mbuji May", health_zone:= "Bimpemba"]
      }
      
      if ((PNLP_files$year[index] == 2011 | PNLP_files$year[index] == 2010)& sheetname == "BDD"){
        dataSheet <- dataSheet[health_zone=="KIKWITS", health_zone:= "Kikwit S"]
      }
      
      if ((PNLP_files$year[index] == 2010)& sheetname == "SK"){
        dataSheet <- dataSheet[!is.na(health_zone)]
      }
      
      # there are still some added rows that happen to have something in the month column but are missing data everywhere else
      dataSheet <- dataSheet[!is.na(province)]
      
      dataSheet <- dataSheet[health_zone=="Kabond D", health_zone:= "Kabond Dianda"]
      dataSheet <- dataSheet[health_zone=="Malem Nk", health_zone:= "Malemba Nkulu"]
      dataSheet <- dataSheet[health_zone=="Mutshat", health_zone:= "Mutshatsha"]
      dataSheet <- dataSheet[health_zone=="Kilela B", health_zone:= "Kilela Balanda"]
      dataSheet <- dataSheet[health_zone=="Mufunga", health_zone:= "Mufunga sampwe"]
      dataSheet <- dataSheet[health_zone=="Kafakumb", health_zone:= "Kafakumba"]
      dataSheet <- dataSheet[health_zone=="Kamalond", health_zone:= "Kamalondo"]
      dataSheet <- dataSheet[health_zone=="Kampem", health_zone:= "Kampemba"]
      dataSheet <- dataSheet[health_zone=="Tshamile", health_zone:= "Tshamilemba"]
      dataSheet <- dataSheet[health_zone=="Lshi", health_zone:= "Lubumbashi"]
      dataSheet <- dataSheet[health_zone=="Mumbund", health_zone:= "Mumbunda"]
      dataSheet <- dataSheet[health_zone=="Fungurum", health_zone:= "Fungurume"]
      
      dataSheet$health_zone <- tolower(dataSheet$health_zone)
      
      dataSheet[health_zone=="omendjadi", health_zone := "omondjadi"]
      dataSheet[health_zone=="kiroshe", health_zone := "kirotshe"]
      dataSheet[health_zone=="boma man", health_zone := "boma mangbetu"]
      
      
      dataSheet[health_zone=="mutshat", health_zone := "mutshatsha"]
      dataSheet[health_zone=="mumbund", health_zone := "mumbunda"]
      dataSheet[health_zone=="fungurum", health_zone := "fungurume"]
      dataSheet[health_zone=="yasa", health_zone := "yasa-bonga"]
      dataSheet[health_zone=="malem nk", health_zone := "malemba nkulu"]
      dataSheet[health_zone=="kampem", health_zone := "kampemba"]
      dataSheet[health_zone=="kamalond", health_zone := "kamalondo"]
      dataSheet[health_zone=="pay", health_zone := "pay kongila"]
      dataSheet[health_zone=="kafakumb", health_zone := "kafakumba"]
      dataSheet[health_zone=="tshamile", health_zone := "tshamilemba"]
      dataSheet[health_zone=="ntandem", health_zone := "ntandembele"]
      dataSheet[health_zone=="masi", health_zone := "masimanimba"]
      dataSheet[health_zone=="koshiba", health_zone := "koshibanda"]
      dataSheet[health_zone=="djalo djek", health_zone := "djalo djeka"]
      dataSheet[health_zone=="ludimbi l", health_zone := "ludimbi lukula"]
      dataSheet[health_zone=="mwela l", health_zone := "mwela lembwa"]
      dataSheet[health_zone=="bena le", health_zone := "bena leka"]
      dataSheet[health_zone=="vanga ket", health_zone := "vanga kete"]
      dataSheet[health_zone=="bomineng", health_zone := "bominenge"]
      dataSheet[health_zone=="bogosenu", health_zone := "bogosenusebea"]
      dataSheet[health_zone=="bwamand", health_zone := "bwamanda"]
      dataSheet[health_zone=="banga lu", health_zone := "banga lubaka"]
      dataSheet[health_zone=="bosomanz", health_zone := "bosomanzi"]
      dataSheet[health_zone=="bosomond", health_zone := "bosomondanda"]
      dataSheet[health_zone=="bonganda", health_zone := "bongandanganda"]
      dataSheet[health_zone=="lilanga b", health_zone := "lilanga bobanga"]
      dataSheet[health_zone=="mondomb", health_zone := "mondombe"]
      dataSheet[health_zone=="tshitshim", health_zone := "tshitshimbi"]
      dataSheet[health_zone=="basankus", health_zone := "basankusu"]
      dataSheet[health_zone=="mobayi m", health_zone := "mobayi mbongo"]
      dataSheet[health_zone=="kabond d", health_zone := "kabond dianda"]
      dataSheet[health_zone=="kilela b", health_zone := "kilela balanda"]
      dataSheet[health_zone=="ndjoko m", health_zone := "ndjoko mpunda"]
      dataSheet[health_zone=="benatshia", health_zone := "benatshiadi"]
      dataSheet[health_zone=="tshudi lo", health_zone := "tshudi loto"]
      dataSheet[health_zone=="pania mut", health_zone := "pania mutombo"]
      dataSheet[health_zone=="ndjoko mp", health_zone := "ndjoko mpunda"]
      dataSheet[health_zone=="kalonda e", health_zone := "kalonda est"]
      dataSheet[health_zone=="kata k", health_zone := "kata kokombe"]
      dataSheet[health_zone=="lshi", health_zone := "lubumbashi"]
      dataSheet[health_zone=="bdd", health_zone := "bandundu"]
      dataSheet[health_zone=="kikwit n", health_zone := "kikwit nord"]
      dataSheet[health_zone=="kikwit s", health_zone := "kikwit sud"]
      dataSheet[health_zone=="kasongo l", health_zone := "kasongo lunda"]
      dataSheet[health_zone=="popoka", health_zone := "popokabaka"]
      dataSheet[health_zone=="kanda k", health_zone := "kanda kanda"]
      dataSheet[health_zone=="muene d", health_zone := "muene ditu"]
      dataSheet[health_zone=="wembo n", health_zone := "wembo nyama"]
      dataSheet[health_zone=="bena dib", health_zone := "bena dibele"]
      dataSheet[health_zone=="wamba l", health_zone := "wamba luadi"]
      
      dataSheet[health_zone=="kabeya", health_zone := "kabeya kamwanga"]
      dataSheet[health_zone=="mampoko", health_zone := "lolanga mampoko"]
      dataSheet[health_zone=="mufunga", health_zone := "mufunga sampwe"]
      
      dataSheet[health_zone=="wembo nyana", health_zone := "wembo nyama"]
      dataSheet[health_zone=="kamonya", health_zone := "kamonia"]
      dataSheet[health_zone=="kitangwa", health_zone := "kitangua"]

      
      # ----------------------------------------------
      # Return current data sheet
      return(dataSheet)
      # ----------------------------------------------
    }  
# ----------------------------------------------

 # currentSheet[health_zone=="Mbuji May"| health_zone== "Bimpemba", c(1:9)]
  