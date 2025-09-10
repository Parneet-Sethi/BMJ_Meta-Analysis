****************************************************
* Journal: BMJ
* Date Submitted: 10th September 2025
* Purpose: Analysis of the study "Gestational weight gain and risk of adverse maternal and neonatal outcomes:  a systematic review and meta-analysis of observational data from 1.6 million women"
****************************************************


************************************************************************************************************************************************************
* This file provides the Stata code used for the analysis of  dataset used in the paper: 
*Gestational weight gain and risk of adverse maternal and neonatal outcomes:  a systematic review and meta-analysis of observational data from 1.6 million women
************************************************************************************************************************************************************

/* This dataset includes the following variables 
Study=Study name
Total_i= Total number of participants in the intervention group
Mean_i=average birth weight in grams of the intervention group 
Se_i=standard_deviation of participants in the intervention group
Total_c= Total number of participants in the control
Mean_c= Average birth weight in grams of the control group 
Se_c=standard_deviation of participants in the intervention group
BMI=BMI category (UW<18.5; NW 18.5-24.9; OW 25-29.9; OB ≥ 30 )
Outcome=C-section; LBW; LGA; SGA etc.
*/

*********************************************************************************
*********************************************************************************
*WHO RESULTS-BIRTH WEIGHT_CONTINOUS OUTCOME
*********************************************************************************
*********************************************************************************

***********************************************************
*SYNTAX FOR INADEQUATE WEIGHT GAIN
***********************************************************
clear

*Define project directory (set by user)
* NOTE: Replace "PATH/TO/PROJECT" with your local folder
global projdir "PATH/TO/PROJECT"

*Import dataset
import excel "$projdir/data/raw_data_who_birthwt.xlsx", sheet("under_who") firstrow


*Encode outcome and the BMI. It converts a string (categorical) variable outcome into a numeric categorical variable outcome_new, assigning integer codes to each unique category while preserving value labels for analysis.
encode outcome, gen(outcome_new)
encode bmi, gen(bmi_r)
gen bmi_new=.
replace bmi_new= 1 if bmi_r==4
replace bmi_new=2 if bmi_r==1
replace bmi_new=3 if bmi_r==3
replace bmi_new=4 if bmi_r==2
lab def bmi 1 "Underweight(<18.5)" 2 "Normal weight (18.5-24.9)" 3 "Overweight (25-29.9)" 4 "Obese (≥30)", replace
lab val bmi_new bmi


******************************************************************************
* Meta-analysis of continuous outcome (birth weight)
* - Effect size = mean difference (inadequate vs adequate weight gain)
* - Random-effects model (REML) with Knapp-Hartung SEs
* - Subgroup analysis by BMI category
* - Forest plot generated and exported as PNG
******************************************************************************

meta esize total_i mean_i se_i total_c mean_c se_c,  studylabel(study) esize(mdiff) random(reml)
* Summarize meta-analysis results by BMI subgroup
meta summ, subgroup(bmi_new) random(reml) se(khartung)
* Create subgroup forest plot (no heterogeneity statistics shown)
meta forestplot, subgroup(bmi_new) nogsig nogwhom noosig noohom random(reml) se(khartung)
 * Export forest plot to PNG file
graph export "$projdir/data/forestplot_below_meandiff.png", as(png) name("Graph") replace


***************************************************************
***********************************************************
*SYNTAX FOR EXCESSIVE WEIGHT GAIN
***********************************************************
***************************************************************
  
clear

*Define project directory (set by user)
* NOTE: Replace "PATH/TO/PROJECT" with your local folder
global projdir "PATH/TO/PROJECT"

*Import dataset
import excel "$projdir/data/raw_data_who_birthwt.xlsx", sheet("over_who") firstrow

*Encode outcome and the BMI. It converts a string (categorical) variable outcome into a numeric categorical variable outcome_new, assigning integer codes to each unique category while preserving value labels for analysis.
encode outcome, gen(outcome_new)
encode bmi, gen(bmi_r)
gen bmi_new=.
replace bmi_new= 1 if bmi_r==4
replace bmi_new=2 if bmi_r==1
replace bmi_new=3 if bmi_r==3
replace bmi_new=4 if bmi_r==2
lab def bmi 1 "Underweight(<18.5)" 2 "Normal weight (18.5-24.9)" 3 "Overweight (25-29.9)" 4 "Obese (≥30)", replace
lab val bmi_new bmi

******************************************************************************
* Meta-analysis of continuous outcome (birth weight)
* - Effect size = mean difference (inadequate vs adequate weight gain)
* - Random-effects model (REML) with Knapp-Hartung SEs
* - Subgroup analysis by BMI category
* - Forest plot generated and exported as PNG
******************************************************************************
meta esize total_i mean_i se_i total_c mean_c se_c, studylabel(study) esize(mdiff) random(reml)
* Summarize meta-analysis results by BMI subgroup
meta summ, subgroup(bmi_new) random(reml) se(khartung)
* Create subgroup forest plot (no heterogeneity statistics shown)
meta forestplot, subgroup(bmi_new) nogsig nogwhom noosig noohom   random(reml) se(khartung)
 * Export forest plot to PNG file
graph export "$projdir/data/forestplot_above_meandiff.png", as(png) name("Graph") replace

