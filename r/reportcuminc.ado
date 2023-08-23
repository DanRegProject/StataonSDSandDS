/********************************************************************************
                                        #+NAME        : reportCuminc.ado;
                                        #+TYPE        : Stata file;
                                        #+DESCRIPTION : Create an org friendly table of cumulative incidence ;
                                        #+OUTPUT      :;
                                        #+AUTHOR      : Flemming Skjøth;
                                        #+CHANGELOG   :Date       Initials Status:
                                                       28.06.2017 FLS      Created;
********************************************************************************/
capture program drop reportCuminc
program define reportCuminc, rclass
version 13.0
syntax anything [if] , ENDpoints(string)  Time(numlist) [BY(string) survival byformat(string) format(string) saving(string) sorting(string) replace fewdata(string)]
tokenize `anything'
loc CIstub `1'
loc byby
local nt = wordcount("`time'")
if "`fewdata'"=="" loc fewdata $fewdata

if "`format'"=="" loc format %4.3f
tempfile store CItab
tempvar keepflag byvar keepflagsum keepflagmax catby
qui save `store', replace
* label val $BRGP $BRGP
qui if "`if'"!="" keep if `if'
loc first 1

if "`saving'" != ""{
	
	cap frame drop results
	frame create results str256(By endpoints) double(time risk ci lower upper) 
}


