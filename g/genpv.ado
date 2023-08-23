/********************************************************************************
                                        #+NAME        : genPV.ado;
                                        #+TYPE        : Stata file;
                                        #+DESCRIPTION : Generate pseudovalue risk estimates;
                                        #+OUTPUT      :;
                                        #+AUTHOR      : Flemming Skjøth;
                                        #+CHANGELOG   :Date       Initials Status:
                                                       26.06.2017 FLS      Created;
                                                       07.08.2017 FLS      Multiline record support added
********************************************************************************/
capture program drop genPV
program define genPV, rclass
version 13.0
syntax anything [iweight aweight pweight fweight], COMpete(string) ENDPoints(string) at(numlist) Origin(string) Enter(string) Scale(string) [/*id(string)*/ strata(varlist)]
tokenize `anything'
local PVstub `1'
tempvar competing all rownr
tempfile indata pvdata
gen `rownr' = _n
save `indata', replace

dis _n "Calculating pseudovalue based risk estimates using stpcuminc"
/* if "`id'"!="" loc id id(`id') */
if "`strata'"==""{
    loc `strata' `all'
    gen `all' = "All"
}
if "`strata'"!=""{
    egen `all' = concat(`strata')
}
label define PVstatus  0 "Censored" 1 "Survived" 2 "Event" 3 "Competing Event", replace
qui levelsof `all' , local(alllevels)
foreach s in `alllevels'{
    preserve
    qui keep if `all' == "`s'"
    qui count
    if r(N)>0{
        foreach e in `endpoints'{
            cap drop `PVstub'`e'*
                if "`weight'"!="" loc myw `weight'=`exp'
            cap drop `competing'
            gen `competing' = 0
            loc ncomp 1
            foreach cv in `compete'{
        qui{
            replace `competing'=`ncomp' if  `cv'EndDate<`e'EndDate & `cv'Status==1
            replace `competing'=`ncomp' if  `cv'EndDate==`e'EndDate & `cv'Status==1 & `e'Status==0
            replace `e'Status=0 if `competing'==`ncomp' & `cv'EndDate<`e'EndDate & `cv'Status==1
            replace `e'EndDate=`cv'EndDate if `competing'==`ncomp' & `cv'EndDate<`e'EndDate & `cv'Status==1
		}
		* loc ncomp = `ncomp' + 1
            }
            stset `e'EndDate `myw'  if `e'Status<., failure(`e'Status) origin(`origin') enter(`enter') scale(`scale') /* `id' */
        *    tab `e'Status `competing'
            cap noi stpcuminc `competing', at(`at') generate(`PVstub'`e')

	    if _rc != 0 {
		exit _rc
	    }
            if _rc==0 {
                if wordcount("`at'")==1{
                    rename `PVstub'`e' `PVstub'`e'1
                }
                dis _n "Absolute risks generated in `PVstub'`e' for strata `s'"

                loc tt 1
                foreach t in `at'{
                    loc tstr = subinstr(word("`at'",`tt'),".","_",.)
                    rename  `PVstub'`e'`tt' `PVstub'`e'_`tstr' // to avoid variable name conflicts an additional _ is inserted
                    gen  `PVstub'`e'Status`tstr' =0
                    qui replace `PVstub'`e'Status`tstr' = 2*_d+3*`competing' if _t<=`t'
                    qui replace `PVstub'`e'Status`tstr' = 1 if _t>`t'
					qui replace `PVstub'`e'Status`tstr' = . if `PVstub'`e'_`tstr' == . 
                    label val `PVstub'`e'Status`tstr' PVstatus
                    if wordcount("`at'")>1 loc tt=`tt'+1
                }
                loc tt 1
                foreach t in `at'{
                    loc tstr = subinstr(word("`at'",`tt'),".","_",.)
                    loc tt=`tt'+1
                    rename  `PVstub'`e'_`tstr' `PVstub'`e'`tstr' // remove additional _
                    mean  `PVstub'`e'`tstr'
                    tab `PVstub'`e'Status`tstr'
                }
            }
        }
        qui{
            keep `rownr'  `PVstub'*
            save `pvdata', replace
            use `indata', clear
            merge 1:1 `rownr' using `pvdata', update replace nogenerate
            save `indata', replace
            }
    }
    restore
}
use `indata', clear

end
