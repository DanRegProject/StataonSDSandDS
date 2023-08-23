
*** nri1 - 1 CUTOFF LIMIT, 2 CATEGORIES ***
********************************************
*********************************************
program nri1
version 10.1

/* START QUIETLY */
quietly {


/* DESCRIBE HOW TO WRITE WHEN YOU WANT TO CALCULATE NRI */
	syntax varlist(min=2), PRvars(varlist min=1) CUT(numlist min=1 max=1 sort)


/* DEFINE THAT THE FIRST VARIABLE IN varlist IS CALLED out AND THIS SHOULD BE THE OUTCOME */
	args out



/* DEFINE TEMPORARY VARIABLES TO BE USED IN THE PROGRAM */
tempvar cut1 cut2 
tempvar pred1 pred2 
tempvar predcat1 predcat2 
	forvalues i=1/8 {
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
* local second `2'
* local third `3' 
label define `categories' 1 "<`first'%" 2 ">=`first'%"
gen `cut1'= `first'/100
* gen `cut2'= `second'/100
* replace third = `third'/100
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
recode `predcat1' .=2 if `pred1' >= `cut1' & `pred1' !=.
label variable `predcat1' "Established risk factors"
label values `predcat1' `categories'
tab `predcat1'

gen `predcat2'=.
recode `predcat2' .=1 if `pred2' < `cut1' & `pred2'!=.
recode `predcat2' .=2 if `pred2' >= `cut1' & `pred2' !=.
label variable `predcat2' "Established risk factors + new predictors"
label values `predcat2' `categories'
tab `predcat2'


tab `predcat1' `predcat2' if `out'==1, matcell(`matcase')
matrix list `matcase'
tab `predcat1' `predcat2' if `out'==0, matcell(`matnocase')
matrix list `matnocase'

/* skapa kolumner av matrisen motsv kolumn1 - col8 */
** gen newvar = matcase[1,1]
** COL1-4 noncases
gen `col1' = `matnocase'[1,1]
gen `col2' = `matnocase'[1,2]
gen `col3' = `matnocase'[2,1]
gen `col4' = `matnocase'[2,2]

** COL 5-8 cases
gen `col5' = `matcase'[1,1]
gen `col6' = `matcase'[1,2]
gen `col7' = `matcase'[2,1]
gen `col8' = `matcase'[2,2]


gen `nnonevents' = `col1' + `col2' + `col3' + `col4' 
gen `nevents' =  `col5' + `col6' + `col7' + `col8' 
gen  `pupnonevents' = (`col2') / `nnonevents'
gen  `pdownnonevents' = (`col3') / `nnonevents'
gen  `pupevents' =  (`col6') / `nevents'
gen  `pdownevents' = (`col7') / `nevents'

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

