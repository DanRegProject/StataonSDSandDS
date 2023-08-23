*****************************************************************************
* stnri
*
* Net reclassification statistics for survival data in a competing risks setting.
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
* log 20/12/16                      :: corrected to allow categorical with non-changed scores
*****************************************************************************

cap program drop stnri
program stnri, eclass
	syntax anything [if] [in],  At(numlist>=0 min=1 max=1)  [CATegorical Competing(varlist min=1 max=1) NOkey *]
	version 11
	st_is 2 analysis

	tempvar pseudo pred1 pred2 up down myd updown

	* Mark sample
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

	* Check syntax
	tokenize "`anything'"
	if(`: word count `anything''!=2) {
		di as err "Exactly 2 variables must be specified"
		exit
	}
	* If no competing events, set to 0
	if("`competing'"=="") {
		tempvar competing
		g `competing' = 0
	}

qui {
    * Pseudovalues
		stpcuminc `competing' if `touse', at(`at') gen(`pseudo')

		if("`categorical'"=="") {
		* If continuous (default), get reclassifications w/pseudovalue regression
			regress `pseudo' `1' if `touse'
			predict `pred1'
			regress `pseudo' `2' if `touse'
			predict `pred2'
			g `up' = `pred2' > `pred1'
			g `down' = `up'==0
                        g `updown' = 1*`up'+ -1*`down'
		}
		else {
		* Otherwise, use specified up/down reclassification
			g `up' = `1'==1
			g `down' = `2'==1
                g `updown' = 1*`up'+ -1*`down'
		* Sanity check
			quietly count if( `up'==1 & `down'==1)
			local count=r(N)
			if(`count'>0) {
				display as error "`1' (up-reclassifications) and `2' (down-reclassifications) cannot equal 1 simultaneously"
				exit
			}
		}
	}

	* Report "evaluable" reclassification (among those who are definite cases/non-cases @ at())
	g `myd'=_d & _t <= `at'
	di _n as txt "Evaluable reclassifications up to t=`at'"
        di as txt "Note this excludes non-events being censored before t=``at'"
	label variable `updown' " "
	label variable `myd' " "
	cap label drop tmplabel
	cap label drop tmpud
	label define tmplabel 0 "Non-event" 1 "Event"
	label define tmpud -1 "Down" 0 "Equal" 1 "Up"
	label values `myd' tmplabel
	label values `updown' tmpud
	tab `updown' `myd' if _t>`at' | `myd', col nokey wrap

	* Key for coefficient table
	if("`nokey'"==""){
		di _n as txt "Net Reclassification Improvement"  _n
		di "{c TLC}{hline 65}{c TRC}"  _n "{c |} Key" _col(67) "{c |}" _n "{c LT}{hline 65}{c RT}"
		di as txt "{c |} upI+" _col(14) "{it:P(reclassified up | event)}" _col(67) "{c |}"
		di as txt "{c |} upI-" _col(14) "{it:P(reclassified up | non-event)}" _col(67) "{c |}"
		di as txt "{c |} downI+" _col(14)"{it:P(reclassified down | event)}" _col(67) "{c |}"
		di as txt "{c |} downI-" _col(14)"{it:P(reclassified down | non-event)}" _col(67) "{c |}"
		di as txt "{c |} NRI+"  _col(14) "{it:(upI+) - (downI+)}" _col(67) "{c |}"
		di as txt "{c |} NRI-"  _col(14) "{it:(downI-) - (upI-)}" _col(67) "{c |}"
		di as txt "{c |} NRI"  _col(14)  "{it:(NRI+) + (NRI-)}" _col(67) "{c |}"
		di as txt "{c |} PEup"  _col(14) "{it:P(event | reclassified up)}" _col(67) "{c |}"
		di as txt "{c |} PEdown"  _col(14)  "{it:P(event | reclassified down)}" _col(67) "{c |}"
		di as txt "{c BLC}{hline 65}{c BRC}" _n
	}
	* Bootstrap NRI calculations
	bootstrap _b, `options': _nriboot `pseudo' `up' `down'
end
