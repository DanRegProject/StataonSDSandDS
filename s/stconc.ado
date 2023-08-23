*****************************************************************************
* stconc
*
* C-statistics for survival data; an interface to somersd which can take into
* account competing risks (by forcing competing events to stay in risk set)
*
* Author: 	Anders Gorst-Rasmussen, Aalborg University Hospital, Aalborg University
*         	Email: agorstras@gmail.com
*
* Version history:
*                       :: small update; ensure that larger risk scores -> larger risk
*			:: 0.9 (10Feb2014)
*****************************************************************************
cap program drop stconc
program stconc, eclass
	syntax anything [if] [in],  [Compete(varlist min=1 max=1)]
	version 11
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
	else {
		g `competing' = `compete'
	}
	qui {
        replace `1'=-`1'
        replace `2'=-`2'
		* Handle competing risks by letting competing events be at-risk at all times
		g `tempt' = _t
		g `cens' = 1-_d
		su _t
		replace `tempt'=r(max)+1 if `competing'

		* Fast calculation for rank statistics
		somersd `tempt' `1' `2', cenind(`cens') transf(c)
		replace `1'=-`1'
                replace `2'=-`2'
	}
	* Get rid of tempname in table
	ereturn local depvar "C"
	ereturn di
end
