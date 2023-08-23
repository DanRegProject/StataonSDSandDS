/* SVN header
$Date: 2019-03-17 10:45:19 +0100 (sø, 17 mar 2019) $
$Revision: 151 $
$Author: wnm6683 $
$Id: storeHR.ado 151 2019-03-17 09:45:19Z wnm6683 $
*/
/********************************************************************************
                                        #+NAME        : storeHR.ado;
                                        #+TYPE        : Stata file;
                                        #+DESCRIPTION : store HR in studydatabase;
                                        #+OUTPUT      :;
                                        #+AUTHOR      : Flemming Skj�th;
                                        #+CHANGELOG   :Date       Initials Status:
                                                       11.08.2017 FLS      Created;
********************************************************************************/
capture program drop storeHR
program define storeHR, rclass
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
