****************************************************
* Journal: BMJ
* Date Submitted: 10th September 2025
* Purpose: Analysis of the study "Gestational weight gain and risk of adverse maternal and neonatal outcomes:  a systematic review and meta-analysis of observational data from 1.6 million women"
************************************************************************************************************************************************************
* This file provides the Stata code used for the analysis of  dataset used in the paper: 
*Gestational weight gain and risk of adverse maternal and neonatal outcomes:  a systematic review and meta-analysis of observational data from 1.6 million women
************************************************************************************************************************************************************
/* This dataset includes the following variables 
Study=Study name
Total_i= Total number of participants in the intervention group, from which the number of events (events_i) and non-events are derived.
Events_i=Number of events of inadequate weight gain
Total_w=Total number of participants in the control group, from which the number of events (events_i) and non-events are derived.
Events_w=Number of events of adequate weight gain
OR=Odds ratio
L_95=lower 95% CI
U_95=Upper 95% CI
BMI=BMI category (UW<18.5; NW 18.5-24.9; OW 25-29.9; OB ≥ 30 )
Outcome=C-section; LBW; LGA; SGA etc.
Rob=high/low
*/
*********************************************************************************
*********************************************************************************
*WHO RESULTS-WEIGHT GAIN ABOVE THE NORMAL WEIGHT GAIN
*********************************************************************************
*********************************************************************************
clear
*Define project directory (set by user)
* NOTE: Replace "PATH/TO/PROJECT" with your local folder
global projdir "PATH/TO/PROJECT"

*Import dataset
import excel "$projdir/data/raw_data_who_wtgainabove.xlsx"", sheet("sheet1") firstrow

*Transforming the given odds ratio in studies to its log scale
gen log_or= log(or) // or needs to be transformed into log scale. 
gen log_upper= log(u_95)
gen log_lower= log(l_95)
generate se = (u_95-l_95) / (2 * 1.96)
generate se_logor =  ( log_upper-log_lower) / (2 * 1.96)

*Generating a, b, c, d  to calculate odds ratio manually. 
gen a= events_i
label var a "events in intervention group"
gen b= total_i-events_i if total_i!=. | events_i!=.
lab var b "no events in intervention group"
gen c= events_w
lab var c "events in control group"
gen d= total_w-events_w if total_w!=. | events_w!=.
lab var d "no events in control group"

/*replacing negative values by missing and adding 0.5 for 0 events.*/
foreach x of varlist a b c d {
	replace `x'=. if `x'<0
} 

*Manually calculating the odds using number of events reported in studies 
gen oddsratio=(a*d)/(b*c)
gen logoddsratio= ln((a*d)/(b*c)) // manual calculation. 
gen se_logor_manual=sqrt((1/a) + (1/b) + (1/c) + (1/d)) // se_log or. 

*Raw odds ratios are preferable in evidence synthesis because different studies adjust for different sets of confounders, making adjusted estimates non-comparable, whereas raw odds ratios provide a consistent, directly comparable measure across studies.
*Combing two odds ratio and se. Adjusted or study-reported odds ratios were used when event data were incomplete or raw odds ratios could not be calculated.
replace logoddsratio=log_or if  logoddsratio==. // replacing adjusted or study reported odds ratio by raw odds ratio is better. 
replace  se_logor_manual=se_logor if se_logor_manual==.


*Pooling the effect size based on invidual outcomes.

