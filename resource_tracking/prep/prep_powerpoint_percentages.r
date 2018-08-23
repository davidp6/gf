
rm(list=ls())
library(data.table)
library(ggplot2)
# root directory
dir = 'J:/Project/Evaluation/GF/resource_tracking/multi_country/mapping/'
# input file
inFile = paste0(dir, 'total_resource_tracking_data.csv')
# load
data = fread(inFile)

data = data[country == "Uganda"]

fgh_data = data[data_source == "fgh"]
fgh_data = data[fin_data_type == "actual" | fin_data_type == "model_estimates" | fin_data_type == "forecasted_mean"]
fgh_disbursment = fgh_data[,sum(disbursement),by=c('financing_source','year', 'disease')][order(financing_source, year)]

current_fgh = fgh_disbursment[year > 2014 & year < 2018] 
future_fgh = fgh_disbursment[year > 2017 & year < 2021] 

fpm_data = data[data_source == "fpm"]
fpm_budget = fpm_data[,sum(budget),by=c('financing_source','year', "disease")][order(financing_source, year)]

current_fpm = fpm_budget[year > 2014 & year < 2018]
future_fpm = fpm_budget[year > 2017 & year < 2021] 

prep_dah_of_TotalExpend = function(expenditure, time_frame){
  ### Percentage of total health expenditure provided through international development assistance 2015-2017 // 2018-2020
  # (dah + dah_other) / the
  expenditure$disease = NULL
  expenditure$year = NULL
  expenditure = expenditure[, total_disbursed:= sum(V1), by = 'financing_source']
  expenditure$V1 = NULL
  expenditure = unique(expenditure)
  
  numerator = expenditure[]
  numerator = expenditure[financing_source == "dah" |financing_source == "other_dah" | financing_source == "bil_usa" | financing_source == "gf", sum(total_disbursed)]
  denominator = sum(expenditure$total_disbursed)
  
  dt = data.table(source = "dah_of_TotalExpend", years = time_frame, value = numerator/denominator, disease = "all")
  
  return(dt)
}

yearly_totalExp = fgh_disbursment
yearly_totalExp$disease = NULL
yearly_totalExp = yearly_totalExp[, total_disbursed:= sum(V1), by = c('financing_source', 'year')]
yearly_totalExp$V1 = NULL

numerator = yearly_totalExp[financing_source == "dah" |financing_source == "other_dah" | financing_source == "bil_usa" | financing_source == "gf", sum(total_disbursed), by = "year"]
denominator = yearly_totalExp[,sum(total_disbursed), by = "year"]
denominator$denom = denominator$V1 
denominator$V1 = NULL

total = merge(numerator, denominator, by = "year")
total$divided = total$V1 / total$denom
total = total[year > 2014 & year < 2021] 
total$V1 = NULL
total$denom = NULL
write.csv(total, "J:/temp/ninip/yearlyExp.csv")
#denominator = [financing_source == "dah" |financing_source == "other_dah" | financing_source == "bil_usa" | financing_source == "gf", sum(total_disbursed)]

prep_disease_focused_disburse = function(fpm, fgh, disease_name, time_frame){
  ### Percentage of malaria-focused international development assistance provided by The Global Fund 2015-2017 // 2018-2020
  # fpm_budget(gf) / fgh_disbursemnet(bil_usa + other_dah + dah_other)
  
  fpm_vals = fpm[disease == disease_name & financing_source == "gf"]
  numerator = sum(fpm_vals$V1)
  
  fgh_vals = fgh[disease == disease_name]
  #fgh_vals = fgh[financing_source %in% c("bil_usa", "other_dah", "gf", "dah")]
  #fgh_vals$disease = NULL
  fgh_vals$year = NULL
  fgh_vals$financing_source = NULL
  
  
  fgh_total = fgh_vals[, total_disbursed:= sum(V1), by = 'disease']
  fgh_total$V1 = NULL
  fgh_total= unique(fgh_total)
  denominator = fgh_total$total_disbursed
  #denominator = fgh_total[financing_source %in% c("bil_usa", "other_dah", "gf", "dah"), sum(total_disbursed)]
  
  dt = data.table(source = paste(disease_name, "focused disbursement"), years = time_frame, value = numerator/denominator, disease = disease_name)
  
  return(dt)
}

total_exp = rbind(prep_dah_of_TotalExpend(current_fgh, "2015-2017"), prep_dah_of_TotalExpend(future_fgh, "2018-2020"))

malaria_disbursment = rbind(prep_disease_focused_disburse(current_fpm, current_fgh, "malaria", "2015 - 2017"), 
                            prep_disease_focused_disburse(future_fpm , future_fgh,"malaria", "2018 - 2020"))

hiv_disbursment = rbind(prep_disease_focused_disburse(current_fpm, current_fgh, "hiv", "2015 - 2017"), 
                            prep_disease_focused_disburse(future_fpm , future_fgh,"hiv", "2018 - 2020"))
tb_disbursment = rbind(prep_disease_focused_disburse(current_fpm, current_fgh, "tb", "2015 - 2017"), 
                            prep_disease_focused_disburse(future_fpm , future_fgh,"tb", "2018 - 2020"))
### Percentage of malaria-focused international development assistance provided by partners 2015-2017 // 2018-2020
malaria_focused_partners = 1 - malaria_focused_disbursment


