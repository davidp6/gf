# model: drc_malaria5.r
# purpose: drc_malaria4 with controls for completeness

model = '

	# linkage 1 regressions
	ITN_received_cumulative ~ prior("dgamma(1,1)")*exp_M1_1_cumulative + prior("dgamma(1,1)")*exp_M1_2_cumulative + prior("dgamma(1,1)")*other_dah_M1_1_cumulative + date + prior("dgamma(1,1)")*ghe_cumulative + completeness_ITN_received
	RDT_received_cumulative ~ prior("dgamma(1,1)")*exp_M2_1_cumulative + prior("dgamma(1,1)")*other_dah_M2_cumulative + date + prior("dgamma(1,1)")*ghe_cumulative + completeness_RDT_received
	ACT_received_cumulative ~ prior("dgamma(1,1)")*exp_M2_1_cumulative + prior("dgamma(1,1)")*other_dah_M2_cumulative + date + prior("dgamma(1,1)")*ghe_cumulative + completeness_ACT_received
	
	# linkage 1 regressions with hotfixes for heywood cases (temporary)

	
	# linkage 2 regressions
	ITN_consumed_cumulative ~ prior("dgamma(1,1)")*ITN_received_cumulative + completeness_ITN_consumed
	ACTs_SSC_cumulative ~  prior("dgamma(1,1)")*exp_M2_3_cumulative + prior("dgamma(1,1)")*other_dah_M2_3_cumulative + prior("dgamma(1,1)")*ghe_cumulative + completeness_ACTs_SSC
	RDT_completed_cumulative ~ prior("dgamma(1,1)")*RDT_received_cumulative + completeness_RDT_completed
	SP_cumulative ~ prior("dgamma(1,1)")*exp_M3_1_cumulative + date + prior("dgamma(1,1)")*ghe_cumulative + completeness_SP
	severeMalariaTreated_cumulative ~ prior("dgamma(1,1)")*exp_M2_6_cumulative + prior("dgamma(1,1)")*ACT_received_cumulative + date + prior("dgamma(1,1)")*ghe_cumulative + completeness_severeMalariaTreated
	totalPatientsTreated_cumulative ~ prior("dgamma(1,1)")*ACT_received_cumulative + completeness_totalPatientsTreated
	
	# latent variables
	
	# fixed variances
	
	# covariances
	exp_M1_1_cumulative ~~ other_dah_M1_1_cumulative
	exp_M1_2_cumulative ~~ other_dah_M1_1_cumulative
	exp_M2_1_cumulative ~~ other_dah_M2_cumulative
	exp_M2_1_cumulative ~~ other_dah_M2_cumulative
	exp_M2_6_cumulative ~~ other_dah_M2_cumulative
	exp_M2_3_cumulative ~~ other_dah_M2_3_cumulative
	
	# fixed covariances
	exp_M2_3_cumulative ~~ 0*exp_M3_1_cumulative
	exp_M2_3_cumulative ~~ 0*exp_M2_6_cumulative
	exp_M2_6_cumulative ~~ 0*exp_M3_1_cumulative
	
	ITN_consumed_cumulative ~~ 0*ACTs_SSC_cumulative
	ITN_consumed_cumulative ~~ 0*RDT_completed_cumulative
	ITN_consumed_cumulative ~~ 0*SP_cumulative
	ITN_consumed_cumulative ~~ 0*severeMalariaTreated_cumulative
	ITN_consumed_cumulative ~~ 0*totalPatientsTreated_cumulative
	
	ACTs_SSC_cumulative ~~ 0*RDT_completed_cumulative
	ACTs_SSC_cumulative ~~ 0*SP_cumulative
	ACTs_SSC_cumulative ~~ 0*severeMalariaTreated_cumulative
	ACTs_SSC_cumulative ~~ 0*totalPatientsTreated_cumulative
	
	RDT_completed_cumulative ~~ 0*SP_cumulative
	RDT_completed_cumulative ~~ 0*severeMalariaTreated_cumulative
	
	SP_cumulative ~~ 0*severeMalariaTreated_cumulative
	SP_cumulative ~~ 0*totalPatientsTreated_cumulative
	
	severeMalariaTreated_cumulative ~~ 0*totalPatientsTreated_cumulative
'
