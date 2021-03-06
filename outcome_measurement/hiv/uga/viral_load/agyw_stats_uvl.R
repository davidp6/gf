# ----------------------------------------------
# Caitlin O'Brien-Carelli
#
# 4/18/2019
# Rbind the UVL data sets together
# Run dist_facilities_uvl.R to download facility and district names
# ----------------------------------------------

# --------------------
# Set up R
rm(list=ls())
library(data.table)
library(ggplot2)
library(stringr) 
library(plyr)
library(RColorBrewer)
library(gplots)
library(corrplot)
library(boot)
library(stargazer)
# --------------------

# this package is not automatically installed on the cluster
# install.packages("betareg", lib='/ihme/scratch/users/ccarelli/packages/')

# load betareg package
library(betareg, lib.loc='/ihme/scratch/users/ccarelli/packages/')

# ----------------------------------------------
# detect if operating on windows or on the cluster 

j = ifelse(Sys.info()[1]=='Windows', 'J:', '/home/j')
# ------------------------------
# set directories and upload data 

inDir = paste0(j, '/Project/Evaluation/GF/outcome_measurement/uga/vl_dashboard/prepped/')
outDir = paste0(j, '/Project/Evaluation/GF/outcome_measurement/uga/vl_dashboard/age_analyses/')

# upload the data 
dt = readRDS(paste0(inDir, 'uvl_prepped_2014_2018_.rds'))

#--------------------------------------
# merge in regions

# import the regions 
regions = fread(paste0(j, '/Project/Evaluation/GF/mapping/uga/uga_geographies_map.csv'))
regions = regions[ ,.(dist112_name, region10_alt)]
setnames(regions, c('district', 'region'))
regions = regions[!duplicated(regions)]

# merge the regions into the data 
dt = merge(dt, regions, by='district', all.x=T)

#--------------------------------------
# factor categorical variables

# factor age category
dt$age = factor(dt$age, levels = c("0 - 4", "5 - 9", "10 - 14", "15 - 19",
                                   "20 - 24", "25 - 29", "30 - 34", "35 - 39", 
                                   "40 - 44", "45 - 49"))

# reset name to age category to add a continuous age variable
setnames(dt, 'age', 'age_cat')

# add an associated integer
dt[ ,age:=(5*as.numeric(age_cat))]

# add year to use as a variable in the model
dt[ ,year:=year(date)]

# sex, district, facility level
dt[ ,sex:=factor(sex)]
dt[ ,district:=factor(district)]
dt[ ,level:=factor(level)]
dt[ ,region:=factor(region)]

# print levels to check
dt[ ,lapply(.SD, function(x) print(levels(x))), .SDcols=c(5:7, 9)]

#--------------------------
# function to lemon squeeze the data 

smithsonTransform = function(x) { 
  N=length( x[!is.na(x)] )
  prop_lsqueeze = (((x*(N-1))+0.5)/N)
}

#--------------------------

#-------------------------------------------------------------------------
# facility level regressions

# sum to the facility level
vl = dt[  ,.(suppressed=sum(suppressed), valid_results=sum(valid_results)), 
          by=.(facility, sex, age, year, age_cat, level, district, region)]
vl[ , ratio:=(suppressed/valid_results)]

# lemon squeeze the ratio
vl[ ,lemon_vl_ratio:=smithsonTransform(ratio)]

#--------------------------
# visualize the distribution and lemon squeeze the data 

# visualize the distribution of the ratios
ggplot(vl[year==2018], aes(x=ratio)) +
  geom_histogram(color='black', fill='white') +
  theme_bw() +
  theme(text=element_text(size=24)) +
  labs(title = "Viral suppression ratio (facility level)", y='Count of ratios', x='Ratio')

# graph the two distributions
vl_new = melt(vl[year==2018], id.vars=c('facility', 'level', 'district', 'region', 'sex', 'age', 'age_cat', 'year'))
vl_new = vl_new[variable=='ratio' | variable=='lemon_vl_ratio']
vl_new[variable=='ratio', variable:='Viral suppression ratio']
vl_new[variable=='lemon_vl_ratio', variable:='Lemon-squeezed viral suppression ratio']

# visualize the distribution of ratios
ggplot(vl_new[year==2018], aes(x=value)) +
  geom_histogram(color='black', fill='white') +
  theme_bw() +
  facet_wrap(~variable, scales='free') +
  theme(text=element_text(size=18)) +
  labs(title = "Viral suppression ratio (facility level)", y='Count of ratios', x='Ratio')

