# -----------------------------------
# David Phillips
# 
# 10/2/2018
# Quick graphs of stockouts from DHIS
# -----------------------------------


# ------------------
# Set up R
rm(list=ls())
library(data.table)
require(Hmisc)
library(ggplot2)
library(scales)
library(RColorBrewer)
# ------------------


# ------------------------------------------------------------------------
# Files and directories

# switch for the cluster
j = ifelse(Sys.info()[1]=='Windows','J:','/home/j')

# data directory
dir = paste0(j, '/Project/Evaluation/GF/outcome_measurement/cod/dhis/')

# codebook file
codebookFile = paste0(dir, 'catalogues/data_elements_cod.csv')

# input file where the given variable can be found
inFile = paste0(dir, 'prepped/sigl_drc_01_2015_07_2018_prepped.rds')

# output file
outFile = paste0(dir, '../visualizations/snis_stockouts.pdf')
outFile2 = paste0(dir, '../visualizations/snis_graphs_for_report_11_19_18.pdf')
outFile3 = paste0(dir, '../visualizations/snis_graphs_for_report_with_natl_trends.pdf')
# ------------------------------------------------------------------------


# --------------------------------------------------
# Load/prep data

# load codebook
codebook = fread(codebookFile)

# identify stockout variables
stockoutCodebook = codebook[grepl('stock', element) & 
					grepl('out', element) & type!='']
variables = stockoutCodebook[order(-type, -drug, element)]$element

# load LMIS data
data = readRDS(inFile)

# subset to the specified variable(s) post 2016
data = data[element_eng %in% variables & year>=2017]

# subset columns
vars = c('org_unit_id','org_unit','dps','mtk','health_zone','date','element_eng','value')
data = data[, vars, with=FALSE]

# confirm unique identifiers
if (nrow(data)!=nrow(unique(data[,c('org_unit_id','date','element_eng'),with=F]))) { 
	stop('org_unit_id, date and element_eng do not uniquely identify rows!')
}
# --------------------------------------------------


# --------------------------------------------------
# exclude facilities that seemingly never have had any drugs 
data[, fullSO:=0]
data[month(date)==2 & value==28, fullSO:=1]
data[month(date) %in% c(4, 6, 9, 11) & value==30, fullSO:=1]
data[month(date) %in% c(1, 3, 5, 7, 8, 10, 12) & value==31, fullSO:=1]
data[value==0, fullSO:=1] # a few zeroes is ok because that's probably just a data quality issue...
data[, is_zero:= value==0]
data[, pct_zero:=mean(is_zero), by=c('element_eng','org_unit_id')]
data[, min:=min(fullSO), by=c('element_eng','org_unit_id')]
data[, never_stock:=(pct_zero<.34 & min==1)]
neverStock = unique(data[, c('org_unit_id','element_eng','never_stock'), with=FALSE])
neverStock = neverStock[, .(pct=mean(never_stock)), by=element_eng]
data = data[never_stock==FALSE] # drop facility-variables that never didn't have a stockout, including some that had a few zeroes mixed in there ("a few"=33%)
# --------------------------------------------------


# --------------------------------------------------
# Identify different explanations for invalid numbers
# 1. Forgot how many days there are in the month
# 2. Cumulative reporting value - lag(value) <= 32 (32 because they may have committed #1 also)
# 3. Cumulative reporting but hard to tell because previous N values are missing, but value - (31*N) <= 31
# 4. Clear typo (value > 31 * N months by a lot)
# 5. Unexplained (value - lag(value) > 31, but not 1, 2 or 4)
# 6. (NOT ADDED) Reported available minus consumed instead of stockout days

# rectangularize
frame = data.table(expand.grid(org_unit_id=unique(data$org_unit_id), 
					date=unique(data$date), 
					element_eng=unique(data$element_eng)))I
data = merge(data, frame, by=c('org_unit_id','date','element_eng'), all=TRUE)

# ensure order for lagging
data = data[order(org_unit_id, element_eng, date)]

# identify type 1
data[, oob_type:=as.character(NA)]
data[, days_this_month:=monthDays(date)]
data[value>days_this_month & value %in% c(29,30,31), oob_type:='1']

# identify type 2
data[, lag:=shift(value), by=c('org_unit_id','element_eng')]
data[, diff:=value-lag]
data[value>days_this_month & diff<=32 & diff>=0 & is.na(oob_type), oob_type:='2']

