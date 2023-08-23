/* SVN header
$Date: 2018-08-03 11:33:06 +0200 (fr, 03 aug 2018) $
$Revision: 118 $
$Author: FCNI6683 $
$Id: storeGLM.ado 118 2018-08-03 09:33:06Z FCNI6683 $
*/
/********************************************************************************
                                        #+NAME        : storeGLM.ado;
                                        #+TYPE        : Stata file;
                                        #+DESCRIPTION : store GLM in studydatabase;
                                        #+OUTPUT      :;
                                        #+AUTHOR      : Flemming Skjøth;
                                        #+CHANGELOG   :Date       Initials Status:
                                                       11.08.2017 FLS      Created;
********************************************************************************/
capture program drop storeGLM
program define storeGLM, rclass
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
if _rc==0 & "`append'"=="append"{
    use `saving', clear
    merge 1:1 file analysis FUP Endpoint exposure level  using `lusing' , replace update
    drop _merge
}
save `saving', replace
$endhide
use `store', clear
end