dis "" _n(2)
dis " Estimated Cumulated incidence "
dis `"| `by' |Endpoint | Time | At Risk | CI | 95%CI |"'
dis "|-------+---------+------+---------+----+-------|"
loc bys
if  "`by'" != ""{
	local wc = wordcount("`by'")
	foreach v of numlist 1/`wc' {
		tempvar byvar`v'
		local wd =word("`by'",`v')
		capture decode `wd', gen(`byvar`v'')
		if _rc != 0{
			generate `byvar`v'' = `wd'
		}
		local bys `bys' `byvar`v''
	}
}
qui{
if "`by'"!=""{
	if wordcount("`by'")>1 egen `byvar' = concat(`bys'), punct("-")
	else gen `byvar' = `bys'
	loc byby by `byvar' :
	*noi codebook `byvar'
	capture encode `byvar', gen(`catby')

	if _rc==0 {
		drop `byvar'
		rename `catby' `byvar'

	}
         capture confirm numeric variable `byvar'
        if !_rc {
			cap decode `byvar', g(`catby')
			if _rc!=0 cap tostring `byvar', g(`catby')
			}
        else gen `catby' = `byvar'
	drop `byvar'
        rename `catby' `byvar'
}
	else{
		gen `byvar' = ""
	}

}
foreach e in `endpoints' {
	qui{
		preserve
				if "`sorting'" == ""{
					sort `byvar' `CIstub'`e'time
				}
				else{
					sort `sorting'
				}
                foreach tc of numlist 1/`nt'{
                    local t = word("`time'",`tc')
                    `byby' egen __atRisk`tc' = count(`CIstub'`e'time) if `t'<= `CIstub'`e'time
					/* lav lokale variable der indeholder antal at risk til de forskellige tidspunkter */


		}
		/* add one to get `nby' * `nt' new observations */
		cap drop last
		cap drop newobs
		`byby' generate last = (_n==_N)
		expand 2 if last==1, generate(newobs)
		expand `nt' if newobs == 1
		/*
		if "`sorting'" == ""{
			sort `byvar' `CIstub'`e'time
		}
		else{
			sort `sorting'
		}
		*/

		if "`sorting'" == ""{
			sort `byvar' `CIstub'`e'time newobs
		}
		else{
			sort `sorting' newobs
		}
                `byby' gen rownum = sum(newobs)
		gen atRisk = 0
		gen CItime = 0
		replace `CIstub'`e' = 0 if newobs == 1
		foreach tc of numlist 1/`nt'{
			local t = word("`time'",`tc')
			replace CItime = `t' if rownum == `tc'
			replace `CIstub'`e'time = `t' if rownum == `tc'
			replace atRisk = __atRisk`tc' if rownum == `tc'
		}

		if "`sorting'" == ""{
			sort `byvar' `CIstub'`e'time rownum
		}
		else{
			sort `sorting' rownum
		}

		keep if `e'Status==1 & !missing(`CIstub'`e'time) | newobs == 1

*		cap drop `time'
*		sort `by' `CIstub'`e'time
		gen `keepflag' = 0

		*gen CItime=0
		*gen atRisk=0
		foreach tc of numlist 1/`nt'{
				replace `keepflag' = 0
				cap drop `keepflagsum' `keepflagmax'

				local t = word("`time'",`tc')
                    *`byby' replace `keepflag' =1 if (_n==1 & `t'<= `CIstub'`e'time)
                        *`byby' replace `keepflag' =1 if (_n>1 & _n<_N & `CIstub'`e'time[_n-1]<`t' & `t'<=`CIstub'`e'time)
						`byby' replace `keepflag' = 1 if (`CIstub'`e'time <= `t') & newobs == 0
						`byby' gen `keepflagsum' = sum(`keepflag') if newobs == 0
						`byby' egen `keepflagmax' = max(`keepflagsum') if newobs == 0
						`byby' replace `keepflagmax' = 0 if `keepflagmax'[_n-1] == `keepflagsum'[_n-1]
						/* hvis der ikke er events mellem to FUP tider sættes FUP tideren til den forige observation startende fra toppen */
						`byby' replace `CIstub'`e' = `CIstub'`e'[_n-1] if `keepflagsum'[_n-1] == `keepflagmax'[_n-1] | newobs[_n] == 1
						`byby' replace `CIstub'`e'hi = `CIstub'`e'hi[_n-1] if `keepflagsum'[_n-1] == `keepflagmax'[_n-1] | newobs[_n] == 1
						`byby' replace `CIstub'`e'lo = `CIstub'`e'lo[_n-1] if `keepflagsum'[_n-1] == `keepflagmax'[_n-1] | newobs[_n] == 1
						*save F:\Projekter\FSEID00002177\t2177_009_LM_ERISTA_VHD_LOWSCORE\tempdata\Stata\testdata.dta, replace
                        *`byby' replace `keepflag' =1 if (_n==_N & _N>1 & `CIstub'`e'time[_n-1]<`t')
					*`byby' replace CItime =`t' if (_n==1 & `t'<= `CIstub'`e'time)
                        *`byby' replace CItime =`t' if (_n>1 & _n<_N & `CIstub'`e'time[_n-1]<`t' & `t'<=`CIstub'`e'time)
                        *`byby' replace CItime =`t' if (_n==_N & _N>1 & `CIstub'`e'time[_n-1]<`t')
                        *`byby' replace atRisk =__atRisk`tc' if (_n==1 & `t'<= `CIstub'`e'time)
                        *`byby' replace atRisk =__atRisk`tc' if (_n>1 & _n<_N & `CIstub'`e'time[_n-1]<`t' & `t'<=`CIstub'`e'time)
                        *`byby' replace atRisk =__atRisk`tc' if (_n==_N & _N>1 & `CIstub'`e'time[_n-1]<`t')
		}


		keep if newobs == 1

		keep `by' CItime `CIstub'`e'* `byvar' atRisk

        replace atRisk=0 if missing(atRisk)
		replace `CIstub'`e' = 0 if missing(`CIstub'`e') /* hvis der ikke er nogen observationer inden første FUP time sættes disse til 0 */
		*save F:\Projekter\FSEID00002177\t2177_009_LM_ERISTA_VHD_LOWSCORE\tempdata\Stata\testdata.dta, replace
		cap duplicates drop
		if _rc==0 {
                    if "`survival'"=="survival"{
			replace `CIstub'`e' = 1- `CIstub'`e'
			replace `CIstub'`e'hi = 1- `CIstub'`e'lo
			replace `CIstub'`e'lo = 1- `CIstub'`e'hi
                    }
                    gen Endpoint = "`e'"
                    qui count
                    loc N=r(N)

                    foreach i of numlist 1/`N'{
                        if atRisk[`i']==0 | atRisk[`i']>=`fewdata' noi dis " | " `byformat' `byvar'[`i'] " |  `e' | " CItime[ `i'] " | "  atRisk[`i'] " | " `format' `CIstub'`e'[`i'] " | ("  `format' `CIstub'`e'lo[`i'] "-" `format' `CIstub'`e'hi[`i'] ") |"
						
						if "`saving'" != ""{
							if atRisk[`i']==0{
								frame post results (`byvar'[`i']) ("`e'") (CItime[ `i']) ( atRisk[`i']) (`CIstub'`e'[`i']) (`CIstub'`e'lo[`i']) (`CIstub'`e'hi[`i'])
							}
						}
						
                        if atRisk[`i']>0 & atRisk[`i']<`fewdata' noi dis " | " `byformat' `byvar'[`i'] " |  `e' | " CItime[ `i'] " | <`fewdata' | " `format' `CIstub'`e'[`i'] " | ("  `format' `CIstub'`e'lo[`i'] "-" `format' `CIstub'`e'hi[`i'] ") |"
                    }
                }

		loc first 0
		restore
	}
}
if "`saving'" != ""{
    if "`replace'" =="replace"{
        frame results : save `saving'.dta, replace
    }
    else{
		cap confirm file `saving'.dta
		if _rc == 0{
			frame results : save `CItab', replace
			use `saving', clear
			merge 1:1 By endpoints time using `CItab', nogenerate
			save `saving'.dta, replace	
		}
		else{
			frame results : save `saving'.dta, replace
		}
		
    }
}
use `store', clear
end