meta set logoddsratio se_logor_manual, studylabel(study) eslabel(Odds ratio) // metaset.
meta forestplot, random(reml) se(khartung) transform(`"Odds ratio"': exp)

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

*Generate x_below and y_within-to label the events numbers in the forest plot
gen x_above= string( events_i ) + "/" + string( total_i  )
gen y_within= string( events_w) + "/" + string(total_w)
replace x_above="" if x_above=="./."
replace y_within="" if y_within=="./."


*Meta Forest plot
cd "$projdir/graphs"
levelsof outcome_new, local(levels) 
 foreach l of local levels {
 	local label: label (outcome_new) `l'
	if "`label'" == "hyperbilirubinanemia" {
    local result "Hyperbilirubinemia "
}
else if "`label'" == "RDS" {
    local result "Respiratory Distress"
}
else if "`label'" == "gdm" {
    local result "Gestational Diabetes"
}
else if "`label'" == "nicu" {
    local result "Neonatal Intensive Care Unit"
}
else if "`label'" == "pre-eclampsia" {
    local result "Hypertensive Disorders of Pregnancy"
}
else if "`label'" == "csection" {
    local result "Caesarean Delivery"
}
else if "`label'" == "lbw" {
    local result "Low Birth Weight"
}
else if "`label'" == "lga" {
    local result "Large for Gestational Age (LGA)"
}
else if "`label'" == "macrosomia" {
    local result "Macrosomia"
}
else if "`label'" == "pre-termbirth" {
    local result "Pre-term Birth"
}
else if "`label'" == "sga" {
    local result "Small for Gestational Age (SGA)"
}
else {
    local result "Unknown Condition"
}
			capture noisily  meta forestplot _id x_above y_within _plot _esci _weight  if outcome_new==`l', random(reml) se(khartung) transform(`"Odds ratio"': exp) subgroup(bmi_new) title("`result'")  nogsig noosigtest  xlabel( -2 "2" -1 "-1" 0 "0" 1 "1" 2 "2", labsize(medium))  coltitleopts(size(medium)) columnopts(_esci, title("OR (95% CI)") supertitle (""))  columnopts(_weight, title("% Weight") supertitle ("")) columnopts(x_above, title("No. GWG Above""events/total")) columnopts(y_within, title("No. GWG Within""events/total")) itemopts(size(medium)) overallopts(size(medium)) bodyopts(size(medium)) markeropts(msize(small)) insidemarker(msize(small)) esrefline(lpa(dash) lwidth(thin))  nullrefline note(, size(medium)) note(" ") saving(fp_`label', replace)			
 }

	 
**Meta-summary. 

levelsof outcome_new, local(levels) 
 foreach l of local levels {
 	local label: label (outcome_new) `l'
	display "Outcome is `label'"
capture noisily meta summarize if outcome_new==`l', random(reml) se(khartung) transform(`"Odds ratio"': exp) subgroup(bmi_new)
 }
  
save who_all_above, replace 

********************************************************************************************************************************************************
********************************************************************************************************************************************************
**Funnel plot-.  Publication bias was assessed using Egger's test, where five or more studies were available for a given outcome. 
********************************************************************************************************************************************************
********************************************************************************************************************************************************
//RUN FUNNEL PLOT AND EGGERS TEST
cd "$projdir/graphs"
* Loop over the levels (these are the values of outcome_new)

local levels 2 5 6 7 9 10 11

foreach level of local levels {
    * Get the label for the current level of 'outcome_new'
    local level_label : label outcome_new `level'

    * Display the label first
    display "Results for Outcome (`level_label'):"

    * Run the meta-analysis for each level afterward
    meta bias if outcome_new == `level', egger detail random(reml) se(khartung)
	
	* Save the funnel plot for each outcome with a unique filename
    meta funnel if outcome_new == `level', random(reml ) title("Funnel plot for `level_label'" "with pseudo 95% confidence limits") legend(off) xtitle("log(OR)") ytitle("s.e. of log(OR)") saving(funnelplot_`level_label', replace)		
}



*************************************************************************************************************************************************************
*Sensitivity analysis- Excluding high risk of bias studies 
*************************************************************************************************************************************************************
**Meta-summary excluding high risk of bias(RoB) studies  
levelsof outcome_new, local(levels) 
 foreach l of local levels {
 	local label: label (outcome_new) `l'
	display "Outcome is `label'"
capture noisily meta summarize if outcome_new==`l' & rob!="high", random(reml) se(khartung) transform(`"Odds ratio"': exp) subgroup(bmi_new)
 }

*************************************************************************************************************************************************************
*Sensitivity analysis 
*Conducting a sensitivity analysis using the Sidik-Jonkman method with Hartung-Knapp adjustment, to assess the robustness of the findings, particularly given the potential influence of small sample sizes and between-study heterogeneity.  
*************************************************************************************************************************************************************
*Pooling the effect size based on invidual outcomes using Sidik-Jonkman method.

