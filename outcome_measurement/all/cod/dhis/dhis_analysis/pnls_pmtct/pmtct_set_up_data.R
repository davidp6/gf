#----------------------------------------
# AUTHOR: Emily Linebarger
# PURPOSE: Set up data for PNLS analysis 
# DATE: Updated May 2019
#-----------------------------------------

#Read in data 
dt = readRDS("J:/Project/Evaluation/GF/outcome_measurement/cod/dhis_data/3_prepped/pnls_final/pnls_pmtct.rds")

# make an easy to use element number (can replace element ID if desired) 
dt = dt[order(element_eng)]
dt[, element_no:=.GRP, by='element_eng']

#Set up names 
setnames(dt, 'facility_level', 'level')

#Pull out year variable
dt[, year:=year(date)]

#---------------------------------------------------------------------
# split kinshasa between funders

# split global fund and pepfar dps
dt[dps=='Haut Katanga' | dps=='Lualaba', funder:='PEPFAR']
dt[!(dps=='Haut Katanga' | dps=='Lualaba' | dps=='Kinshasa'), funder:='The Global Fund']

# for kinshasa, split the city by health zone
gf_zones = c('Barumbu', 'Gombe','Kasa Vubu', 
             'Kintambo', 'Police', 'Selembao', 'Biyela', 'Bumbu', 
             'Kalamu 1', 'Kalamu 2', 'Kisenso', 'Lemba', 'Makala', 
             'Mont Ngafula 2')

# set the funders in kinshasa by health zone
dt[health_zone %in% gf_zones, funder:='The Global Fund']
dt[is.na(funder), funder:='PEPFAR']

#Fix DPS names 
dt[, dps:=standardizeDPSNames(dps)]

#Read in the shapefile
shapefile = shapefile("J:/Project/Evaluation/GF/mapping/cod/gadm36_COD_shp/gadm36_COD_1.shp")
shapefile@data$NAME_1 = standardizeDPSNames(shapefile@data$NAME_1)
shapefile@data$dps = shapefile@data$NAME_1

# use the fortify function to convert from spatialpolygonsdataframe to data.frame
coord = data.table(fortify(shapefile)) 
coord[, id:=as.numeric(id)]
coord_ann = rbind(coord, coord)
coord_ann[, year:=rep(2017:2018, each=nrow(coord))] #What years do you have data for? 

#Pull in ID using shapefile data 
shape_ids = data.table(dps = shapefile@data$dps, id = 0:25)
shape_ids[, dps:=standardizeDPSNames(dps)]
dt = merge(dt, shape_ids, by='dps')

#Make a coordinate map for the months you have available in the data. 
dates_avail = unique(dt[, .(date)][order(date)])
coord_months = data.table()
for (i in dates_avail){
  print(i)
  temp = copy(coord)
  temp[, date:=i]
  coord_months = rbind(coord_months, temp)
}

# Add in a clustered level variable to make scatter plots with later. 
#Just label health post, health center, and hospital, and call everything else 'other'. 
dt$level = factor(dt$level, c('health_center', 'reference_health_center', 'general_reference_hospital', 
                              'hospital_center', 'medical_center', 'clinic', 'hospital', 'secondary_hospital', 
                              'polyclinic', 'health_post', 'dispensary', 'medical_surgical_center'), 
                  c('Health center', 'Reference health center', 'General reference hospital', 
                    'Hospital center', 'Medical center', 'Clinic', 'Hospital', 'Secondary hospital', 
                    'Polyclinic', 'Health post', 'Dispensary', 'Medical surgical center'))
dt[, level2:=level]
dt[!level%in%c('Health post', 'Health center', 'Hospital'), level2:='Other']

# ------------------------------------------------------
# Prep some color palettes
#-------------------------------------------------------

two = c('#91bfdb', '#bd0026')
ratio_colors = brewer.pal(8, 'Spectral')
results_colors = brewer.pal(6, 'Blues')
sup_colors = brewer.pal(6, 'Reds')
ladies = brewer.pal(11, 'RdYlBu')
gents = brewer.pal(9, 'Purples')

graph_colors = c('#bd0026', '#fecc5c', '#74c476','#3182bd', '#8856a7')
tri_sex = c('#bd0026', '#74c476', '#3182bd')
wrap_colors = c('#3182bd', '#fecc5c', '#bd0026', '#74c476', '#8856a7', '#f768a1')
sex_colors = c('#bd0026', '#3182bd', '#74c476', '#8856a7') # colors by sex plus one for facilities
single_red = '#bd0026'

colScale = scale_fill_gradient2(low="red", high="green", midpoint=0)
colScale2 = scale_fill_gradient2(low="green", high="red", midpoint=0)

scale_2018 = scale_fill_gradient2(low = "white", high = "orangered")
scale_2017 = scale_fill_gradient2(low = "white", high = "mediumorchid1")