# check for heteroscedastisticity in the age distribution
ggplot(vl[year==2018], aes(x=age_cat, y=ratio)) +
  geom_jitter() +
  theme_bw() +
  theme(text=element_text(size=22)) +
  labs(title = "Viral suppression ratio within a health facility", y='Ratio', x='Age Category')

# check for heteroscedastisticity in the facility levels
ggplot(vl[year==2018], aes(x=level, y=ratio)) +
  geom_jitter() +
  theme_bw() +
  theme(text=element_text(size=22), axis.text.x=element_text(size=12, angle=90)) +
  labs(title = "Viral suppression ratio within a health facility", y='Ratio', x='Health facility level')

# check for heteroscedastisticity in the age distribution by sex
ggplot(vl[year==2018], aes(x=age_cat, y=ratio, color=sex)) +
  geom_jitter() +
  theme_bw() +
  facet_wrap(~sex) +
  theme(text=element_text(size=22), axis.text.x=element_text(size=12, angle=90)) +
  labs(title = "Viral suppression ratio within a health facility", y='Ratio', x='Age category') 

# check the trend in ratios by year
ggplot(vl, aes(x=year, y=ratio, color=sex)) +
  geom_jitter() +
  theme_bw() +
  facet_wrap(~sex) +
  theme(text=element_text(size=22), axis.text.x=element_text(size=12, angle=90)) +
  labs(title = "Viral suppression ratio within a health facility", y='Ratio', x='Age category') 

#----------------------------------
# run the main model 
beta = betareg(lemon_vl_ratio~sex+age+year+level+region, vl)

# summarize the model 
summary(beta)

# plot the predicted values and standard errords
vl[, predictions:=predict(beta, newdata=vl)]
vl[ , predictions:=(100*predictions)]
vl[ ,c('lower','upper'):=predict(beta, interval='confidence')] # this gives incorrect values

# test graph - predicted sex ratios by region and sex 
ggplot(vl[(age_cat=='15 - 19' | age_cat=='20 - 24') & level=='HC III' & year==2018], aes(x=region, y=predictions, fill=sex)) +
  # geom_errorbar(data = vl[(age_cat=='15 - 19' | age_cat=='20 - 24') & level=='HC III'], (aes(x=region, ymin=lower, ymax=upper))) +
  facet_wrap(~age_cat) +
  geom_bar(stat="identity", position=position_dodge()) +
  theme_bw() +
  theme() +
  coord_cartesian(ylim=c(50, 100)) +
  labs(y='Viral suppression ratio', x='Region', fill='Sex', title='Predicted viral suppression ratio, 2018, HC IIIs, ages 15 - 24') +
  theme(text = element_text(size=18), axis.text.x=element_text(size=12, angle=90))

# test graph - true ratios
ggplot(vl[(age_cat=='15 - 19' | age_cat=='20 - 24') & level=='HC III' & year==2018], aes(x=region, y=100*ratio, fill=sex)) +
  # geom_errorbar(data = vl[(age_cat=='15 - 19' | age_cat=='20 - 24') & level=='HC III'], (aes(x=region, ymin=lower, ymax=upper))) +
  facet_wrap(~age_cat) +
  geom_bar(stat="identity", position=position_dodge()) +
  theme_bw() +
  theme() +
  coord_cartesian(ylim=c(50, 100)) +
  labs(y='Viral suppression ratio', x='Region', fill='Sex', title='Viral suppression ratio, all years') +
  theme(text = element_text(size=18), axis.text.x=element_text(size=12, angle=90))

ggplot(vl[level=='HC III' & year==2018], aes(x=age_cat, y=predictions, fill=sex)) +
  # geom_errorbar(data = vl[(age_cat=='15 - 19' | age_cat=='20 - 24') & level=='HC III'], (aes(x=region, ymin=lower, ymax=upper))) +
  facet_wrap(~region) +
  geom_bar(stat="identity", position=position_dodge()) +
  theme_bw() +
  theme() +
  labs(y='Viral suppression ratio', x='Region', fill='Sex', title='Viral suppression ratio, all years') +
  theme(text = element_text(size=18), axis.text.x=element_text(size=12, angle=90))

#------------------
# alternate model with years as a categorical (reference = 2014)

