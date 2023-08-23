/********************************************************************************
                                        #+NAME        : storeRates.ado;
                                        #+TYPE        : Stata file;
                                        #+DESCRIPTION : store incidence rates in studydatabase;
                                        #+OUTPUT      :;
                                        #+AUTHOR      : Flemming Skjøth;
                                        #+CHANGELOG   :Date       Initials Status:
                                                       26.06.2017 FLS      Created;
********************************************************************************/
capture program drop storeRates
program define storeRates, rclass
version 13.0
syntax , using(string) id(string)  saving(string) [strata(varlist) append]
tempfile store
tempfile lusing
if "`strata'"=="" loc strata strata
$beginhide
save `store', replace
use `using', clear
gen file = "`id'"
gen exposure = "`strata'"
gen level = `strata'
drop `strata'
save `lusing', replace
cap confirm file `saving'
if _rc==0 & "`append'"=="append"{
    use `saving', clear
    merge 1:1 file analysis FUP Endpoint exposure level using `lusing' , replace update
    drop _merge
}
save `saving', replace
$endhide
use `store', clear
end
