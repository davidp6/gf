# Organization of this folder

/models/
Folder to contain different versions of the "model object", an R script that stores a single character string which represents the equations of the model. Variables in the equations must match variables in the output data from 4a or 4b, priors must be specified according to JAGS syntax, 4c, 4d, 5a and 5b must refer to a script in this folder (see below).

/data_quality_corrections/
Folder to contain additional adjustments that happen before the main sequence of scripts

/misc/
Folder to contain random stuff that is handy but not terribly importantly

/visualizations/
Folder to contain additional code for making graphs, as well as the "nodetables", which contain the list of variables in a model, the coordinates where they should be displayed in the final path diagram (see 6a below), and nice (short) labels for visualizations. Should be one for the first half and one for the second half of the results chain.

1_master_file.r
Runs all other scripts in order if you want

2a_prep_resource_tracking.r
2b_prep_activities_outputs.R
2c_prep_outcomes_impact.r
Preps different parts of the results chain (very specific data munging stuff)

3_merge_data.R
Merges together the output from step 2

3b_correct_to_models.R
Performs "model standardization", a basic adjustment to make outcomes and impact indicators mimic the trend of model estimates while still preserving their "natural" variance.

4a_set_up_for_first_half_analysis.r
Final prep work before running a model on the first half of the results chain. Most importantly this performs transformations such as lags, leads, log, logit, cumulative sums and variance-standardization (dividing by a constant so that every variable has the same order of magnitude)

4b_set_up_for_second_half_analysis.r
Final prep work before running a model on the first half of the results chain. Most importantly this performs transformations such as lags, leads, log, logit, cumulative sums and variance-standardization (dividing by a constant so that every variable has the same order of magnitude)

4c_explore_first_half_data.r
Code that makes some basic descriptive graphs using a first-half model object and output from 4a. Requires user to input the name of a model object and ensure that the nodetable contains the same variable names as the model.

4d_explore_second_half_data.r
Code that makes some basic descriptive graphs using a second-half model object and output from 4b. Requires user to input the name of a model object and ensure that the nodetable contains the same variable names as the model.

5a_run_first_half_analysis.r
Code that runs the structural equation model on the first half of the results chain. This should be run on IHME's cluster for speed because it runs every admin-2 (health zone, municipality etc) in parallel. Requires user to input the name of a model object and ensure that the nodetable contains the same variable names as the model.

5b_run_second_half_analysis.r
Code that runs the structural equation model on the second half of the results chain. This should be run on IHME's cluster for speed because it runs every admin-2 (health zone, municipality etc) in parallel. Requires user to input the name of a model object and ensure that the nodetable contains the same variable names as the model.

5c_run_single_model.r
Code that runs one iteration of the structural equation model, regardless of whether first half or second half. Requires user to pass a model name and a number indicating which "half" of the results chain is being run. These should be passed as command-line arguments.

6a_display_sem_results.r
Code that makes path diagrams from SEM output

6b_efficiency_effectiveness.r
Code that highlights specific model coefficients for interpretation

6c_impact_analysis.r
Code that makes sunburst graphs to explore explained variance

6d_effect_sizes_by_hz.r
Code that makes a map of specific coefficients by admin-2

Additional notes: Every script sources set_up_r.r to load all the file paths it needs so there are no clashes in file names. They also use the function ./impact_evaluation/_common/archive_function.R to automatically time-stamp their resulting file because this inevitably gets re-run a million times and it's useful to have all the history.