#Percentage of Global Fund malaria investments allocated for treatment 2015-2017 // 2018-2020
# subset fpm -----------abbrev_intervention / total fpm malaria spending
fpm_disease = fpm_data[disease == "malaria"]
future = fpm_disease[year > 2017 & year < 2021]
current = fpm_disease[year > 2014 & year < 2018]

malaria_invest = function(fpm, time_frame){
  denominator = sum(fpm$budget)
  
  malaria_treatment = subset(fpm, abbrev_intervention == "Facility-based treatment" | abbrev_intervention == "iCCM" |
                               abbrev_intervention =="Severe malaria"  | abbrev_intervention == "Private sector case management")
  
  malaria_treatment_t2 = subset(fpm, abbrev_intervention == "Facility-based treatment" | abbrev_intervention == "iCCM" |
                                  abbrev_intervention =="Severe malaria"  | abbrev_intervention == "Private sector case management" | 
                                  abbrev_intervention == "Procurement strategy" | abbrev_intervention == "Nat. product selection")
  numerator_1 = sum(malaria_treatment$budget)
  numerator_2 = sum(malaria_treatment_t2$budget)
  return(data.table(source = "treament allocation focused disbursement", years = time_frame, value = numerator_1/denominator, value_natProd = numerator_2/denominator))
}


malaria_distrub = rbind(malaria_invest(current, "2015-2017"), malaria_invest(future, "2018-2020"))

fpm_disease = fpm_disease[,c("year", "financing_source", "budget", "abbrev_intervention")]
denominator = fpm_disease[, total_disbursed:= sum(budget), by = c('financing_source', 'year')]
denominator$abbrev_intervention = NULL
denominator$budget = NULL
denominator$financing_source = NULL
denominator = unique(denominator)
malaria_treatment = subset(fpm_disease, abbrev_intervention == "Facility-based treatment" | abbrev_intervention == "iCCM" |
                               abbrev_intervention =="Severe malaria"  | abbrev_intervention == "Private sector case management")
  
malaria_treatment_t2 = subset(fpm_disease, abbrev_intervention == "Facility-based treatment" | abbrev_intervention == "iCCM" |
                                  abbrev_intervention =="Severe malaria"  | abbrev_intervention == "Private sector case management" | 
                                  abbrev_intervention == "Procurement strategy" | abbrev_intervention == "Nat. product selection")

numerator = malaria_treatment[, numerator:= sum(budget), by = c('financing_source', 'year')]
numerator$budget = NULL
numerator$financing_source = NULL
numerator$abbrev_intervention = NULL
numerator$total_disbursed = NULL
numerator = unique(numerator)

total_mal = merge(numerator, denominator, by = "year")
total_mal$divided = total_mal$numerator / total_mal$total_disbursed
total_mal= total_mal[year > 2014 & year < 2021] 
total$V1 = NULL
total$denom = NULL
write.csv(total, "J:/temp/ninip/yearlyExp.csv")

merge()

numerator_2 = sum(malaria_treatment_t2$budget)
#return(data.table(source = "treament allocation focused disbursement", years = time_frame, value = numerator_1/denominator, value_natProd = numerator_2/denominator))





# 
# # # # # subset
# data = data[country=="Uganda"]
# fgh_data = data[data_source=='fgh' & disease%in%c('all','malaria')]
# 
# # compute disease-percentages from actuals
# all_dah = fgh_data[fin_data_type=='forecasted_mean' & financing_source=='dah', c('disbursement','year')]
# disease_dah = fgh_data[fin_data_type=='actual' & grepl('total', module), .(total=sum(disbursement)), by=c('year','disease')]
# disease_dah = dcast.data.table(disease_dah, year~disease, value.var='total')
# all_dah = merge(all_dah, disease_dah, by='year', all.x=TRUE)
# all_dah[, pct_malaria:=malaria/disbursement]
# 
# # extend the last percentage forward
# last_value = all_dah[!is.na(pct_malaria)][year==max(year)]$pct_malaria
# all_dah[is.na(malaria), malaria:=last_value*disbursement]
# all_dah[is.na(pct_malaria), pct_malaria:=last_value]
# 
# # compute number that's from the global fund
# fpm_data = data[data_source=='fpm' & disease=='malaria']
# fpm_data = fpm_data[, .(gf=sum(budget)), by='year']
# all_dah = merge(all_dah, fpm_data, by='year')
# 
# # aggregate by window
# all_dah[year>=2015 & year<=2017, window:='2015-2017']
# all_dah[year>=2018, window:='2018-2020']
# 
# agg = all_dah[, .(malaria=sum(malaria), gf=sum(gf)), by='year']
# agg[, pct_gf:=gf/malaria]
# agg

# # 


dt = fread("J:/temp/ninip/PowerPoint_ToGRaph.csv")
pdf("J:/temp/ninip/graphs.pdf", height=5.5, width=8)
ggplot(dt, aes(x = year, y = Percent * 100, color = Value)) + 
  geom_line() +
  geom_point() +
  labs(title = "" , y = "Percent", x = "", color = "") +
  theme_bw(base_size=16) + 
  theme(legend.position = "bottom", legend.direction = "vertical")
dev.off()