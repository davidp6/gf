# Function that makes a diagram of SEM output
# Arguments: 
# fitObject, a lavaan or blavaan object
# infoTable, a data.table containing 4 columns (rows correspond to model variables in any order): 
# 	variable (exactly as in model), x, y (where it should appear in graph) and label (optional)
# scaling_factors, optional data.table containing one column per model variable, data represents factors used to rescale variables
# edgeLabels, (logical) whether or not to label coefficients
# variances, (logical) whether or not to show variances
# standardized, (logical) whether or not to display standardized coefficients
# labSize1, labSize2, (numeric) large and small text sizes
# boxHeight, boxWidth, (numeric) height and width of boxes
# linewidth, (numeric) edge thickness and arrow size
# midpoint, (numeric [0,1]), user-specified midpoint for edge bending
# curved, (numeric) 0=straight lines, 1=1 bend, 2=2 bends, 3=step-wise (1 and 2 NOT IMPLEMENTED)
# tapered, (logical) whether to taper edges from start to finish NOT IMPLEMENTED
# Returns: a graph
# Rquires: data.table, ggplot2, stringr

# TO DO
# use unstandardized coefficients and multiply by scaling factors for "per unit" interpretability?

# rm(list=ls())
# fitObject = semFit
# nodeTable = fread('C:/local/gf/impact_evaluation/visualizations/vartable.csv')
# labSize1=5
# labSize2=3
# variances = TRUE
# edgeLabels = TRUE
# standardized = FALSE
# boxWidth=4
# boxHeight=1
# linewidth=1
# midpoint=0.4
# curved=3

