capture program drop tvNRI
program define tvNRI
version 11
if "`1'" == "?" {
    display "kommando: tvNRI timevar deadvar riskVarOld riskVarNew, [ plot() saving() w(0.5) bootstrap(0) level(0.95)]"
      display " timevar:   failure eller censoreringstid"
	  display " deadvar:   indikator for failure, deadvar>0"
      display " riskVarOld:  Variabelstub for Predikteret risiko for sygdom, gammel prediktionsmodel"
	  display " riskVarNew:  Variabelstub for Predikteret risiko for sygdom, ny prediktionsmodel"
	  display "Options:"
	  display " plot:       plot overlevelseskurver"
	  display " w:          vægt faktor "
      display " saving:     datasætnavn til Predikterede risici, default Risk"
	  display " bootstrap:  antal bootstrapsamples til estimation af konfidensintervaller"
	  display " level:      signifikans niveau"
      display "Baseret på:  (), "
	  display "            , , "
	  display "Flemming Skjøth, Forskningens Hus, 2011"
      exit
    }
syntax varlist(max=4) [,plot(string) w(real 0.5) saving(string)  bootstrap(integer 0)  level(real 0.95)]
 	tokenize `varlist'
	local time `1'
	local cens `2'
	local riskModelOld `3'
	local riskModelNew `4'

	if "`saving'"=="" {
	local saving = "NRI"
	}

	preserve
	tempvar UpDown
gen `UpDown' = (`riskModelOld'<`riskModelNew')-(`riskModelOld'>`riskModelNew')
display "Fordeling af Gammel og Ny Score"
tab2 `riskModelOld' `riskModelNew'
display "Fordeling af Gammel og Ny Score for hhv event og non-event grupper"
 bysort `cens' : tab2 `riskModelOld' `riskModelNew'
quietly: 	count if `UpDown'==-1
	local pdown=r(N)
quietly:     count if `UpDown'==1
	local pup=r(N)
quietly: 	count
	local pdown=`pdown'/r(N)
	local pup=`pup'/r(N)

quietly: 	tempfile _Down
quietly: 	tempfile _Up
quietly: 	tempfile _Base
	/* Estimate survival rates */
	if(`pdown'>0)	quietly: ltable `time' `cens' if `UpDown'==-1, notable   saving("`_Down'", replace)
	if(`pup'>0)	    quietly: ltable `time' `cens' if `UpDown'==1, notable   saving("`_Up'", replace)
	            quietly: ltable `time' `cens' , notable   saving("`_Base'", replace)
	/* */
	if(`pdown'==0){
		quietly: use "`_Base'", replace
		quietly: drop if _n>0
		quietly: save "`_Down'", replace
	}
	if(`pup'==0){
		quietly: use "`_Base'", replace
		quietly: drop if _n>0
		quietly: save "`_Up'", replace
	}

	quietly: use "`_Down'", replace
	rename survival Dsurvival
	rename failure  Dfailure
	keep t0 Dsurvival Dfailure
	quietly: save "`_Down'", replace

	quietly: use "`_Up'", replace
	rename survival Usurvival
	rename failure  Ufailure
	keep t0 Usurvival Ufailure
	quietly: save "`_Up'", replace

	quietly: use "`_Base'", replace
	keep t0 survival failure

	quietly: merge 1:1 t0 using "`_Down'"
	drop _merge

	quietly: merge 1:1 t0 using "`_Up'"
	drop _merge

	quietly: replace Dsurvival=Dsurvival[_n-1] if Dsurvival==.
	quietly: replace Usurvival=Usurvival[_n-1] if Usurvival==.
	quietly: replace Dfailure=Dfailure[_n-1] if Dfailure==.
	quietly: replace Ufailure=Ufailure[_n-1] if Ufailure==.
	if(`pdown'==0){
		quietly: replace Dsurvival=1
		quietly: replace Dfailure=0
	}
	if(`pup'==0){
		quietly: replace Usurvival=1
		quietly: replace Ufailure=0
	}
	gen NRID1 = Ufailure*`pup' /failure     - Dfailure*`pdown' /failure
	gen NRID0 = Dsurvival*`pdown' /survival - Usurvival*`pup' /survival
	local w 0.5
	gen NRIw = `w' * NRID1 + (1-`w') * NRID0

   quietly: rename t0 `time'
if("`plot'"=="1" | lower("`plot'")=="true"){
	twoway (line survival `time', connect(J)) (line Dsurvival `time', connect(J))(line Usurvival `time', connect(J)), ///
      legend(label(1 "Overall") label(2 "Reduced risk class") label(3 "Increased risk class") rows(3)) name(_plot1, replace)
   }
   keep `time' NRID0 NRID1 NRIw
	quietly: sort `time'

	quietly: save "`saving'", replace

	 if `bootstrap' > 0 {
	 restore
	quietly: compress
      tempfile _broc
      tempfile _brocstore
  		display "Der laves nu bootstrapping"
  		forvalues _boot=1/`bootstrap' {
  		display "." _continue
  			preserve
  			bsample
  			quietly: tvNRI `time' `cens' `riskModelOld' `riskModelNew' ,plot(0) saving(`_broc') w(`w')
  			if `_boot' == 1 {
  				quietly: use `_broc', replace
				quietly: save `_brocstore', replace
  			}
  			else {
  				quietly: use `_broc', replace
  				quietly: append using `_brocstore'
  				quietly: save `_brocstore', replace
  			}
  			restore
  		}
	preserve

  		quietly: use `_brocstore', replace
		sort `time'
	  collapse (sd) NRID0sd=NRID0 NRID1sd=NRID1 NRIwsd=NRIw , by(`time')
  		quietly: merge 1:m `time' using `saving'
   		quietly: drop _merge
  		quietly: generate NRID0low = NRID0 - `level' * NRID0sd
  		quietly: generate NRID0up  = NRID0 + `level' * NRID0sd
 		quietly: generate NRID1low = NRID1 - `level' * NRID1sd
  		quietly: generate NRID1up  = NRID1 + `level' * NRID1sd
 		quietly: generate NRIwlow = NRIw - `level' * NRIwsd
  		quietly: generate NRIwup  = NRIw + `level' * NRIwsd
		quietly: sort `time'
	  quietly: save `saving', replace



  }
  display ""
	quietly: summarize NRID1, detail
	local medianNRID1=round(r(p50),0.001)
	quietly: summarize NRID0, detail
	local medianNRID0=round(r(p50),0.001)
	quietly: summarize NRIw, detail
	local medianNRIw=round(r(p50),0.001)