meta set logoddsratio se_logor_manual, studylabel(study) eslabel(Odds ratio) random(sjonkman)
meta forestplot, random(sjonkman) se(khartung) transform(`"Odds ratio"': exp)

*Meta Forest. 
 
cd "$projdir/graphs/jonkman"
levelsof outcome_new, local(levels) 
 foreach l of local levels {
 	local label: label (outcome_new) `l'
	if "`label'" == "hyperbilirubinanemia" {
    local result "Hyperbilirubinemia "
}
else if "`label'" == "RDS" {
    local result "Respiratory Distress"
}
else if "`label'" == "gdm" {
    local result "Gestational Diabetes"
}
else if "`label'" == "nicu" {
    local result "Neonatal Intensive Care Unit"
}
else if "`label'" == "pre-eclampsia" {
    local result "Hypertensive Disorders of Pregnancy"
}
else if "`label'" == "csection" {
    local result "Caesarean Delivery"
}
else if "`label'" == "lbw" {
    local result "Low Birth Weight"
}
else if "`label'" == "lga" {
    local result "Large for Gestational Age (LGA)"
}
else if "`label'" == "macrosomia" {
    local result "Macrosomia"
}
else if "`label'" == "pre-termbirth" {
    local result "Pre-term Birth"
}
else if "`label'" == "sga" {
    local result "Small for Gestational Age (SGA)"
}
else {
    local result "Unknown Condition"
}
			capture noisily  meta forestplot _id x_above y_within _plot _esci _weight  if outcome_new==`l', random(sjonkman) se(khartung) transform(`"Odds ratio"': exp) subgroup(bmi_new) title("`result'")  nogsig noosigtest  xlabel( -2 "2" -1 "-1" 0 "0" 1 "1" 2 "2", labsize(medium))  coltitleopts(size(medium)) columnopts(_esci, title("OR (95% CI)") supertitle (""))  columnopts(_weight, title("% Weight") supertitle ("")) columnopts(x_above, title("No. GWG Above""events/total")) columnopts(y_within, title("No. GWG Within""events/total")) itemopts(size(medium)) overallopts(size(medium)) bodyopts(size(medium)) markeropts(msize(small)) insidemarker(msize(small)) esrefline(lpa(dash) lwidth(thin))  nullrefline note(, size(medium)) note(" ") saving(fp_`label', replace)			
 }

**Meta-summary (Summarizing the results in the table format)

levelsof outcome_new, local(levels) 
 foreach l of local levels {
 	local label: label (outcome_new) `l'
	display "Outcome is `label'"
capture noisily meta summarize if outcome_new==`l' & rob!="high" , random(reml) se(khartung) transform(`"Odds ratio"': exp) subgroup(bmi_new)
 }
 
save who_all_above, replace 

*************************************************************************************************************************************************************
*Sensitivity analysis- Crude or adjusted 
*This analysis was restricted to studies that reported both crude and adjusted odds ratios for the outcomes of interest (LGA, LBW, macrosomia, and SGA) in relation to weight gain above the recommended range. The dataset therefore included only studies providing both crude and adjusted estimates for these outcomes.
*Study=Study name
*Total_i= Total number of participants in the intervention group, from which the number of events (events_i) and non-events are derived.
*Events_i=Number of events of inadequate weight gain
*Total_w=Total number of participants in the control group, from which the number of events (events_i) and non-events are derived.
*Events_w=Number of events of adequate weight gain
*OR=Odds ratio
*L_95=lower 95% CI
*U_95=Upper 95% CI
*BMI=BMI category (UW<18.5; NW 18.5-24.9; OW 25-29.9; OB ≥ 30 )
*Outcome=LBW; LGA; SGA, Macrosomia.
*crudeoradjusted=Crude/adjusted
*************************************************************************************************************************************************************
clear
import excel "$projdir/data/raw_data_who_wtgainaboveca.xlsx", sheet("sheet1") firstrow

*Transforming the given odds ratio in studies to its log scale
gen log_or= log(or) // or needs to be transformed into log scale. 
gen log_upper= log(u_95)
gen log_lower= log(l_95)
generate se = (u_95-l_95) / (2 * 1.96)
generate se_logor =  ( log_upper-log_lower) / (2 * 1.96)

*Generating a, b, c, d  to calculate odds ratio manually. 
gen a= events_i
label var a "events in intervention group"
gen b= total_i-events_i if total_i!=. | events_i!=.
lab var b "no events in intervention group"
gen c= events_w
lab var c "events in control group"
gen d= total_w-events_w if total_w!=. | events_w!=.
lab var d "no events in control group"

/*replacing negative values by missing and adding 0.5 for 0 events.*/
foreach x of varlist a b c d {
	replace `x'=. if `x'<0
} 

