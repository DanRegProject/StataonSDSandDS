/********************************************************************************
                                        #+NAME        : storeGLM.ado;
                                        #+TYPE        : Stata file;
                                        #+DESCRIPTION : store GLM in studydatabase;
                                        #+OUTPUT      :;
                                        #+AUTHOR      : Flemming Skjøth;
                                        #+CHANGELOG   :Date       Initials Status:
                                                       11.08.2017 FLS      Created;
********************************************************************************/
capture program drop storeFG
program define storeFG, rclass
version 13.0
syntax , using(string) id(string) saving(string) [append]
tempfile store
tempfile lusing
$beginhide
save `store', replace
use `using', clear
gen file = "`id'"
save `lusing', replace
cap confirm file `saving'
if _rc==0  & "`append'"=="append"{
    use `saving', clear
    merge 1:1 file analysis FUP Endpoint exposure level  using `lusing' , replace update
    drop _merge
}
save `saving', replace
$endhide
use `store', clear
end
