*****************************************************************************
* one2nmatch
*
* One to many match selection with/without replacement
*
*
* Author: 	Flemming Skjøth, Aalborg University Hospital, Aalborg University
*         	Email: fls@rn.com
*
* Version history:
*			:: 0.1 (08Feb2017).
*****************************************************************************
cap program drop one2nmatch
program one2nmatch, rclass
version 14
	syntax varlist(min=2 max=2) [if] [in] [, nrep(integer 1) replace]
/*
* this part should work but for some reason touse is zero for all rows

        marksample touse

	* Check for obs
	 su `touse'
	local nobs=`r(sum)'
	if(`nobs'==0){
		di as err "No observations"
*	exit
	}
*/
tempfile mydata
save `mydata', replace
/* indgangsdatasættet er lavet så hver case er koblet med alle potentielle kontroller */
/* Det antages også at casen har sin egen record i datasættet, variablen som indikerer */
/* koblingen mellem kontrol og case, som derfor holder cases id (pnr) antages at være lagt i */
/* variablen $mpnr */
/* det forudsættes at der er lavet en variablen ran som er uniformt fordelt og som er lig 1.1 hvis */
/* pnr == $mpnr */
/* nrep angiver antallet af match */


/* laver først en nøgle så case pnr erstattes med fortløbende heltal */
tempvar mpnrloc ran
tempfile key
gen `ran' = runiform()
replace `ran'=1.1 if `1'==`2'

keep `1' `2' `ran'
sort `1' `2'

by `1': gen `mpnrloc'=1 if _n==1
replace `mpnrloc'=sum(`mpnrloc')
recast int `mpnrloc' , force
preserve
keep `mpnrloc' `1'
duplicates drop
save `key', replace
restore

drop `1'

drop if `ran'>1
/* lav en række pr kontrol med en kolonne pr case (typisk er der flere unikke kontroller end cases) */
reshape wide `ran' ,i(`2') j(`mpnrloc')
/* for hver case findes nu $Nrep kontroller og disse kontroller udelukkes fra at kunne være kontroller for andre */
/* med andre ord vi laver udtrækning uden tilbagelægning */
foreach c of numlist 1/`nrep'{
  foreach v1 of varlist `ran'* {
      sort `v1'
      qui replace `v1' = `c' if _n==`c' & `v1'<. & `c'>`v1'
      qui replace `v1' = `v1' + 1 if _n>`c' & `v1'<.

     if "`replace'"==""{
         foreach v2 of varlist `ran'* {
             if "`v2'"!="`v1'" qui replace `v2'=. if _n==`c' & `v2'>floor(`v2')
         }
     }
  }
}
foreach v1 of varlist `ran'* {
    qui replace `v1'=. if `v1'>floor(`v1')
}
reshape long `ran', i(`2') j(`mpnrloc')
keep if `ran' < .
keep if `ran'==floor(`ran')
/* variablen `ran' er nu heltal fra 1 til nrep */

/* på med case pnr  igen */
merge m:1 `mpnrloc' using `key', keepusing(`mpnrloc' `1')

drop _merge
drop `mpnrloc'
/* sikre at case pnr har sin egen række */
expand 2 if `ran'==1, gen(flag)
replace `2'=`1' if flag==1
drop flag `ran'

/* flette original data på igen og rydde op */
merge 1:1 `2' `1' using `mydata'
keep if _merge==3
drop _merge
end
