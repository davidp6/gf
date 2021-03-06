# model: sen_tb_model1
# purpose: intended to be version 1 of the model (both halves combined into one)

model = '
    # linkage 1 regressions
    com_mobsoc_cumulative ~ lag_other_dah_T1_cumulative + lag_exp_T1_cumulative
    com_cause_cumulative ~ lag_other_dah_T1_cumulative + lag_exp_T1_cumulative
    com_radio_cumulative ~ lag_other_dah_T1_cumulative + lag_exp_T1_cumulative
    
    tot_genexpert_cumulative ~ lag_other_dah_T1_cumulative + lag_exp_T1_cumulative + lag_other_dah_T3_cumulative + lag_exp_T3_cumulative
    
    # linkage 2 regresions
    
    com_enf_ref_cumulative ~ com_mobsoc_cumulative 
    com_nom_touss_cumulative ~ com_mobsoc_cumulative + com_cause_cumulative + com_radio_cumulative
    tb_tfc_cumulative ~ com_mobsoc_cumulative + tot_genexpert_cumulative + perf_lab + lag_other_dah_T1_cumulative + lag_exp_T1_cumulative
    
    perf_lab ~ lag_other_dah_T1_cumulative + lag_exp_T1_cumulative
    ntr_all_cumulative ~ lag_exp_R2_cumulative + lag_other_dah_R3_cumulative + com_mobsoc_cumulative + tb_tfc_cumulative + lag_other_dah_T1_cumulative + lag_exp_T1_cumulative
    
    tb_vih_arv_cumulative ~ lag_exp_T2_cumulative
    
    dx_count_cumulative ~ lag_exp_T3_cumulative + lag_other_dah_T3_cumulative + tot_genexpert_cumulative + lag_other_dah_T1_cumulative + lag_exp_T1_cumulative
    
    # linkage 3 regressions
    
    tbvih_arvtx_rate ~ tb_vih_arv_cumulative
    
    tpm_chimio_enf_cumulative ~ com_enf_ref_cumulative
    
    gueris_taux ~ com_enf_ref_cumulative + com_nom_touss_cumulative + ntr_all_cumulative
    
    mdr_tx_rate ~ dx_count_cumulative
    
    
    
    # fixed variances
    
    # covariances

    # latent variable
'