if("`plot'"=="1" | lower("`plot'")=="true"){
        twoway (line NRID0 `time')(line NRID1 `time') (line NRIw `time'), ///
            yline(`medianNRID1' `medianNRID0' `medianNRIw') ytitle("P(New better) - P(New worse)") ///
            legend(label(1 "NRI, non-case group") label(2 "NRI, case group") label(3 "NRI, overall") rows(3)) ///
            name(_plot2, replace)
        graph combine _plot1 _plot2, col(2)
   }
	if(`bootstrap'>0){
		quietly: summarize NRID1sd, detail
		local medianNRID1sd=round(r(p50),0.001)
		quietly: summarize NRID0sd, detail
		local medianNRID0sd=round(r(p50),0.001)
		quietly: summarize NRIwsd, detail
		local medianNRIwsd=round(r(p50),0.001)
		quietly: summarize NRID1low, detail
		local medianNRID1low=round(r(p50),0.001)
		quietly: summarize NRID0low, detail
		local medianNRID0low=round(r(p50),0.001)
		quietly: summarize NRIwlow, detail
		local medianNRIwlow=round(r(p50),0.001)
		quietly: summarize NRID1up, detail
		local medianNRID1up=round(r(p50),0.001)
		quietly: summarize NRID0up, detail
		local medianNRID0up=round(r(p50),0.001)
		quietly: summarize NRIwup, detail
		local medianNRIwup=round(r(p50),.001)
	}
display "På tværs af alle tidspunkter opnås følgende"
display "For cases er median [median `level' % CI](median sd) forskellen mellem andelen"
	display "      hvor den nye model gør det bedre og "
	display "      hvor den gør det dårligere"
	if(`bootstrap'>0) display "               (P(ny bedre|case) - P(ny dårligere|case)) =" `medianNRID1' "[" `medianNRID1low' "-" `medianNRID1up' "] (" `medianNRID1sd' ")"
	if(`bootstrap'==0) display "               (P(ny bedre|case) - P(ny dårligere|case)) =" `medianNRID1'
	display "For ikke-cases er median median sd) forskellen mellem andelen"
	display "      hvor den nye model gør det bedre og "
	display "      hvor den gør det dårligere"
	if(`bootstrap'>0) display "               (P(ny bedre|ikke-case) - P(ny dårligere|ikke-case)) =" `medianNRID0'  "[" `medianNRID0low' "-" `medianNRID0up' "] (" `medianNRID0sd' ")"
	if(`bootstrap'==0) display "               (P(ny bedre|ikke-case) - P(ny dårligere|ikke-case)) =" `medianNRID0'
	display "Overordnet er median (median sd) forskellen mellem andelen"
	display "      hvor den nye model gør det bedre og "
	display "      hvor den gør det dårligere"
	if(`bootstrap'>0) display "               (P(ny bedre) - P(ny dårligere)) =" `medianNRIw'  "[" `medianNRIwlow' "-" `medianNRIwup' "] (" `medianNRIwsd' ")"
	if(`bootstrap'==0) display "               (P(ny bedre) - P(ny dårligere)) =" `medianNRIw'
display ""
	if(`bootstrap'>0)	display "NRI data incl spredninger er lagt i datasættet `saving'"
	if(`bootstrap'==0) 	display "NRI(t) er lagt i datasættet `saving'"
	restore
end