semGraph = function(fitObject=NULL, nodeTable=NULL, scaling_factors=NA, 
	edgeLabels=TRUE, variances=TRUE, standardized=FALSE, 
	labSize1=5, labSize2=3, boxWidth=4, boxHeight=1, linewidth=3, midpoint=.5, 
	curved=0) {

	# -------------------------------------------------------------------------------
	# Set up node table
	
	# test any variables not in model
	
	# test any variables not in nodeTable
	modelVars = unique(c(fitObject@ParTable$lhs, fitObject@ParTable$rhs))
	modelVars = modelVars[modelVars!='']
	exclVars = modelVars[!modelVars %in% nodeTable$variable]
	
	# check all labels available
	nodeTable[, label:=as.character(label)]
	nodeTable[is.na(label), label:=variable]
	# -------------------------------------------------------------------------------
	
	
	# -------------------------------------------------------------------------------
	# Set up edge table
	
	# extract edges from lavaan table
	# edgeTable = data.table(sapply(fitObject@ParTable,c))
	# edgeTable[, est:=as.numeric(est)]
	# edgeTable[, se:=as.numeric(se)]
	# edgeTable$label = NULL
	if (standardized==TRUE) {
		edgeTable = data.table(standardizedSolution(fitObject))
		setnames(edgeTable, 'est.std', 'est')
	}
	if (standardized==FALSE) { 
		edgeTable = data.table(parTable(fitObject))[, c('lhs','op','rhs','est'), with=FALSE]
	}
	# multiply by scaling factors if we're showing actual coefficients (if possible)
	if (!all(is.na(scaling_factors))) {
		tmp = unique(melt(scaling_factors, value.name='scaling_factor'))
		edgeTable = merge(edgeTable, tmp, by.x='rhs', by.y='variable', all.x=TRUE)
		edgeTable = merge(edgeTable, tmp, by.x='lhs', by.y='variable', all.x=TRUE)
		edgeTable[is.na(scaling_factor.x), scaling_factor.x:=1]
		edgeTable[is.na(scaling_factor.y), scaling_factor.y:=1]
		edgeTable[, est:=est/scaling_factor.x*scaling_factor.y]
	}
	
	# identify start and end locations
	edgeTable = merge(edgeTable, nodeTable, by.x='rhs', by.y='variable')
	setnames(edgeTable, c('x','y','label'), c('xstart','ystart','labelstart'))
	edgeTable = merge(edgeTable, nodeTable, by.x='lhs', by.y='variable')
	setnames(edgeTable, c('x','y','label'), c('xend','yend','labelend'))
	
	# make start and end y-values repel eachother a little
	edgeTable[, grp:=.GRP, by=c('yend','xend')]
	for (g in unique(edgeTable$grp)) {
		N = nrow(edgeTable[grp==g & op!='~~'])
		if (N==1) next
		edgeTable[grp==g & op!='~~', half:=rep(seq(N/2), each=N/2)]
		edgeTable[grp==g & op!='~~', n:=seq(.N), by=half]
		edgeTable[grp==g & op!='~~' & half==1, yend:=yend-n*(boxHeight*.15)]
		edgeTable[grp==g & op!='~~' & half==2, yend:=yend+n*(boxHeight*.15)]
	}
	
	# identify middle of each path for coefficient labels (plus a user-specified midpoint "s")
	edgeTable[, xmid:=(xstart+boxWidth+xend)/2]
	edgeTable[, ymid:=(ystart+yend)/2]
	edgeTable[, xmid_s:=xmid-((0.5-midpoint)*(xend-xstart))]
	edgeTable[, ymid_s:=ymid-((0.5-midpoint)*(yend-ystart))]
	
	# identify the length of each path
	edgeTable[,edge_length:=sqrt(((yend-ystart)^2)+((xend-xstart)^2))]
	
	# add buffers to the end of the edges (assuming all arrows are going left to right)
	edgeTable[, vx:=xend-xstart]
	# edgeTable[, xend:=xend-(labSize2*.05*vx)]
	# edgeTable[op!='~~', xend:=xend-labSize2*.1]
	
	# drop variances if specified
	if (variances==FALSE) { 
		edgeTable = edgeTable[op!='~~']
	}
	
	# always drop variances that are exactly zero assuming they've been manually excluded
	edgeTable = edgeTable[!(op=='~~' & est==0)]
	# -------------------------------------------------------------------------------
	
	
	# -------------------------------------------------------------------------------
	# Graph
	
	# initialize plot
	p = ggplot() 

	
	# add edges
	# straight
	if (curved==0) { 
		p = p + 
			geom_segment(data=edgeTable[op!='~~'], aes(x=xstart+boxWidth, y=ystart, xend=xend, yend=yend, color=est), 
				arrow=arrow(), size=linewidth)
	}
	# stepwise
	if (curved==3) { 
		p = p + 
			geom_segment(data=edgeTable[op!='~~'], aes(x=xstart, y=ystart, xend=xmid_s, yend=ystart, color=est), size=linewidth, alpha=.5) + 
			geom_segment(data=edgeTable[op!='~~'], aes(x=xmid_s, y=ystart, xend=xmid_s, yend=yend, color=est), size=linewidth, alpha=.5) + 
			geom_segment(data=edgeTable[op!='~~'], aes(x=xmid_s, y=yend, xend=xend, yend=yend, color=est), size=linewidth, alpha=.5, arrow=arrow(length=unit(linewidth*.25,'cm')))
	}
	
	# add covariances with curvature based on edge length
	if (variances==TRUE) { 
		for(i in which(edgeTable$op=='~~' & edgeTable$rhs!=edgeTable$lhs)) { 		
			# identify edge length
			el = edgeTable[i]$edge_length
			# set direction of curve
			di = ifelse(edgeTable[i]$xstart<mean(edgeTable$xstart), -1, 1)
			# curved arrows going downward need to bend the other way
			if (edgeTable[i]$yend < edgeTable[i]$ystart) di = -di 
			# add curves to graph (different depending on direction of curve)
			if (di<0) {
				p = p + 
					geom_curve(data=edgeTable[i], 
						aes(x=xstart+boxWidth, y=ystart, xend=xend+boxWidth, yend=yend, color=est), 
						size=labSize2*.25, curvature=di*(1/(0.4*el)), angle=90)
			}
			if (di>=0) { 
				p = p + 
					geom_curve(data=edgeTable[i], 
						aes(x=xstart, y=ystart, xend=xend, yend=yend, color=est), 
						size=labSize2*.25, curvature=di*(1/(0.4*el)), angle=90)			
			}
		}
	}
	
	# add edge labels
	if (edgeLabels) { 
		if (curved==0) { 
			p = p + geom_text(data=edgeTable[edgeTable$op!='~~'], aes(x=xmid, y=ymid+(min(edgeTable$ystart)*.25), 
				label=round(est,2)), size=labSize2*.8, lwd=0)
		}
		if (curved==3) { 
			p = p + geom_text(data=edgeTable[edgeTable$op!='~~'], aes(x=xmid, y=yend, 
				label=round(est,2)), size=labSize2*.8, lwd=0)
		}
	}
	
	# add nodes
	p = p + 
		# geom_point(data=nodeTable, aes(y=y, x=x), size=labSize2*5, shape=22, fill='white') + 
		geom_rect(data=nodeTable, aes(ymin=y-(boxHeight*.5), ymax=y+(boxHeight*.5), xmin=x, xmax=x+boxWidth), 
			fill='white', color='black') + 
		geom_text(data=nodeTable, aes(y=y, x=x+(0.05*boxWidth), label=str_wrap(label,20)), size=labSize2, hjust=0) 
	
	# improve legend
	p = p + 
		scale_color_viridis(direction=-1) 
	
	# add buffer space to axes
	ymax = max(nodeTable$y)+(0.25*sd(nodeTable$y))
	ymin = min(nodeTable$y)-(0.25*sd(nodeTable$y))
	xmax = max(nodeTable$x)+(0.25*sd(nodeTable$x))
	xmin = min(nodeTable$x)-(0.25*sd(nodeTable$x))
	p = p + 
		expand_limits(y=c(ymin, ymax), x=c(xmin, xmax)) 
	
	# labels
	p = p + 
		labs(color='Effect\nSize', caption=paste('Control variables not displayed:', paste(exclVars, collapse =',')))
	
	# clean up plot
	p = p + theme_void() + theme(legend.position=c(0.5, 0), legend.direction='horizontal', plot.margin=unit(c(t=-.5,r=.75,b=.25,l=-1.5), 'cm'))
	
	# -------------------------------------------------------------------------------
	return(p)
}
