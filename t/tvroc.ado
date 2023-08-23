capture program drop tvROC
program define tvROC
version 11
 if "`1'" == "?" {
    display "kommando: tvROC time cens marker  [if] [in] [using] [,saving() mshift(1.0) tshift(7) bootstrap(0) level(0.95)]"
      display " time:     levetid"
      display " cens:     censoreringsflag: 1:ja 0:nej"
      display " marker:   sygdomsmarkør"
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
syntax varlist(min=1)   [,saving(string) mshift(real 1.0)  tshift(real 7.0)  bootstrap(integer 0) level(real 0.95)]
 	tokenize `varlist'
	local time `1'
	local cens `2'
	local marker `3'
local level invnormal(1-(1-`level')/2)
	egen minclass=min(`marker')
	local minclass=minclass
	egen maxclass=max(`marker')
	local maxclass=maxclass
	drop minclass maxclass
	if "`saving'"=="" {
	local saving = "ROC"
	}
	quietly: count
	local N0=r(N)
	foreach v of numlist `minclass' (`mshift') `maxclass' {
		quietly: count if `marker'<=`v'
		local F`v' = r(N)/`N0'
	}

    tempfile _st0
	tempfile mysaving
	ltable `time' `cens', notable   saving(`_st0', replace)

	preserve
		use `_st0', replace
		keep t0 survival
		rename survival s0
		quietly: save `_st0', replace
		keep t0
		gen sp = 0
		gen se = 1
		gen crit=-99999
		quietly: save `mysaving', replace
		quietly: replace sp = 1
		quietly: replace se = 0
		quietly: replace crit=99999
		quietly: append using `mysaving'
		quietly: save `mysaving', replace

	restore
	foreach v of numlist  `minclass' (`mshift') `maxclass' {
		if `F`v''>0 & `F`v''<1 {
		    tempfile _se`v'
			tempfile _sp`v'
				ltable `time' `cens' if `marker'>`v', notable  saving(`_se`v'', replace)
				ltable `time' `cens' if `marker'<=`v', notable  saving(`_sp`v'', replace)
				preserve
				use `_se`v'', replace
					keep t0 survival
					rename survival sse
					quietly: merge 1:m t0 using `_st0'
					drop _merge
					sort t0
					gen crit=`v'
					quietly: replace sse=sse[_n-1] if sse==.
					gen se = (1-sse)*(1-`F`v'')/(1-s0)
				quietly: save `_se`v'', replace
				use `_sp`v'', replace
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
					use `_sp`v'', replace
					quietly: merge 1:1 t0 using `_se`v''
					drop _merge
					quietly: save `mysaving', replace
				}
				else {
					use `_sp`v'', replace
					quietly: merge 1:1 t0 using `_se`v''
					drop _merge
					quietly: append using `mysaving'
					quietly: save `mysaving', replace
				}
				restore
			}
		}
	preserve
	  use `mysaving', replace
		sort t0 crit
	*	quietly: drop if t0==`maxtime'
		rename t0 `time'
		rename crit `marker'
		rename ssp NPV
		quietly: gen PPV = 1-sse
		drop sse
		quietly: gen FP = 1 - sp
		rename se TP
		drop sp s0

		label var TP "True Positive = Sensitivity"
		label var FP "False Positive = 1-Specificity"
		label var PPV "Positive Predictive Value"
		label var NPV "Negative Predictive Value"
		label var `marker' "free: C<=c; disease: C>c"

		quietly: generate auc = (TP+TP[_n-1])/2*abs(FP-FP[_n-1])
		quietly: replace auc = 0 if `time'!=`time'[_n-1]
		quietly: by `time': generate AUC= sum(auc)
		quietly: by `time': replace AUC= AUC[_N]
		label var AUC "AUC"
		drop auc
		quietly: drop if abs(`marker') == 99999
		quietly: drop if mod(`time',`tshift')>0

order `time' `marker' AUC TP FP PPV NPV
quietly: save `mysaving', replace
		quietly: save `saving', replace

		display "ROC data er lagt i datasættet `saving'"
	restore
  if `bootstrap' > 0 {
	quietly: compress
      tempfile _broc
      tempfile _brocstore
  		display "Der laves nu bootstrapping"
  		forvalues _boot=1/`bootstrap' {
  		display "." _continue
  			preserve
  			bsample
  			quietly: tvROC `time' `cens' `marker' ,saving(`_broc') mshift(`mshift') tshift(`tshift')
  			if `_boot' == 1 {
  				use `_broc', replace
				quietly: drop if mod(`time',`tshift')>0
  				quietly: save `_brocstore', replace
  			}
  			else {
  				use `_broc', replace
  				quietly: drop if mod(`time',`tshift')>0
  				append using `_brocstore'
  				quietly: save `_brocstore', replace
  			}
  			restore
  		}

  		preserve
  		use `_brocstore', replace
  	*	sort `time'
  	*	by `time': replace AUC = . if _n>1
  		quietly: replace TP = log(TP/(1-TP))
  		quietly: replace FP = log(FP/(1-FP))
  		quietly: replace PPV = log(PPV/(1-PPV))
  		quietly: replace NPV = log(NPV/(1-NPV))
  		sort `time' `marker'
  		collapse (sd) TPsd=TP FPsd=FP PPVsd=PPV NPVsd=NPV, by(`time' `marker')
  		quietly: merge 1:m `time' `marker' using `mysaving'
  		quietly: drop _merge
  		quietly: generate TPlow = 1/(1+1/exp(log(TP/(1-TP))- `level' *TPsd))
  		quietly: generate TPup  = 1/(1+1/exp(log(TP/(1-TP))+ `level' *TPsd))
  		quietly: generate FPlow = 1/(1+1/exp(log(FP/(1-FP))- `level' *FPsd))
  		quietly: generate FPup  = 1/(1+1/exp(log(FP/(1-FP))+ `level' *FPsd))
  		quietly: generate PPVlow = 1/(1+1/exp(log(PPV/(1-PPV))- `level' *PPVsd))
  		quietly: generate PPVup  = 1/(1+1/exp(log(PPV/(1-PPV))+ `level' *PPVsd))
  		quietly: generate NPVlow = 1/(1+1/exp(log(NPV/(1-NPV))- `level' *NPVsd))
  		quietly: generate NPVup  = 1/(1+1/exp(log(NPV/(1-NPV))+ `level' *NPVsd))
  		quietly: save `mysaving', replace
		use `_brocstore', replace
 		quietly: keep `time' AUC
  		quietly: replace AUC = log(AUC/(1-AUC))
 	    quietly: duplicates drop
  		collapse (sd) AUCsd=AUC, by(`time')
 		quietly: merge 1:m `time' using `mysaving'
 		quietly: drop _merge
  		quietly: generate AUClow = 1/(1+1/exp(log(AUC/(1-AUC))- `level' *AUCsd))
  		quietly: generate AUCup  = 1/(1+1/exp(log(AUC/(1-AUC))+ `level' *AUCsd))
		quietly: sort `time' `marker'
        order time ScoreOld AUC AUCsd AUClow AUCup TP TPsd TPlow TPup FP FPsd FPlow FPup PPV PPVsd PPVlow PPVup NPV NPVsd NPVlow NPVup
        quietly: save `mysaving', replace
 		quietly: save `saving', replace

  		restore
  		display "ROC data incl spredninger er lagt i datasættet `saving'"
  }

end


