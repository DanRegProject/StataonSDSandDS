*****************************************************************************
* stidi
*
* Integrated discrimination improvement for survival data under competing risks
*
* Note that the function conditions on risk scores; accordingly, sampling variation
* due to estimating risk scores from data is not taken into account. This is a
* non-issue when risk scores are known in advance.
*
* Author: 	Anders Gorst-Rasmussen, Aalborg University Hospital, Aalborg University
*         	Email: agorstras@gmail.com
*
* Version history:
*			:: 0.9 (10Feb2014)
*****************************************************************************

cap program drop stidi

program stidi, eclass
	syntax anything [if] [in],  At(numlist>=0 min=1 max=1)  [Competing(varlist min=1 max=1) *]
	version 11
	st_is 2 analysis

	marksample touse

	quietly replace `touse' = 0 if _st==0

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

	tempvar pseudo pred1 pred2
	tokenize "`anything'"
	if(`: word count `anything''!=2) {
		di as err "Exactly 2 variables must be specified"
		exit
	}

	if("`competing'"=="") {
		tempvar competing
		g `competing' = 0
	}

	qui {
		stpcuminc `competing', at(`at') gen(`pseudo')
		regress `pseudo' `1' if `touse'
		predict `pred1'

		regress `pseudo' `2' if `touse'
		predict `pred2'
	}

	bootstrap _b, `options': _idiboot `pseudo' `pred1' `pred2'

end
