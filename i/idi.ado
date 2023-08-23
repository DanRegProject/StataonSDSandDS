
*********************************************************************
************            IDI           *********************
************************************************************************



program idi
version 10.1

quietly {
	
/* DESCRIBE HOW TO WRITE WHEN YOU WANT TO CALCULATE IDI */
	syntax varlist(min=2), PRvars(varlist min=1)


/* DEFINE THAT CALCULATIONS SHOULD BE PERFORMED IN THE SAME SAMPLE */
	marksample touse

/* DEFINE THAT THE FIRST VARIABLE IN varlist IS CALLED out AND THIS SHOULD BE THE OUTCOME */
	args out

/* DEFINE TEMPORARY VARIABLES TO BE USED IN THE PROGRAM */
tempvar pred1 pred2 diffpred 
tempvar mdiffprednonevents sediffprednonevents mdiffpredevents sediffpredevents
tempvar idi seidi zidi pidi

/* PREDICT MODELS */
logistic `varlist'  if `touse'
predict `pred1'
logistic `varlist' `prvars'  if `touse'
predict `pred2'

/* GENERATE DIFFERENCE BETWEEN PREDICTIONS */
gen `diffpred' = `pred2'-`pred1'


/* GENERATE MEANS AND SE FOR DIFFERENCE BETWEEN PREDICTIONS, NON-EVENTS */
ci `diffpred' if `out' ==0
gen `mdiffprednonevents'=r(mean)
gen `sediffprednonevents'=r(se)

/* GENERATE MEANS AND SE FOR DIFFERENCE BETWEEN PREDICTIONS, EVENTS */
ci `diffpred' if `out'==1
gen `mdiffpredevents' =r(mean)
gen `sediffpredevents'=r(se)

/* CALCULATE IDI */
gen `idi'=(`mdiffpredevents')-(`mdiffprednonevents')
gen `seidi'=  (`sediffprednonevents'^2 + `sediffpredevents'^2)^0.5
gen `zidi'= `idi'/`seidi'
gen `pidi'= 2*(1-normal(abs(`zidi')))


/* SUMMARIZE/EXPORT RESULTS */
preserve
keep in 1
tempvar result
gen str `result'= " "
label variable `result' "IDI"
label variable `idi' "Estimate"
label variable `seidi' "Std. Err."
label variable `zidi' "Z"
label variable `pidi' "P-value"

/* END QUIETLY */
	}

tabdisp `result', cellvar(`idi' `seidi' `pidi') format(%9.5f) cellwidth(12)
restore

end

