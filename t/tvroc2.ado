capture program drop tvROC2
program define tvROC2
version 11
 if "`1'" == "?" {
    display "kommando: tvROC2 time cens markervarlist  [if] [in] [using] [,saving() mshift(1.0) tshift(7) bootstrap(0) level(0.95)]"
      display " time:     levetid"
      display " cens:     censoreringsflag: 1:ja 0:nej"
      display " marker:   sygdomsmarkør liste"
	  display "Options:"
	  display " saving:   datasætnavn til ROC kurver, default ROC"
      display " mshift:   interval inddeling af markør"
      display " tshift:   opdeling af tidskale til beregning af bootstrap konfidensitervaller"
      display " bootstrap: dan sikkerhedsintervaller med bootstrap"
	  display " level:    signifikansniveau"
      display "Default værdier er som vist i kommando: "
	  display "Baseret på: Heagerty, Lumley, Pepe (2000), Time-Dependent ROC Curves for Censored "
	  display "            Survival Data and a Diagnostic Marker, Biometrics 56, 337-344"
	  display "Flemming Skjøth, Forskningens Hus, 2010"
      exit
    }
syntax anything [if][in][using]   [,saving(string) mshift(real 1.0)  tshift(real 7.0)  bootstrap(integer 0) level(real 0.95)]
 	tokenize `anything'
	local time `1'
	local cens `2'
	macro shift 2
	local markerlist `*'

    local level invnormal(1-(1-`level')/2)
	if "`saving'"=="" {
		local saving = "ROC"
	}
	quietly: count
	local N0=r(N)
	local first = 1
	tempfile `collect'

	local antmarker : word count `markerlist'
	local i=0

foreach marker of varlist `markerlist'{
    local i=`i' + 1
	egen minclass=min(`marker')
	local minclass=minclass
	egen maxclass=max(`marker')
	local maxclass=maxclass
	drop minclass maxclass
	foreach v of numlist `minclass' (`mshift') `maxclass' {
		quietly: count if `marker'<=`v'
		local F`v' = r(N)/`N0'
	}

    tempfile _st0
	tempfile mysaving
	ltable `time' `cens',intervals(`tshift') notable   saving(`_st0', replace)

	preserve
		quietly: use `_st0', replace
		keep t0 survival
		rename survival s0
		quietly: save `_st0', replace
		keep t0
		gen sp = 0
		gen se = 1
		gen crit=-99999
		quietly: save `mysaving', replace
		replace sp = 1
		replace se = 0
		replace crit=99999
		quietly: append using `mysaving'
		quietly: save `mysaving', replace

	restore
	foreach v of numlist  `minclass' (`mshift') `maxclass' {
		if `F`v''>0 & `F`v''<1 {
		    tempfile _se`v'
			tempfile _sp`v'
			ltable `time' `cens' if `marker'>`v',intervals(`tshift') notable  saving(`_se`v'', replace)
			ltable `time' `cens' if `marker'<=`v',intervals(`tshift') notable  saving(`_sp`v'', replace)
			preserve
			quietly: use `_se`v'', replace
			keep t0 survival
			rename survival sse
			quietly: merge 1:m t0 using `_st0'
			drop _merge
			sort t0
			gen crit=`v'
			quietly: replace sse=sse[_n-1] if sse==.
			gen se = (1-sse)*(1-`F`v'')/(1-s0)
			quietly: save `_se`v'', replace
			quietly: use `_sp`v'', replace
			keep t0 survival
			rename survival ssp
			quietly: merge 1:m t0 using `_st0'
			drop _merge
			sort t0
			gen crit=`v'
			quietly: replace ssp=ssp[_n-1] if ssp==.
			gen sp = (ssp)*(`F`v'')/(s0)
			quietly: save `_sp`v'', replace
			if `v'==-1 {
				quietly: use `_sp`v'', replace
				quietly: merge 1:1 t0 using `_se`v''
				drop _merge
				quietly: save `mysaving', replace
			}
			else {
				quietly: use `_sp`v'', replace
				quietly: merge 1:1 t0 using `_se`v''
				drop _merge
				quietly: append using `mysaving'
				quietly: save `mysaving', replace
			}
			restore
		}
	}
	preserve
	  quietly: use `mysaving', replace
		sort t0 crit
	*	quietly: drop if t0==`maxtime'
		rename t0 `time'
		rename crit Crit
		rename ssp NPV`marker'
		quietly: gen PPV`marker' = 1-sse
		drop sse
		quietly: gen FP`marker' = 1 - sp
		rename se TP`marker'
		drop sp s0

		label var TP`marker' "True Positive = Sensitivity"
		label var FP`marker' "False Positive = 1-Specificity"
		label var PPV`marker' "Positive Predictive Value"
		label var NPV`marker' "Negative Predictive Value"
		label var Crit "free: C<=c; disease: C>c"

		quietly: generate auc = (TP+TP[_n-1])/2*abs(FP-FP[_n-1])
		quietly: replace auc = 0 if `time'!=`time'[_n-1]
		quietly: by `time': generate AUC`marker'= sum(auc)
		quietly: by `time': replace AUC`marker'= AUC`marker'[_N]
		label var AUC`marker' "AUC"
		drop auc
		if (`antmarker'>1 ){
		quietly: gen IntTP`marker' =0
		quietly: gen IntFP`marker' =0
		quietly: by `time': replace IntTP`marker' =(TP+TP[_n-1])/2*1/_N
		quietly: by `time': replace IntFP`marker' =(FP+FP[_n-1])/2*1/_N
		quietly: replace IntTP`marker' = 0 if `time'!=`time'[_n-1]
		quietly: replace IntFP`marker' = 0 if `time'!=`time'[_n-1]
		quietly: by `time': replace IntTP`marker'= sum(IntTP`marker')
		quietly: by `time': replace IntFP`marker'= sum(IntFP`marker')
		quietly: by `time': replace IntFP`marker'= IntFP`marker'[_N]
		quietly: by `time': replace IntTP`marker'= IntTP`marker'[_N]


		}  /*if antmarker gt 1 */

		quietly: drop if abs(Crit) == 99999
		quietly: drop if mod(`time',`tshift')>0

		quietly: save `mysaving', replace

		if `first'==0 {
		  quietly: merge 1:1 `time' Crit using `saving'
		  drop _merge
		}
 		quietly: save `saving', replace
		if `first'==1{
			local first = 0
		}

		display "ROC data er lagt i datasættet `saving'"
	restore
}
	if (`antmarker'>1 ){
	preserve
	quietly: use `saving', replace
	local i=0

	foreach marker  in `markerlist'{


	if `i'>0 {
			local j=0

			foreach marker2 in `markerlist'{
				if(`j'<`i'){
						gen IDI`j'_`i' = (IntTP`marker'-IntTP`marker2')-(IntFP`marker'-IntFP`marker2')

						label var IDI`j'_`i' "IDI`marker'-`marker2' "
					}
					local j=`j'+1
				}

			}
