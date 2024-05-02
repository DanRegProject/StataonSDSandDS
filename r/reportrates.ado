/* SVN header
$Date: 2020-03-30 10:16:52 +0200 (ma, 30 mar 2020) $
$Revision: 229 $
$Author: fskMarJen $
$ID: $
*/
/********************************************************************************
                                        #+NAME        : reportRates.ado;
                                        #+TYPE        : Stata file;
                                        #+DESCRIPTION : Report incidence rates
                                        #+OUTPUT      :;
                                        #+AUTHOR      : Flemming Skjøth;
                                        #+CHANGELOG   :Date       Initials Status:
                                                       28.06.2017 FLS      Created;
********************************************************************************/
capture program drop reportRates
program define reportRates, rclass
version 13.0
syntax [if], using(string)   [by(string) strata(string) format(string) sorting(string) fewdata(string)]
tempfile store
tempvar sstrata one
qui save `store' , replace
use `using', clear
if "`if'"!="" keep if `if'
if "`format'"=="" loc format %6.2f
if "`fewdata'"=="" loc fewdata $fewdata
if "`by'"==""{
  loc by `one'
  gen `one'=1
}
if "`strata'"=="" loc strata strata
if "`sorting'" == ""{
	sort `by' analysis Endpoint `strata'
}
else{
	sort `by' `sorting'
}
 capture confirm numeric variable `strata'
if !_rc decode `strata', g(`sstrata')
else gen `sstrata' = `strata'
qui count
loc N=r(N)
loc shift 1
foreach i of numlist 1/`N'{
    if  `shift'==1{
        dis "" _n(2)
        if "`by'"!="`one'" dis "By : "`by'[`i'] " `by'"
        dis "| Analysis | Endpoint | `strata' | Events | Persontime | Rate | 95%CI |"
        dis "|----------|----------|----------|--------|------------|------|-------|"
        loc shift 0
    }
    if _D[`i'] < `fewdata' {
        dis "| " analysis[`i'] " | " Endpoint[`i'] " | " `sstrata'[`i'] " | " "<`fewdata'" " | " "-" ///
            " | " `format' _Rate[`i'] " | (" `format' _Lower[`i'] "-" `format' _Upper[`i'] ") |"
    }
    else{
        dis "| " analysis[`i'] " | " Endpoint[`i'] " | " `sstrata'[`i'] " | "  _D[`i'] " | " ///
            `format' _Y[`i'] " | " `format' _Rate[`i'] " | (" `format' _Lower[`i'] "-" `format' _Upper[`i'] ") |"
    }
    if  `i'>1{
        if "`by'"!="`one'"  & `by'[`i']!= `by'[`i'+1] loc shift 1
    }
}
use `store', clear
end