# run with dummies by year
beta_yr_alt = betareg(lemon_vl_ratio~sex+age+factor(year)+level+region, vl)

# summarize the model 
summary(beta_yr_alt)

#-------------------------------
# create a map

vl_sub = dt[  ,.(suppressed=sum(suppressed), valid_results=sum(valid_results)), 
              by=.(facility, sex, year, age, age_cat, region)]

vl_sub[ ,ratio:=suppressed/valid_results]
vl_sub[ , lemon:=smithsonTransform(ratio)]

# run with dummies by year
beta_map = betareg(lemon~sex+age+year+region, vl_sub)

# summarize the model 
summary(beta_map)

# subset to the predictions of interest
vl_sub[, predictions:=predict(beta_map, newdata=vl_sub)]
vl_sub[ , predictions:=(100*predictions)]
vl_sub = vl_sub[year==2018 & (age==20 | age==25)]
vl_sub = vl_sub[ ,.(predictions = unique(predictions)), by=.(sex, age, age_cat, region)]



#-------------------------------------------------------------------------
# run with an interaction term 

beta_interact = betareg(lemon~region*age*sex, vl)
summary(beta_interact)

predict(beta_test)

#-------------------------

#------------------------------------------------------------------
# run with district instead of region as a covariate
betaFac_dist = betareg(lemon~sex+age_cont+level+district, vl)

# summarize the region model 
summary(betaFac_dist)

#-----------------------------------------------
# district level regression - regressions with direct-level data points
# use facility level to examine at the lowest level

# sum to the district level
dist = dt[  ,.(suppressed=sum(suppressed), valid_results=sum(valid_results))  , by=.(district, region, sex, age)]
dist[ , ratio:=(suppressed/valid_results)]

# visualize the distribution of the ratios
ggplot(dist, aes(x=ratio)) +
  geom_histogram(color='black', fill='white') +
  theme_bw() +
  theme(text=element_text(size=24)) +
  labs(title = "Viral suppression ratio (district level)", y='Count of ratios', x='Ratio')

# number of observationa
dist[ ,lemon:=smithsonTransform(ratio)]

# graph the two distributions
new = melt(dist, id.vars=c('district', 'sex', 'age'))
new = new[variable=='ratio' | variable=='lemon']
new[variable=='ratio', variable:='Viral suppression ratio']
new[variable=='lemon', variable:='Lemon-squeezed viral suppression ratio']

# visualize the distribution of ratios
ggplot(new, aes(x=value)) +
  geom_histogram(color='black', fill='white') +
  theme_bw() +
  facet_wrap(~variable, scales='free')+
  theme(text=element_text(size=18)) +
  labs(title = "Viral suppression ratio (district level)", y='Count of ratios', x='Ratio',
       subtitle="Lemon squeeze formula: (ratio(N-1)+0.5)/N")

# models
betaDist = betareg(lemon~sex+age+district, dist)

# print the output
summary(betaDist)

#--------------------------------------------------
# regional regression to test
# use facility level to examine at the lowest level

# sum to the district level
reg = dt[  ,.(suppressed=sum(suppressed), valid_results=sum(valid_results))  , by=.(region, sex)]
reg[ , ratio:=(suppressed/valid_results)]

# number of observationa
reg[ ,lemon:=smithsonTransform(ratio)]

# run the regional regression on sex
reg_sex = betareg(lemon~sex, data = reg)


reg[,predictions:=predict(reg_sex, newdata=reg)]
reg[,c('lower', 'upper'):=predict(reg_sex, newdata=reg, interval='confidence')]

# samples received by sex, age, year - all years
ggplot(reg, aes(x=region, y=predictions, fill=sex)) +
  geom_bar(stat="identity", position=position_dodge()) +
  theme_bw() +
  labs(y='Viral suppression ratio', x='Region', fill='Sex') 


#--------------------------------------------------
# original smithson transformation function 

smithsonTransform_og = function(x) { 
  N=length( x[!is.na(x)] )
  prop_lsqueeze = logit(((x*(N-1))+0.5)/N)
}

smithsonTransformNoLogit = function(x) { 
  N=length( x[!is.na(x)] )
  prop_lsqueeze = (((x*(N-1))+0.5)/N)
}

x = runif(100, 0, 1)
x = c(x,c(0,0,1,1))

hist(x)
hist(logit(x))
hist(smithsonTransform(x))
hist(smithsonTransformNoLogit(x))

#-------------------------------------------------------------------------






