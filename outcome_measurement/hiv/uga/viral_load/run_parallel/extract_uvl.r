# ----------------------------------------------
# David Phillips, Caitlin O'Brien-Carelli
#
# 3/31/2019

# Function that runs VL extraction for a single month-years
# Inputs:
# y - 2-digit year
# m - 2-digit month
# Outputs:
# nothing. saves one file per age/sex/tb status
# ----------------------------------------------
# start a cluster IDE 

# sh /share/singularity-images/rstudio/shells/rstudio_qsub_script.sh -p 1347 -s 10 
# --------------------
# Set up R
y <- commandArgs()[4]
m <- commandArgs()[5]
allAges <- commandArgs()[6]
allTbs <- commandArgs()[7]
bothSexes <- commandArgs()[8]

library(jsonlite)
# --------------------


# ----------------------------------------------
# Files and directories

# output file
dir = '/home/j/Project/Evaluation/GF/outcome_measurement/uga/vl_dashboard/webscrape/age_sex_tb/'

# parameters
ages = c('0,1', '1,2,3,4', '5,6,7,8,9,10', '11, 12, 13, 14, 15', 
		'16, 17, 18, 19, 20', '21, 22, 23, 24, 25', '26, 27, 28, 29, 30', 
		'31, 32, 33, 34, 35', '36, 37, 38, 39', '40,41, 42, 43, 44, 45', 
		'46, 47, 48, 49, 50', '51, 52, 53, 54, 55', '56, 57, 58, 59, 60', 
		'61,62,63,64,65', '66,67,68,69,70', '71,72,73,74,75', '76,77,78,79,80', 
		'81,82,83,84,85', '86,87,88,89,90', '91,92,93,94,95', '96,97,98,99')
tbs = c('y','n','x')
sexes = c('m','f','x')

# whether to aggregate
if (allAges==TRUE) ages = ''
if (allTbs==TRUE) tbs = ''
if (bothSexes==TRUE) sexes = ''

# whether or not to re-download everything (or just new data)
reload_everything = FALSE

# to test the loop
y = '16'
m = '01'
ages = '0,1'
tbs = 'n'
sexes = 'f'
# ----------------------------------------------


# ----------------------------------------------
# Load/prep data

# loop over age groups
for(a in ages) { 
  
  # loop over tb groups - includes "unknown" option
  for(t in tbs) { 
	
	# loop over sexes - includes "unknown" option
	for(s in sexes) { 

		# store rds file location
		outFile = paste0(dir, '/20', y, '/', m, 
		 '/facilities_suppression_', m,'_', '20', y, 
			'_',a,'_', s, '_tb','_', t, '.rds')
			  

		# only download if it doesn't already exist
		check = file.exists(outFile)
		if (check==FALSE | reload_everything==TRUE) {

			# store url
			url = paste0('https://vldash.cphluganda.org/live?age_ids=%5B',
			    a, '%5D&districts=%5B%5D&emtct=%5B%5D&fro_date=20', 
					y, m,'&genders=%5B%22',s,'%22%5D&hubs=%5B%5D&indications=%5B%5D&lines=%5B%5D&regimens=%5B%5D&tb_status=%5B%22', 
					t, '%22%5D&to_date=20',y, m)
			
			
			# load
			print(paste('Loading json from:', url))
			data = fromJSON(url)

			# save raw output
			print(paste('Saving data to:', outFile))
			saveRDS(data, file=outFile)
		}
	}
  }
}
# ----------------------------------------------
