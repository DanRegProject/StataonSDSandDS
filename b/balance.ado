*! version 1.3.0  04apr2017
program balance, sortpreserve
	syntax, [SUMmary UNWeighted Weighted width(integer 6) collapseto(string)]
	* check that ps or mnps was last estimation command run
	if ("`e(cmd)'" != "ps" & "`e(cmd)'" != "mnps" & "`e(cmd)'" != "dxwts" ) {
		error 301
	}
	di ""
	
	* we create output table with estout, so check that it is installed
	capture which estout
	if _rc >0 {
		capture ssc install estout, replace
		local estout = _rc
	}
	else{
		local estout = 0
	}
	qui capture estout , note("Testing that note() option works")
	local estout = _rc

	* remove extraneous quotes from paramaters
	local collapseto = lower(subinstr("`collapseto'","'","",.))

	* error out if collapseto is specified but weighted or unweighted is not
	if "`collapseto'" !="" & "`unweighted'"=="" & "`weighted'"=="" {
		display as error "collapseto parameter valid only for weighted|unweighted options"
	 	exit 111
	}		
	
	* if collapseto is not specified, set to default
	if "`collapseto'"=="" | "`collapseto'"=="none" {
		local collapseto pair
	}
	
	* only one collapseto is allowed
	if wordcount("`collapseto'")>1 {
		di as error "Only one collapseto() option is allowed"
		exit 111
	}
	
	* validate enumerated parameters                   
	local validcl = "none pair covariate stop.method"  
	local chkcl : list collapseto in validcl
	if `chkcl' == 0 {
		display as error "Invalid collapseto parameter: `collapseto'"
		display as error "Valid estimand options: `validcl'"
	 	exit 111
	}

	*di "Collapseto=`collapseto'"

	* MNPS 
	if ("`e(cmd)'" == "mnps") {
		* summary (default)
		if "`summary'"!="" | ("`summary'"=="" & "`unweighted'"=="" & "`weighted'"=="") {
			* ATE: 2 summary matricies
			if ("`e(estimand)'" == "ATE") {
				if (`estout' !=0) {
					di as text "Summary of pairwise comparisons"
					matrix list e(summary1), noh f(%6.2f)
					display ""
					di as text "Sample sizes and effective sample sizes"
					matrix list e(summary2), noh f(%6.2f)
					display ""
					*display "Warning: estout could not be installed. Display of balance table will not have anticipated formatting." 
				}
				else{
					estout e(summary1, f(%`width'.0g)), ti("Summary of pairwise comparisons") mlabels(,none) note("") varwidth(10) modelwidth(`=`width'+2')
					estout e(summary2, f(%`width'.0g)), ti("Sample sizes and effective sample sizes") mlabels(,none) note("") varwidth(10) modelwidth(`=`width'+2')
					*estout e(summary), ti("Summary") mlabels(,none) note("")
				}
			}
			* ATT: 1 summary matrix
			if ("`e(estimand)'" == "ATT") {
				if (`estout' !=0) {
					di as text "Summary"
					matrix list e(summary), noh f(%6.2f)
					display ""
					*display "Warning: estout could not be installed. Display of balance table will not have anticipated formatting." 
				}
				else{
					estout e(summary, f(%`width'.0g)), ti("Summary") mlabels(,none) note("") varwidth(10) modelwidth(`=`width'+2')
					*estout e(summary), ti("Summary") mlabels(,none) note("")
				}
			}
		}
		if (`estout'!=0) {
			display as text "Warning: estout could not be installed. Display of balance table will not have anticipated formatting."
		}  
	


		* if not summary(default), bring back balance table
		if ("`unweighted'"!="" | "`weighted'"!="") {
			* preserve data in memory
			preserve 
			clear
			
			matrix baltabmat=e(baltab)
			qui svmat baltabmat, names(col)
			
			* ATT
			if ("`e(estimand)'" == "ATT") {
				* bring back labels
				label define stopmethod `e(l_stopmethod)' 
				label define control `e(l_control)'
				label define var `e(l_var)' 
				label values _var var
				label values _control control
				label values _stopmethod stopmethod
				qui decode _var, gen(var)
				qui decode _control, gen(control)
				qui decode _stopmethod, gen(stopmethod)
				drop _var _control _stopmethod
			}
			
			* ATE
			if ("`e(estimand)'" == "ATE") {
				* bring back labels
				label define stopmethod `e(l_stopmethod)' 
				label define tmt1 `e(l_tmt1)'
				label define tmt2 `e(l_tmt2)'
				label define var `e(l_var)' 
				label values _var var
				label values _tmt1 tmt1
				label values _tmt2 tmt2
				label values _stopmethod stopmethod
				qui decode _var, gen(var)
				qui decode _tmt1, gen(tmt1)
				qui decode _tmt2, gen(tmt2)
				qui decode _stopmethod, gen(stopmethod)
				drop _var _tmt1 _tmt2 _stopmethod
			}
					
  	
			if "`unweighted'"!="" {
				di as text "Unweighted"
				* collapseto=covariate
				if ("`collapseto'"=="covariate") {
					* collapse balance table, no longer a distinction between ATE and ATT
					collapse (max) maxstdeffsz=stdeffsz maxks=ks (min) minp=p minkspval=kspval, by(var stopmethod)
					list var maxstdeffsz minp maxks minkspval stopmethod if stopmethod=="unw"
				}
				* collapseto=stop.method
				else if ("`collapseto'"=="stop.method") {
					* collapse balance table, no longer a distinction between ATE and ATT
					collapse (max) maxstdeffsz=stdeffsz maxks=ks (min) minp=p minkspval=kspval, by(stopmethod)
					list maxstdeffsz minp maxks minkspval stopmethod if stopmethod=="unw"
				}
				* if collapseto not in (covariate,stop.method)
				else {
					if ("`e(estimand)'" == "ATE") {
						list tmt1 tmt2 var mean1 mean2 popsd stdeffsz p ks kspval stopmethod if stopmethod=="unw"
					}
					if ("`e(estimand)'" == "ATT") {
						list var txmn txsd ctmn ctsd stdeffsz stat p ks kspval control stopmethod if stopmethod=="unw"
					}
				}
				display ""
			}
			if "`weighted'"!="" {
				if "`unweighted'"==""{
					if ("`collapseto'"=="covariate") {
						* collapse balance table, no longer a distinction between ATE and ATT
						collapse (max) maxstdeffsz=stdeffsz maxks=ks (min) minp=p minkspval=kspval, by(var stopmethod)
					}
					if ("`collapseto'"=="stop.method") {
						* collapse balance table, no longer a distinction between ATE and ATT
						collapse (max) maxstdeffsz=stdeffsz maxks=ks (min) minp=p minkspval=kspval, by(stopmethod)
					}
				}
				local weightvars `e(weightvars)'
				foreach var of local weightvars { 
					di as text "Weighted: `var'"
					if ("`collapseto'"=="covariate") {
						list var maxstdeffsz minp maxks minkspval stopmethod if stopmethod=="`var'"
					}
					else if ("`collapseto'"=="stop.method") {
						list maxstdeffsz minp maxks minkspval stopmethod if stopmethod=="`var'"
					}
					else {
						if ("`e(estimand)'" == "ATE") {
							list tmt1 tmt2 var mean1 mean2 popsd stdeffsz p ks kspval stopmethod if stopmethod=="`var'"
						}
						if ("`e(estimand)'" == "ATT") {
							list var txmn txsd ctmn ctsd stdeffsz stat p ks kspval control stopmethod if stopmethod=="`var'"
						}
					}
					display ""
				}
			}
  	
			clear 
			restore
		}
	}



	* PS/DXWTS
	if ("`e(cmd)'" == "ps" | "`e(cmd)'" == "dxwts") {
		if "`summary'"!="" | ("`summary'"=="" & "`unweighted'"=="" & "`weighted'"=="") {
			if (`estout' !=0) {
				di as text "Summary"
				matrix list e(summary), noh f(%6.2f)
				display ""
				*display "Warning: estout could not be installed. Display of balance table will not have anticipated formatting." 
			}
			else{
				estout e(summary, f(%`width'.0g)), ti("Summary") mlabels(,none) note("") varwidth(10) modelwidth(`=`width'+2')
				*estout e(summary), ti("Summary") mlabels(,none) note("")
			}
		}
		
		if "`unweighted'"!="" {
			if (`estout' !=0) {
				di as text "Unweighted"
				matrix list e(unw), noh f(%10.2f)
				display ""
				*display "Warning: estout could not be installed. Display of balance table will not have anticipated formatting." 
			}
			else{
				estout e(unw, f(%`width'.0g)), ti("Unweighted") mlabels(,none) note("") varwidth(10) modelwidth(`=`width'+2')
			}
		}
		
		if "`weighted'"!="" {
			local weightvars `e(weightvars)'
			foreach var of local weightvars { 
				if (`estout' !=0) {
					di as text "Weighted: `var'"
					matrix list e(`var'), noh f(%10.2f)
					display ""
					*display "Warning: estout could not be installed. Display of balance table will not have anticipated formatting." 
				}
				else{
				di "`var'"
					estout e(`var', f(%`width'.0g)), ti("Weighted: `var'") mlabels(,none) note("") varwidth(10) modelwidth(`=`width'+2')
				}
			}
		}
		
	
		if (`estout'!=0) {
			display as text "Warning: estout could not be installed. Display of balance table will not have anticipated formatting."
		}
	}
end
