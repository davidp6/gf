# Messy code to test out an example of the coutnerfactual analysis
# Copied over from 6_display_results.r

# ----------------------------------------------
# Example counterfactual

# get actual predictions
preds_actual = data.table(predict_lavaan(semFit, newdata=data))

# set up alternative budget
newData = copy(data)

# convert back to actual dollars using scaling factors
if (!all(names(newData)==names(scaling_factors))) stop('Different order of variables in scaling factors')
newData = newData*scaling_factors

# set up counterfactual scenarios
# scenario 1: reallocate 25% from ITNs to ACTs for 2016-2018
newData[, reallocation1:=0]
newData[, reallocation2:=0]
newData[date>=2016, reallocation1:=.25*exp_M1_1]
newData[date>=2016, reallocation2:=.25*exp_M1_2]
newData[, exp_M1_1:=exp_M1_1-reallocation1]
newData[, exp_M1_2:=exp_M1_2-reallocation2]
newData[, exp_M2_1:=exp_M2_1+reallocation1+reallocation2]
newData$reallocation1 = NULL
newData$reallocation2 = NULL

# recompute cumulatives
rtVars = names(newData)
rtVars = rtVars[grepl('exp', rtVars) & !grepl('cumulative', rtVars)]
for(v in rtVars) newData[, (paste0(v,'_cumulative')):=cumsum(get(v))]

# convert back to re-scaled values
if (!all(names(newData)==names(scaling_factors))) stop('Different order of variables in scaling factors')
newData = newData/scaling_factors

# predict counterfactual using predict_lavaan
# adapted from https://github.com/yrosseel/lavaan/issues/44
preds = data.table(predict_lavaan(semFit, newdata=newData))
preds[, date:=data$date]

# bring back variables that didn't get predictions
preds = merge(preds, newData, by='date', suffixes=c('','.y'))
dropVars = names(preds)[grepl('.y',names(preds))]
preds = preds[, names(scaling_factors), with=FALSE]

head(preds_actual)
head(preds)

# convert actuals and counterfactuals to unscaled levels
data = data*scaling_factors
preds = preds*scaling_factors

cf = merge(data, preds, 'date')
cf = melt(cf, id.vars='date')
cf[, cf:=ifelse(grepl('.y',variable),'Counterfactual Budget', 'Actual Budget')]
cf[, graph_var:=!grepl('exp|other_dah|ghe',variable)]
cf[, variable:=gsub('.x|.y','',variable)]

# show counterfactual budget
# ggplot(cf[grepl('exp_cumulative',variable)], aes(y=value, x=))

# graph comparison
ggplot(cf[graph_var==TRUE], aes(y=value, x=variable, fill=cf)) + 
	geom_bar(stat='identity', position='dodge') + 
	theme_bw() + 
	theme(axis.text.x=element_text(angle=315, hjust=0))
tmp1 = cf[cf=='Counterfactual Budget',.(counterfactual=mean(value)), by=variable]
tmp2 = cf[cf=='Actual Budget',.(actual=mean(value)), by=variable]
merge(tmp1, tmp2, by='variable')
# ----------------------------------------------