# identify type 3
data[, consecutive_nas:=sequence(rle(is.na(data$value))$lengths)]
data[!is.na(value), consecutive_nas:=NA]
data[!is.na(shift(consecutive_nas)) & value>days_this_month & 
	(value/(31*shift(consecutive_nas))<31) & is.na(oob_type), oob_type:='3']

# identify type 4
data[value>31*12*4 & is.na(oob_type), oob_type:='4']

# identify type 5
data[value>days_this_month & is.na(oob_type), oob_type:='5']
# --------------------------------------------------


# --------------------------------------------------
# Do something about each type

# save original value
data[, orig_value:=value]

# assume 1 is just an error, replace with length of month
data[oob_type=='1',  value:=days_this_month]

# assume 2 is cumulative: subtract previous month
data[oob_type=='2', value:=diff]
data[oob_type=='2' & value>days_this_month, value:=days_this_month]

# assume 3 is cumulative: subtract out what the previous month must have been to make it cumulative
data[oob_type=='3', value:=orig_value%%30] 

# assume type 4 is unknown: replace with NA
data[oob_type=='4',  value:=NA]

# assume type 5 is unknown: replace with NA
data[oob_type=='5',  value:=NA]

# count how many were removed
pctOutliers = data[, .(pct=mean(oob_type %in% c('4','5'))), by=element_eng]
# --------------------------------------------------


# -------------------------------------------------------------------------
# Aggregate

# aggregate all other DPS's
agg = copy(data)
agg[mtk=='No', dps:='All Other Provinces'] 
agg = agg[!is.na(dps)]

# compute monthly average value by dps
byVars = c('dps','date','element_eng')
agg = agg[, .(value=mean(value, na.rm=TRUE)), by=byVars]

# compute percentage of HZ's and percentage of facilities with any stockout per DPS
data[, hf_any_stockout:= value>0]
data[, hz_max:=max(value,na.rm=TRUE), by=c('element_eng','health_zone','date')]
data[, hz_any_stockout:= hz_max>0]
pct = copy(data)
pct[!dps %in% c('Equateur','Kwilu','Kinshasa','Maniema','Tshopo'), dps:='All Other Provinces']
pct = pct[, .(hf_pct=mean(hf_any_stockout, na.rm=TRUE), 
			hz_pct=mean(hz_any_stockout, na.rm=TRUE)), by=byVars]
			
# melt the two percentages long
pct = melt(pct, id.vars=byVars)
pct[variable=='hf_pct', variable:='facilities']
pct[variable=='hz_pct', variable:='health zones']
# -------------------------------------------------------------------------


# ---------------------------------------------
# Set up to graph
c = brewer.pal(12, 'Paired')
colors = c('All Other Provinces'=c[1], 'Kinshasa'=c[4], 
		'Maniema'=c[8], 'Tshopo'=c[10], 'Equateur'=c[6], 
		'Kwilu'=c[2])
# ---------------------------------------------


