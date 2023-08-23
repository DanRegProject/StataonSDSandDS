
*** nri2 - 2 CUTOFF LIMITS, 3 CATEGORIES ***
********************************************
*********************************************
program nri2
version 10.1

/* START QUIETLY */
quietly {


/* DESCRIBE HOW TO WRITE WHEN YOU WANT TO CALCULATE NRI */
	syntax varlist(min=2), PRvars(varlist min=1) CUT(numlist min=2 max=2 sort)


/* DEFINE THAT THE FIRST VARIABLE IN varlist IS CALLED out AND THIS SHOULD BE THE OUTCOME */
	args out



/* DEFINE TEMPORARY VARIABLES TO BE USED IN THE PROGRAM */
tempvar cut1 cut2 
tempvar pred1 pred2 
tempvar predcat1 predcat2 
	forvalues i=1/18 {
		tempvar col`i'
		}
tempvar idi2 seidi2 zidi2 pidi2
tempvar nnonevents nevents pupnonevents pdownnonevents pupevents pdownevents
tempvar nri senri znri pnri
tempname total matnocase matcase categories
tempvar ut
tempname ute


/* GET CUT LIMITS */
numlist "`cut'"
tokenize `r(numlist)'
local first `1'
local second `2'

label define `categories' 1 "<`first'%" 2 "`first'-`second'%" 3 ">=`second'%"
gen `cut1'= `first'/100
gen `cut2'= `second'/100

gen `ut' = `out'
recode `ut' 0=2
label define `ute' 1 "1" 2 "0"
label values `ut' `ute'
label variable `ut' "`out'"



/* PREDICT MODELS */
logistic `varlist'
predict `pred1'
logistic `varlist' `prvars'
predict `pred2'

/* GENERATE PREDICTION CATEGORIES */
gen `predcat1'=.
recode `predcat1' .=1 if `pred1' < `cut1' & `pred1'!=.
recode `predcat1' .=2 if `pred1' >= `cut1' & `pred1' < `cut2' & `pred1'!=.
recode `predcat1' .=3 if `pred1' >= `cut2' & `pred1' !=.
label variable `predcat1' "Established risk factors"
label values `predcat1' `categories'
tab `predcat1'

gen `predcat2'=.
recode `predcat2' .=1 if `pred2' < `cut1' & `pred2'!=.
recode `predcat2' .=2 if `pred2' >= `cut1' & `pred2' <`cut2' & `pred2' !=.
recode `predcat2' .=3 if `pred2' >= `cut2' & `pred2' !=.
label variable `predcat2' "Established risk factors + new predictors"
label values `predcat2' `categories'
tab `predcat2'


/* GENERATE RECLASSIFICATION MATRIX */
tab `predcat1' `predcat2' if `out'==1, matcell(`matcase')
matrix list `matcase'
tab `predcat1' `predcat2' if `out'==0, matcell(`matnocase')
matrix list `matnocase'

/* CREATE COLUMNS 1-18 BASED ON THE MATRIX */
** gen newvar = matcase[1,1]
** COL1-9 noncases
gen `col1' = `matnocase'[1,1]
gen `col2' = `matnocase'[1,2]
gen `col3' = `matnocase'[1,3]
gen `col4' = `matnocase'[2,1]
gen `col5' = `matnocase'[2,2]
gen `col6' = `matnocase'[2,3]
gen `col7' = `matnocase'[3,1]
gen `col8' = `matnocase'[3,2]
gen `col9' = `matnocase'[3,3]

** COL 10-18 cases
gen `col10' = `matcase'[1,1]
gen `col11' = `matcase'[1,2]
gen `col12' = `matcase'[1,3]
gen `col13' = `matcase'[2,1]
gen `col14' = `matcase'[2,2]
gen `col15' = `matcase'[2,3]
gen `col16' = `matcase'[3,1]
gen `col17' = `matcase'[3,2]
gen `col18' = `matcase'[3,3]


/* CALCULATE RECLASSIFICATION */
gen `nnonevents' = `col1' + `col2' + `col3' + `col4' + `col5' + `col6' + `col7' + `col8' + `col9'
gen `nevents' = `col10' + `col11' + `col12' + `col13' + `col14' + `col15' + `col16' + `col17' + `col18'

gen  `pupnonevents' = (`col2' + `col3' + `col6') / `nnonevents'
gen  `pdownnonevents' = (`col4' + `col7' + `col8') / `nnonevents'
gen  `pupevents' =  (`col11' + `col12' + `col15') / `nevents'
gen  `pdownevents' = (`col13' + `col16' + `col17') / `nevents'

gen `nri' = ( `pupevents' - `pdownevents' ) - ( `pupnonevents' - `pdownnonevents' )
gen `senri' = ( ( `pupevents' + `pdownevents' ) / `nevents' + ( `pupnonevents' + `pdownnonevents' ) / `nnonevents' )^.5
gen `znri' = `nri' / `senri'
gen `pnri'= 2*(1-normal(abs(`znri')))


matrix `total' = `matcase' \ `matnocase'
matlist `total'



/* SUMMARIZE/EXPORT RESULTS */
preserve
keep in 1
tempvar besk
gen str `besk'= " "
label variable `besk' "NRI"
label variable `nri' "Estimate"
label variable `senri' "Std. Err."
label variable `znri' "Z"
label variable `pnri' "P-value"



/* END QUIETLY */
		}

tabdisp `besk', cellvar(`nri' `senri' `znri' `pnri') format(%9.5f) cellwidth(12)
restore
table `predcat1' `predcat2' , by(`ut')contents(freq) row col


end

