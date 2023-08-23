*****************************************************************************
* stconc
*
* C-statistics for survival data; an interface to somersd which can take into
* account competing risks (by forcing competing events to stay in risk set)
*
* Author: 	Flemming Skjøth , Aalborg University Hospital, Aalborg University
*         	Email: fls@rn.dk
* based on version 0.9 coded by Anders Gorst-Rasmussen, Aalborg University Hospital, Aalborg University
*         	Email: agorstras@gmail.com
*
* Version history:
*			:: .95 (29Sep2016)
*****************************************************************************
cap program drop stconc
program stconc, eclass
	syntax anything [if] [in],  [Compete(varlist min=1 max=1)]
	version 13
	st_is 2 analysis

	marksample touse

	* Check for obs
	qui su `touse'
	local nobs=`r(sum)'
	if(`nobs'==0){
		di as err "No observations"
	exit
	}

	* No support for weights
	local w: char _dta[st_wv]
	if("`w'" != "") {
	   display as error "The function does not support weighted data"
	   exit
	}

	* Check if some event times are left truncated.
	quietly sum _t0 if(`touse')
	local max=r(max)
	if(`max'>0) {
		display as error "The function does not support left truncated event times."
		exit
	}

	tempvar pseudo pred1 pred2 tempt cens competing
	tokenize "`anything'"
		if(`: word count `anything''!=2) {
			di as err "Exactly 2 variables  must be specified"
			exit
		}

	if("`compete'"=="") {
		g `competing' = 0
	}
        else{
            g `competing' = `compete'
        }
	qui {
/*		* Larger risk scores -> larger risk
		replace `1'=-`1'
		replace `2'=-`2'
*/
		* Handle competing risks by letting competing events be at-risk at all times
		g `tempt' = _t
		g `cens' = 1-_d
                su _t
                replace `tempt'=r(max)+1e-5 if `competing'
                stcox `1'
                predict _`1'
                stcox `2'
                predict _`2'
                replace _`1' = 1/_`1'
                replace _`2' = 1/_`2'
		* Fast calculation for rank statistics
		somersd `tempt' _`1' _`2' if _st==1, cenind(`cens') transf(c) tdist
                drop _`1' _`2'
/*
replace `1'=-`1'
		replace `2'=-`2'

*/
}
	* Get rid of tempname in table
	ereturn local depvar "C"
	ereturn di
end