local i=`i' + 1
			}
	quietly: save `saving', replace
	restore
			}

  if `bootstrap' > 0 {
	quietly: compress
      tempfile auctemp
      tempfile _broc
      tempfile _brocstore
  		display "Der laves nu bootstrapping"
  		forvalues _boot=1/`bootstrap' {
  		display "." _continue
  			preserve
  			bsample
  			quietly: tvROC2 `time' `cens' `markerlist' ,saving(`_broc') mshift(`mshift') tshift(`tshift')
  			if `_boot' == 1 {
  				quietly: use `_broc', replace
				quietly: drop if mod(`time',`tshift')>0
				gen _boot=`_boot'
  				quietly: save `_brocstore', replace
  			}
  			else {
  				quietly: use `_broc', replace
  				quietly: drop if mod(`time',`tshift')>0
  				gen _boot=`_boot'
  				append using `_brocstore'
  				quietly: save `_brocstore', replace
  			}
  			restore
  		}

  		use `_brocstore', replace

		foreach marker in `markerlist'{
			foreach st in TP FP PPV NPV AUC{
				quietly: replace `st'`marker' = log(`st'`marker'/(1-`st'`marker')) if `st'`marker'<1
			}
		}
		local antmarker : word count `markerlist'

  		sort `time'
		local i=0
		foreach marker in `markerlist'{
			preserve
			collapse (sd) TP`marker'sd=TP`marker' FP`marker'sd=FP`marker' PPV`marker'sd=PPV`marker' NPV`marker'sd=NPV`marker', by(`time' Crit)
			quietly: merge 1:1 `time' Crit using `saving'
			quietly: drop _merge
			foreach st in TP FP PPV NPV{
						quietly: generate `st'`marker'low = 1/(1+1/exp(log(`st'`marker'/(1-`st'`marker'))- `level' *`st'`marker'sd))
						quietly: generate `st'`marker'up  = 1/(1+1/exp(log(`st'`marker'/(1-`st'`marker'))+ `level' *`st'`marker'sd))
						label var `st'`marker'low "`st'`marker' CI lower"
						label var `st'`marker'up  "`st'`marker' CI upper"
						}
			quietly: save `saving', replace
			restore
			if (`antmarker'>1  & `i'<`antmarker'){
				local j=0

				foreach marker2 in `markerlist'{
					if(`j'>`i'){
					    preserve
						foreach st in TP FP PPV NPV{
							gen d_`st'`i'_`j' = `st'`marker'-`st'`marker2'
						}
						collapse (sd) sdTP`i'_`j'=d_TP`i'_`j'  sdFP`i'_`j'=d_FP`i'_`j' ///
						             sdPPV`i'_`j'=d_PPV`i'_`j' sdNPV`i'_`j'=d_NPV`i'_`j' , by(`time' Crit)
						quietly: merge  1:1 `time' Crit using `saving'
						quietly: drop _merge
						foreach st in TP FP PPV NPV{
							gen z_`st'`i'_`j' = (log(`st'`marker'/(1-`st'`marker'))-log(`st'`marker2'/(1-`st'`marker2'))) / sd`st'`i'_`j'
							gen p_`st'`i'_`j' = 2*normal(z_`st'`i'_`j') if z_`st'`i'_`j'<0
							quietly: replace p_`st'`i'_`j' = 2*(1-normal(z_`st'`i'_`j')) if z_`st'`i'_`j'>=0 & z_`st'`i'_`j'<.
							label var z_`st'`i'_`j' "z-stat `st'`marker'_`marker2'"
							label var p_`st'`i'_`j' "p-value `st'`marker'_`marker2'"
						}
						quietly: save `saving', replace
						restore
						}

					local j=`j'+1
				}
			}

			preserve
			quietly: keep time _boot AUC* IDI*
			quietly: duplicates drop
			quietly: save `auctemp', replace
			collapse (sd) AUC`marker'sd=AUC`marker', by(`time')
			quietly: merge 1:m `time' using `saving'
			quietly: drop _merge
			quietly: generate AUC`marker'low = 1/(1+1/exp(log(AUC`marker'/(1-AUC`marker'))- `level' *AUC`marker'sd))
			quietly: generate AUC`marker'up  = 1/(1+1/exp(log(AUC`marker'/(1-AUC`marker'))+ `level' *AUC`marker'sd))
			label var AUC`marker'low "AUC`marker' CI lower"
			label var AUC`marker'up "AUC`marker' CI upper"
			quietly: sort `time'

			quietly: save `saving', replace
			if (`antmarker'>1  & `i'<`antmarker'){
				local j=0

				foreach marker2 in `markerlist'{
					if(`j'>`i'){
						use `auctemp', replace
list if _n==1, table
						foreach st in AUC{
							gen d_`st'`i'_`j' = `st'`marker'-`st'`marker2'
						}
						quietly: collapse (sd) sdAUC`i'_`j'=d_AUC`i'_`j' sdIDI`i'_`j'=IDI`i'_`j', by(`time')

						quietly: merge  1:m `time' using `saving'
						quietly: drop _merge
			quietly: generate IDI`i'_`j'low = IDI`i'_`j' - `level' * sdIDI`i'_`j'
			quietly: generate IDI`i'_`j'up  = IDI`i'_`j' + `level' * sdIDI`i'_`j'
			label var IDI`i'_`j'low "IDI`marker'-`marker2' CI lower"
			label var IDI`i'_`j'up "IDI`marker'-`marker2' CI upper"
						foreach st in AUC{
							gen z_`st'`i'_`j' = (log(`st'`marker'/(1-`st'`marker'))-log(`st'`marker2'/(1-`st'`marker2'))) / sd`st'`i'_`j'
							gen p_`st'`i'_`j' = 2*normal(z_`st'`i'_`j') if z_`st'`i'_`j'<0
							quietly: replace p_`st'`i'_`j' = 2*(1-normal(z_`st'`i'_`j')) if z_`st'`i'_`j'>=0 & z_`st'`i'_`j'<.
							label var z_`st'`i'_`j' "z-stat `st'`marker'_`marker2'"
							label var p_`st'`i'_`j' "p-value `st'`marker'_`marker2'"
						}
						quietly: save `saving', replace

						}

					local j=`j'+1
				}
			}

			restore
			local i=`i'+1
		}
		display "ROC data incl spredninger er lagt i datasættet `saving'"
	  }

end

