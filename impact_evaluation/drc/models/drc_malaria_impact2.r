# model: drc_malaria_impact2.r
# purpose: drc_malaria_impact1 with outputs, RDTs, CHWs and ANC

# to do


model = '

	# linkage 1 regressions
	ITN_rate ~ ITN
	mildMalariaTreated_rate ~ mildMalariaTreated + RDT_rate
	severeMalariaTreated_rate ~ severeMalariaTreated + RDT_rate
	ACTs_CHWs_rate ~ SSCACT
	SP_rate ~ SP
	RDT_rate ~ RDT
	
	# linkage 2 regressions
	lead_newCasesMalariaMild_rate ~ ITN_rate + mildMalariaTreated_rate + ACTs_CHWs_rate + SP_rate + date
	lead_newCasesMalariaSevere_rate ~ ITN_rate + severeMalariaTreated_rate + ACTs_CHWs_rate + SP_rate + date
	lead_malariaDeaths_rate ~ lead_newCasesMalariaMild_rate + lead_newCasesMalariaSevere_rate + mildMalariaTreated_rate + severeMalariaTreated_rate + ACTs_CHWs_rate + SP_rate + date
	
	# latent variables
	
	# fixed variances
	
	# covariances
	
	# fixed covariances
	ITN ~~ 0*mildMalariaTreated
	ITN ~~ 0*severeMalariaTreated
	ITN ~~ 0*SSCACT
	ITN ~~ 0*SP
	ITN ~~ 0*RDT
	mildMalariaTreated ~~ 0*RDT
	mildMalariaTreated ~~ 0*severeMalariaTreated
	mildMalariaTreated ~~ 0*SSCACT
	mildMalariaTreated ~~ 0*SP
	severeMalariaTreated ~~ 0*RDT
	severeMalariaTreated ~~ 0*SSCACT
	severeMalariaTreated ~~ 0*SP
	RDT ~~ 0*SSCACT
	RDT ~~ 0*SP
	RDT ~~ 0*SP
'
