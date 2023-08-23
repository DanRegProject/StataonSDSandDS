/* SVN header
$Date: 2018-08-03 11:33:06 +0200 (fr, 03 aug 2018) $
$Revision: 118 $
$Author: FCNI6683 $
$Id: reportHR.ado 118 2018-08-03 09:33:06Z FCNI6683 $
*/
/********************************************************************************
                                        #+NAME        : reportFG.ado;
                                        #+TYPE        : Stata file;
                                        #+DESCRIPTION : Report subdistribution HR  tables;
                                        #+OUTPUT      :;
                                        #+AUTHOR      : Flemming Skjøth;
                                        #+CHANGELOG   :Date       Initials Status:
                                                       11.08.2017 FLS      Created;
********************************************************************************/
capture program drop reportFG
program define reportFG, rclass
version 13.0
syntax [if] , using(string) [ by(string) evalue notrare format(string) sorting(string)]
tempfile store
tempvar sstrata
qui save `store', replace
use `using', clear
if "`if'"!="" keep if `if'
if "`format'"=="" loc format %6.2f
if "`sorting'" == ""{
	sort `by' analysis FUP Endpoint exposure level
}
else{
	sort `sorting'
}

qui count
loc N=r(N)
loc shift 1
if "`evalue'"!=""{
	/*following Vanderweele & Ding 2017 Annals of Internal Medicine */
	if "`notrare'"==""{
		generate 	Eval 	= sdHR + sqrt(sdHR*(sdHR-1)) if (sdHR >= 1 & !missing(sdHR))
		replace 	Eval 	= 1/sdHR+sqrt(1/sdHR*(1/sdHR-1)) if (sdHR<1)
		generate 	EvalLow = sdHRl + sqrt(sdHRl*(sdHRl-1)) if sdHR>=1 & !missing(sdHR) & (sdHRl>=1)
		replace 	EvalLow = 1 if sdHR >=1 & !missing(sdHR) & (sdHRl<1)
		replace 	EvalLow = 1/sdHRu+sqrt(1/sdHRu*(1/sdHRu-1)) if sdHR<1 &  !missing(sdHR) & (sdHRu<=1)
		replace 	EvalLow = 1 if sdHR<1 & !missing(sdHR) & (sdHRu>1)
	}
	else{
		generate 	RRapr	= (1-0.5**sqrt(sdHR))/(1-0.5)**sqrt(1/sdHR)
		generate 	RRaprl	= (1-0.5**sqrt(sdHRl))/(1-0.5)**sqrt(1/sdHRl)
		generate 	RRapru	= (1-0.5**sqrt(sdHRu))/(1-0.5)**sqrt(1/sdHRu)
		generate 	Eval 	= RRapr+sqrt(RRapr*(RRapr-1)) if (RRapr >= 1 & !missing(RRapr))
		replace 	Eval	= 1/RRaprl + sqrt(RRaprl*(RRaprl-1)) if (RRapr<1)
		generate	EvalLow	= RRaprl + sqrt(RRaprl*(RRaprl-1)) if RRaprl>=1 & !missing(RRapr) & (RRaprl>=1)
		replace		EvalLow	= 1 if RRapr >= 1 & !missing(RRapr) & (RRaprl < 1)
		replace 	EvalLow	= 1/RRapru+sqrt(1/RRapru*(1/RRapru-1)) if RRapr < 1 & !missing(RRapr) & (RRapru <=1)
		replace		EvalLow	= 1 if RRapr < 1 & !missing(RRapr) & (RRapru > 1)
		drop RRapr*
	}
	local evalhead1 | E-value | Min-E
	local evalhead2 +---------+-------
}
foreach i of numlist 1/`N'{
    if `shift'==1{
        dis "" _n(2)
        if "`by'" !="" dis "`by' : " `by'[`i'] " "
        dis "| Analysis | FUP | Endpoint | Exposure | level | sdHR | 95%CI `evalhead1'|"
        dis "|----------+-----|----------+----------+-------+----+-------`evalhead2'|"
        loc shift 0
    }
if "`evalue'"=="" dis "| " analysis[`i'] " | " FUP[`i'] " | " Endpoint[`i'] "| " exposure[`i'] " | " level[`i'] " | " ///
              `format' sdHR[`i'] " | (" `format' sdHRl[`i'] "-" `format' sdHRu[`i'] ") |"
else dis "| " analysis[`i'] " | " FUP[`i'] " | " Endpoint[`i'] "| " exposure[`i'] " | " level[`i'] " | " ///
               `format' sdHR[`i'] " | (" `format' sdHRl[`i'] "-" `format' sdHRu[`i'] ") |" `format' Eval[`i'] " | " `format' EvalLow[`i'] " |"
    if `i'>1{
        if "`by'" !=""         if `by'[`i'] != `by'[`i'+1] loc shift 1
      }
  }
use `store', clear
end