*Manually calculating the odds using number of events reported in studies 
gen oddsratio=(a*d)/(b*c)
gen logoddsratio= ln((a*d)/(b*c)) // manual calculation. 
gen se_logor_manual=sqrt((1/a) + (1/b) + (1/c) + (1/d)) // se_log or. 

*Raw odds ratios are preferable in evidence synthesis because different studies adjust for different sets of confounders, making adjusted estimates non-comparable, whereas raw odds ratios provide a consistent, directly comparable measure across studies.
*Combing two odds ratio and se. Adjusted or study-reported odds ratios were used when event data were incomplete or raw odds ratios could not be calculated.
replace logoddsratio=log_or if  logoddsratio==. // replacing adjusted or study reported odds ratio by raw odds ratio is better. 
replace  se_logor_manual=se_logor if se_logor_manual==.


*Pooling the effect size based on invidual outcomes.

meta set logoddsratio se_logor_manual, studylabel(study) eslabel(Odds ratio) // metaset.
meta forestplot, random(reml) se(khartung) transform(`"Odds ratio"': exp)

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

*Generate x_below and y_within-to label the events numbers in the forest plot
gen x_above= string( events_i ) + "/" + string( total_i  )
gen y_within= string( events_w) + "/" + string(total_w)
replace x_above="" if x_above=="./."
replace y_within="" if y_within=="./."


**Pooling the effect size based on invidual outcomes.
meta set logoddsratio se_logor_manual, studylabel(study) eslabel(Odds ratio) // metaset.

**meta forest. 
cd "$projdir/graphs/crudeoradjusted"
levelsof outcome_new, local(levels) 
 foreach l of local levels {
 	local label: label (outcome_new) `l'
	if "`label'" == "lga" {
    local result "Large for Gestational Age (LGA)"
}
else if "`label'" == "lbw" {
    local result "Low Birth Weight"
}
else if "`label'" == "lga" {
    local result "Large for Gestational Age (LGA)"
}
else if "`label'" == "sga" {
    local result "Small for Gestational Age (SGA)"
}
else {
    local result "Unknown Condition"
}
	*Check if outcome is lbw or macrosomia – plot without pooling as they only have one study
if inlist("`label'", "lbw", "macrosomia") {
			capture noisily  meta forestplot _id x_above y_within _plot _esci _weight  if outcome_new==`l', nooverall  transform(`"Odds ratio"': exp) subgroup(crudeoradjusted) nogsig noosigtest title("`result'") xlabel( -2 "2" -1 "-1" 0 "0" 1 "1" 2 "2", labsize(medium))  coltitleopts(size(medium)) columnopts(_esci, title("OR (95% CI)") supertitle (""))  columnopts(_weight, title("% Weight") supertitle ("")) columnopts(x_above, title("No. GWG Above""events/total")) columnopts(y_within, title("No. GWG Within""events/total")) itemopts(size(medium)) overallopts(size(medium)) bodyopts(size(medium)) markeropts(msize(small)) insidemarker(msize(small)) esrefline(lpa(dash) lwidth(thin))  nullrefline note(, size(medium)) note(" ") saving(fp_`label', replace)			
 }
else {
	* All other outcomes – plot with random-effects pooling
	capture noisily  meta forestplot _id x_above y_within _plot _esci _weight  if outcome_new==`l', random(reml) se(khartung) transform(`"Odds ratio"': exp) subgroup(crudeoradjusted) nogsig noosigtest title("`result'") xlabel( -2 "2" -1 "-1" 0 "0" 1 "1" 2 "2", labsize(medium))  coltitleopts(size(medium)) columnopts(_esci, title("OR (95% CI)") supertitle (""))  columnopts(_weight, title("% Weight") supertitle ("")) columnopts(x_above, title("No. GWG Above""events/total")) columnopts(y_within, title("No. GWG Within""events/total")) itemopts(size(medium)) overallopts(size(medium)) bodyopts(size(medium)) markeropts(msize(small)) insidemarker(msize(small)) esrefline(lpa(dash) lwidth(thin))  nullrefline note(, size(medium)) note(" ") saving(fp_`label', replace)			
 }
}

**Meta-summary, subgrup by crudeoradjusted odds ratio
levelsof outcome_new, local(levels) 
 foreach l of local levels {
 	local label: label (outcome_new) `l'
	display "Outcome is `label'"
capture noisily meta summarize if outcome_new==`l', random(reml) se(khartung) transform(`"Odds ratio"': exp) subgroup(crudeoradjusted)
 }

