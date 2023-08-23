
*** nri3 - 3 CUTOFF LIMITS, 4 CATEGORIES ***
********************************************
*********************************************
program nri3
version 10.1

/* START QUIETLY */
quietly {


/* DESCRIBE HOW TO WRITE WHEN YOU WANT TO CALCULATE NRI */
	syntax varlist(min=2), PRvars(varlist min=1) CUT(numlist min=3 max=3 sort)


/* DEFINE THAT THE FIRST VARIABLE IN varlist IS CALLED out AND THIS SHOULD BE THE OUTCOME */
	args out



/* DEFINE TEMPORARY VARIABLES TO BE USED IN THE PROGRAM */
tempvar cut1 cut2 cut3
tempvar pred1 pred2 
tempvar predcat1 predcat2 
	forvalues i=1/32 {
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
local third `3' 
label define `categories' 1 "<`first'%" 2 "`first'-`second'%" 3 "`second' - `third'%" 4 ">=`third'%"
gen `cut1'= `first'/100
gen `cut2'= `second'/100
gen `cut3'= `third'/100

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
recode `predcat1' .=3 if `pred1' >= `cut2' & `pred1' < `cut3' & `pred1'!=.
recode `predcat1' .=4 if `pred1' >= `cut3' & `pred1' !=.
label variable `predcat1' "Established risk factors"
label values `predcat1' `categories'
tab `predcat1'

gen `predcat2'=.
recode `predcat2' .=1 if `pred2' < `cut1' & `pred2'!=.
recode `predcat2' .=2 if `pred2' >= `cut1' & `pred2' <`cut2' & `pred2' !=.
recode `predcat2' .=3 if `pred2' >= `cut2' & `pred2' <`cut3' & `pred2' !=.
recode `predcat2' .=4 if `pred2' >= `cut3' & `pred2' !=.
label variable `predcat2' "Established risk factors + new predictors"
label values `predcat2' `categories'
tab `predcat2'


tab `predcat1' `predcat2' if `out'==1, matcell(`matcase')
matrix list `matcase'
tab `predcat1' `predcat2' if `out'==0, matcell(`matnocase')
matrix list `matnocase'

/* skapa kolumner av matrisen motsv kolumn1 - col32 */
** gen newvar = matcase[1,1]
** COL1-16 noncases
gen `col1' = `matnocase'[1,1]
gen `col2' = `matnocase'[1,2]
gen `col3' = `matnocase'[1,3]
gen `col4' = `matnocase'[1,4]
gen `col5' = `matnocase'[2,1]
gen `col6' = `matnocase'[2,2]
gen `col7' = `matnocase'[2,3]
gen `col8' = `matnocase'[2,4]
gen `col9' = `matnocase'[3,1]
gen `col10' = `matnocase'[3,2]
gen `col11' = `matnocase'[3,3]
gen `col12' = `matnocase'[3,4]
gen `col13' = `matnocase'[4,1]
gen `col14' = `matnocase'[4,2]
gen `col15' = `matnocase'[4,3]
gen `col16' = `matnocase'[4,4]

** COL 17-32 cases
gen `col17' = `matcase'[1,1]
gen `col18' = `matcase'[1,2]
gen `col19' = `matcase'[1,3]
gen `col20' = `matcase'[1,4]
gen `col21' = `matcase'[2,1]
gen `col22' = `matcase'[2,2]
gen `col23' = `matcase'[2,3]
gen `col24' = `matcase'[2,4]
gen `col25' = `matcase'[3,1]
gen `col26' = `matcase'[3,2]
gen `col27' = `matcase'[3,3]
gen `col28' = `matcase'[3,4]
gen `col29' = `matcase'[4,1]
gen `col30' = `matcase'[4,2]
gen `col31' = `matcase'[4,3]
gen `col32' = `matcase'[4,4]

gen `nnonevents' = `col1'+`col2'+`col3'+`col4'+`col5'+`col6'+`col7'+`col8'+`col9'+`col10'+`col11'+`col12'+`col13'+`col14'+`col15'+`col16'
gen `nevents' =  `col17'+`col18'+`col19'+`col20'+`col21'+`col22'+`col23'+`col24'+`col25'+`col26'+`col27'+`col28'+`col29'+`col30'+`col31'+`col32'

gen  `pupnonevents' = (`col2'+`col3'+`col4'+`col7'+`col8'+`col9') / `nnonevents'
gen  `pdownnonevents' = (`col5'+`col9'+`col10'+`col13'+`col14'+`col15') / `nnonevents'
gen  `pupevents' =  (`col18'+`col19'+`col20'+`col23'+`col24'+`col28') / `nevents'
gen  `pdownevents' = (`col21'+`col25'+`col26'+`col29'+`col30'+`col31') / `nevents'

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
table `predcat1' `predcat2', by(`ut') contents(freq) row col


end

