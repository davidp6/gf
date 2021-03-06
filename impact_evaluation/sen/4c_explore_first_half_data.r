# ------------------------------------------------
# Francisco Rios, adapted from code byDavid Phillips
# 
# 1/18/2019
# Exploratory visualizations to get a good sense of the impact evaluation data
# The current working directory should be the root of this repo (set manually by user) Use ctrl+SHIFT+H
# ------------------------------------------------

source('./impact_evaluation/sen/set_up_r.r')
library(GGally)

# --------------------------------------------------------------------
# Load/prep data

# load data from step 4a
load(outputFile4a)

# load model object
modelVersion = 'sen_tb_model1'
source(paste0('./impact_evaluation/sen/models/', modelVersion, '.R'))

# load "node table" for convenient labels
nodeTable = fread(nodeTableFile1)

# sample n random health zones to graph
n = 6
hzs = sample(data$region, n)
sample = data[region %in% hzs]
sample_untr = untransformed[region %in% hzs]
# --------------------------------------------------------------------


# ----------------------------------------------
# Set up to graph

# parse model object
parsedModel = lavParseModelString(model)
modelVars = unique(c(parsedModel$lhs, parsedModel$rhs))

# organize completeness variables last, remove date
complVars = modelVars[grepl('completeness',modelVars)]
modelVars = c(modelVars[!modelVars %in% complVars], complVars)
modelVars = modelVars[modelVars!='date']

# organize groups of variables
lhsVars = unique(parsedModel$lhs[parsedModel$op=='~'])
varGroups = lapply(lhsVars, function(v) { 
	c(v, parsedModel$rhs[parsedModel$lhs==v & parsedModel$rhs!='date' & parsedModel$op=='~'])
})

# melt long
long = melt(sample, id.vars=c('region','date'))
long = merge(long, nodeTable, by='variable', all.x=TRUE)
long[is.na(label), label:=variable]
long_untr = melt(sample_untr, id.vars=c('region','date'))
long_untr = merge(long_untr, nodeTable, by='variable', all.x=TRUE)
long_untr[is.na(label), label:=variable]
# ----------------------------------------------


# -------------------------------------------------------------------
# Make histograms

# transformed data as seen by the model
histograms = lapply(modelVars, function(v) {
	l = nodeTable[variable==v]$label
	ggplot(sample, aes_string(x=v)) + 
		geom_histogram() + 
		facet_wrap(~region, scales='free') + 
		labs(title=paste('Histograms of', l), y='Frequency', x=l, 
			subtitle=paste('Random Sample of', n, 'Health Zones'),
			caption='Variables are post-transformation. Transformations may include: 
			cumulative, log, logit and lag.') + 
		theme_bw()
})

# untransformed data
histograms_untr = lapply(modelVars, function(v) {
	l = nodeTable[variable==v]$label
	for(ext in c('_cumulative','lag_','lead_')) {
		if (grepl(ext, v)) v = gsub(ext,'',v) 
	}
	if (!v %in% names(sample_untr)) v = paste0('value_',v) 
	ggplot(sample_untr, aes_string(x=v)) + 
		geom_histogram() + 
		facet_wrap(~region, scales='free') + 
		labs(title=paste('Histograms of', l, '(Without Transformation)'), 
			y='Frequency', x=l, 
			subtitle=paste('Random Sample of', n, 'Regions'), 
			caption='Variables are pre-transformation.') + 
		theme_bw()
})
# -------------------------------------------------------------------


# ---------------------------------------------------------------------------------------
# Make time series graphs
tsPlots = lapply(seq(length(varGroups)), function(g) {
	l = nodeTable[variable==lhsVars[g]]$label
	ggplot(long[variable%in%varGroups[[g]]], aes(y=value, x=date, color=label)) + 
		geom_line() + 
		facet_wrap(~region) + 
		labs(title=paste('Time series of variables related to', l), y='Value', x='Date', 
			subtitle=paste('Random Sample of', n, 'Regions'),
			caption='Variables are post-transformation. Transformations may include: 
			cumulative, log, logit and lag.') + 
		theme_bw()
}) 

# untransformed data
tsPlots = lapply(seq(length(varGroups)), function(g) {
	l = nodeTable[variable==lhsVars[g]]$label
	ggplot(long[variable%in%varGroups[[g]]], aes(y=value, x=date, color=label)) + 
		geom_line() + 
		facet_wrap(~region) + 
		labs(title=paste('Time series of variables related to', l), y='Value', x='Date', 
			subtitle=paste('Random Sample of', n, 'Regions'),
			caption='Variables are pre-transformation.') + 
		theme_bw()
}) 
# ---------------------------------------------------------------------------------------


# ----------------------------------------------
# Make correlation graphs
corPlots = lapply(seq(length(varGroups)), function(g) {
	l = nodeTable[variable==lhsVars[g]]$label
	vars = nodeTable[variable %in% varGroups[[g]]]
	leftout = varGroups[[g]][!varGroups[[g]] %in% vars$variable]
	vars = rbind(vars, data.table(variable=leftout, label=leftout), fill=TRUE)
	ggpairs(sample[, vars$variable, with=FALSE], 
		title=paste('Correlations between variables related to', l),
		columnLabels=vars$label, lower=list(continuous='smooth'))
})
# ----------------------------------------------


# --------------------------------
# Save file
print(paste('Saving:', outputFile4c)) 
pdf(outputFile4c, height=5.5, width=9)
for(i in seq(length(tsPlots))) { 
	print(tsPlots[[i]])
}
for(i in seq(length(corPlots))) { 
	print(corPlots[[i]])
}
for(i in seq(length(histograms))) { 
	print(histograms[[i]])
	print(histograms_untr[[i]])
}
dev.off()

# save a time-stamped version for reproducibility
archive(outputFile4c)
# --------------------------------