# ------------------------------------------------------
# Graph mean days by element and dps
meanPlots = list()
for(i in seq(length(variables))) { 
	pctO = round(pctOutliers[element_eng==variables[i]]$pct*100,2)
	pctN = round(neverStock[element_eng==variables[i]]$pct*100,1)
	meanPlots[[i]] = ggplot(agg[element_eng==variables[i]], aes(y=value, x=date, color=dps)) +
		geom_line() + 
		geom_point() + 
		scale_x_date(labels=date_format("%b-%Y"), 
			date_breaks ="3 month") + 
			scale_color_manual(values=colors) + 
		labs(title=variables[i], y='Average days of stock-out per facility', 
			x='', color='', 
			caption=paste0('Reported stockouts greater than 31 days with no obvious explanation excluded (', pctO, '% of facility-months)\n
			Facilities which seem to never stock this commodity (', pctN, '% of facilities) also excluded')) + 
		theme_bw()
}
# ------------------------------------------------------


# ------------------------------------------------------
# Graph percent of HZ's and HF's with any stockout by element and dps
pctPlots = list()
i=1
for(j in seq(length(variables))) { 
	for(v in c('facilities','health zones')) {
		pctO = round(pctOutliers[element_eng==variables[j]]$pct*100,1)
		pctN = round(neverStock[element_eng==variables[j]]$pct*100,1)
		pctPlots[[i]] = ggplot(pct[element_eng==variables[j] & variable==v], 
				aes(y=value*100, x=date, color=dps)) +
			geom_line(size=1) + 
			geom_point(size=2) + 
			scale_x_date(labels=date_format("%b-%Y"), 
				date_breaks ="3 month") + 
				scale_color_manual(values=colors) + 
			labs(title=variables[j], y=paste('Percentage of', v, 'with any stockouts'), 
				x='', color='', 
				caption=paste0('Reported stockouts greater than 31 days with no obvious explanation excluded (', pctO, '% of facility-months)\n
				Facilities which seem to never stock this commodity (', pctN, '% of facilities) also excluded')) + 
			theme_bw()
		i=i+1
	}
}
# ------------------------------------------------------


# --------------------------------------------------
# Save
pdf(outFile, height=5.5, width=9)
for(i in seq(length(meanPlots))) print(meanPlots[[i]])
for(i in seq(length(pctPlots))) print(pctPlots[[i]])
dev.off()
# --------------------------------------------------




# --------------------------------------------------
# --------------------------------------------------
# MAKE A VERSION OF THE GRAPH FOR THE REPORT - Audrey 11/16
# Aggregate

# aggregate all other DPS's
agg = copy(data)
agg[dps!= "Maniema", dps:='All Other Provinces'] 
agg = agg[!is.na(dps)]

# compute monthly average value by dps
byVars = c('dps','date','element_eng')
agg = agg[, .(value=mean(value, na.rm=TRUE)), by=byVars]

c = brewer.pal(12, 'Paired')
colors = c('All Other Provinces'=c[1], 'Kinshasa'=c[4], 
           'Maniema'=c[8], 'Bas Uele'=c[10], 'Equateur'=c[6], 
           'Kwilu'=c[2])

i=8

pctO = round(pctOutliers[element_eng==variables[i]]$pct*100,2)
pctN = round(neverStock[element_eng==variables[i]]$pct*100,1)

g <- ggplot(agg[element_eng==variables[i] & date >= "2017-10-01"], aes(y=value, x=date, color=dps)) +
  geom_line() + 
  geom_point() + 
  scale_x_date(labels=date_format("%b-%Y"), 
               date_breaks ="3 month") + 
  scale_color_manual(values=colors) + 
  labs(title= paste0(variables[i]), y='Average days of stock-out per facility', 
       x='', color='', 
       caption=paste0('Reported stockouts greater than 31 days with no obvious explanation excluded (', pctO, '% of facility-months)\n
			Facilities which seem to never stock this commodity (', pctN, '% of facilities) also excluded')) + 
  theme_bw()
g

# REMAKE Constant's figure with diff provinces
# need to load the data in again
# load LMIS data
data2 = readRDS(inFile)

# set variables to use
variables =  data2[ grep("2-11 months", element_eng), unique(element_eng)]
variables =  variables[ !grepl("out of stock", variables) ]

# subset to the specified variable(s) post 2016
data2 = data2[element_eng %in% variables & year>=2017]

# subset columns
vars = c('org_unit_id','org_unit','dps','mtk','health_zone','date','element_eng','value')
data2 = data2[, vars, with=FALSE]

# confirm unique identifiers
if (nrow(data2)!=nrow(unique(data2[,c('org_unit_id','date','element_eng'),with=F]))) { 
  stop('org_unit_id, date and element_eng do not uniquely identify rows!')
}

# aggregate
agg2 = copy(data2)
agg2[dps!= "Maniema", dps:='All Other Provinces'] 
agg2 = agg2[!is.na(dps)]

# compute sum value by dps
byVars = c('dps','date','element_eng')
agg2 = agg2[, .(value=sum(value, na.rm=TRUE)), by=byVars]

# rename element eng vars
agg2[ grepl("amount consumed", element_eng), element_eng := "Quantity consumed"]
agg2[ grepl("quantity lost", element_eng), element_eng := "Quantity lost"]
agg2[ grepl("stock available", element_eng), element_eng := "Available stock"]

agg2 <- agg2[element_eng != "Quantity lost"]

c = brewer.pal(12, 'Paired')
colors2 = c('Quantity consumed'=c[6], 
           'Available stock'=c[2])

change_labels <- function(label){
  label = paste0(label/1000, "k")
}

g2 <- ggplot(agg2[date >= "2017-10-01"], aes(y=value, x=date, color=element_eng)) +
  geom_line() + 
  geom_point() + 
  scale_x_date(labels=date_format("%b-%Y"), 
               date_breaks ="3 month") + 
  facet_wrap(~dps, scales = "free_y") + 
  scale_color_manual(values=colors2) + 
  labs(title= "Artesunate-amodiaquine C1 12.1 (2-11 months) + 25mg tablet 67,5mg - stock over time", y='Quantity in doses', x='', color='') + 
  theme_bw() + scale_y_continuous(labels = change_labels)
g2

pdf(outFile2, height=5.5, width=9)
print(g)
print(g2)
dev.off()
# --------------------------------------------------

# --------------------------------------------------
# make graphs with national trends rather than "all other provinces"

# first figure
# aggregate maniema and national level separately
maniema = copy(data)
# subset to just maniema 
maniema = maniema[dps== "Maniema", ] 
maniema = maniema[!is.na(dps)]

natl = copy(data)
natl= natl[, dps:='National average'] 
natl = natl[!is.na(dps)]

# compute sum value by dps for both dts then rbind them together
byVars = c('dps','date','element_eng')
natl = natl[, .(value=mean(value, na.rm=TRUE)), by=byVars]
maniema = maniema[, .(value=mean(value, na.rm=TRUE)), by=byVars]
dt <- rbindlist(list(maniema, natl), use.names=TRUE, fill = FALSE)

c = brewer.pal(12, 'Paired')
colors = c('National average'=c[1], 'Kinshasa'=c[4], 
           'Maniema'=c[8], 'Bas Uele'=c[10], 'Equateur'=c[6], 
           'Kwilu'=c[2])

i=8

pctO = round(pctOutliers[element_eng==variables[i]]$pct*100,2)
pctN = round(neverStock[element_eng==variables[i]]$pct*100,1)

g3 <- ggplot(dt[element_eng==variables[i] & date >= "2017-10-01"], aes(y=value, x=date, color=dps)) +
  geom_line() + 
  geom_point() + 
  scale_x_date(labels=date_format("%b-%Y"), 
               date_breaks ="3 month") + 
  scale_color_manual(values=colors) + 
  labs(title= paste0(variables[i]), y='Average days of stock-out per facility', 
       x='', color='', 
       caption=paste0('Reported stockouts greater than 31 days with no obvious explanation excluded (', pctO, '% of facility-months)\n
                      Facilities which seem to never stock this commodity (', pctN, '% of facilities) also excluded')) + 
  theme_bw()
g3

# second figure
# aggregate maniema and national level separately
maniema = copy(data2)
# subset to just maniema 
maniema = maniema[dps== "Maniema", ] 
maniema = maniema[!is.na(dps)]

natl = copy(data2)
natl= natl[, dps:='National total'] 
natl = natl[!is.na(dps)]

# compute sum value by dps for both dts then rbind them together
byVars = c('dps','date','element_eng')
natl = natl[, .(value=sum(value, na.rm=TRUE)), by=byVars]
maniema = maniema[, .(value=sum(value, na.rm=TRUE)), by=byVars]
dt <- rbindlist(list(maniema, natl), use.names=TRUE, fill = FALSE)

# rename element eng vars
dt[ grepl("amount consumed", element_eng), element_eng := "Quantity consumed"]
dt[ grepl("quantity lost", element_eng), element_eng := "Quantity lost"]
dt[ grepl("stock available", element_eng), element_eng := "Available stock"]

dt <- dt[element_eng != "Quantity lost"]

c = brewer.pal(12, 'Paired')
colors2 = c('Quantity consumed'=c[6], 
            'Available stock'=c[2])

g4 <- ggplot(dt[date >= "2017-10-01"], aes(y=value, x=date, color=element_eng)) +
  geom_line() + 
  geom_point() + 
  scale_x_date(labels=date_format("%b-%Y"), 
               date_breaks ="3 month") + 
  facet_wrap(~dps, scales = "free_y") + 
  scale_color_manual(values=colors2) + 
  labs(title= "Artesunate-amodiaquine C1 12.1 (2-11 months) + 25mg tablet 67,5mg - stock over time", y='Quantity in doses', x='', color='') + 
  theme_bw() + scale_y_continuous(labels = change_labels)
g4

pdf(outFile3, height=5.5, width=9)
print(g3)
print(g4)
dev.off()