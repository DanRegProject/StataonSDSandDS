/* SVN header
$Date: 2021-12-21 13:21:33 +0100 (ti, 21 dec 2021) $
$Revision: 319 $
$Author: wnm6683 $
$Id: reportHR.ado 319 2021-12-21 12:21:33Z wnm6683 $
*/
/********************************************************************************
                                        #+NAME        : reportHR.ado;
                                        #+TYPE        : Stata file;
                                        #+DESCRIPTION : Report HR rate tables;
                                        #+OUTPUT      :;
                                        #+AUTHOR      : Flemming Skjøth;
                                        #+CHANGELOG   :Date       Initials Status:
                                                       11.08.2017 FLS      Created;
********************************************************************************/
capture program drop reportHR
program define reportHR, rclass
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
		generate 	Eval 	= HR + sqrt(HR*(HR-1)) if (HR >= 1 & !missing(HR))
		replace 	Eval 	= 1/HR+sqrt(1/HR*(1/HR-1)) if (HR<1)
		generate 	EvalLow = HRl + sqrt(HRl*(HRl-1)) if HR>=1 & !missing(HR) & (HRl>=1)
		replace 	EvalLow = 1 if HR >=1 & !missing(HR) & (HRl<1)
		replace 	EvalLow = 1/HRu+sqrt(1/HRu*(1/HRu-1)) if HR<1 &  !missing(HR) & (HRu<=1)
		replace 	EvalLow = 1 if HR<1 & !missing(HR) & (HRu>1)
	}
	else{
		generate 	RRapr	= (1-0.5**sqrt(HR))/(1-0.5)**sqrt(1/HR)
		generate 	RRaprl	= (1-0.5**sqrt(HRl))/(1-0.5)**sqrt(1/HRl)
		generate 	RRapru	= (1-0.5**sqrt(HRu))/(1-0.5)**sqrt(1/HRu)
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
        if "`by'" !=""         dis "`by' : " `by'[`i'] " "
        dis "| Analysis | FUP | Endpoint | Exposure | level | HR | 95%CI | p-value `evalhead1'|"
        dis "|----------+-----|----------+----------+-------+----+-------|---------`evalhead2'|"
        loc shift 0
    }
if "`evalue'"=="" dis "| " analysis[`i'] " | " FUP[`i'] " | " Endpoint[`i'] "| " exposure[`i'] " | " level[`i'] " | " ///
              `format' HR[`i'] " | (" `format' HRl[`i'] "-" `format' HRu[`i'] ") |" %6.4f pval[`i'] " | "
else dis "| " analysis[`i'] " | " FUP[`i'] " | " Endpoint[`i'] "| " exposure[`i'] " | " level[`i'] " | " ///
               `format' HR[`i'] " | (" `format' HRl[`i'] "-" `format' HRu[`i'] ") |" %6.4f pval[`i'] " | " `format' Eval[`i'] " | " `format' EvalLow[`i'] " |"
    if `i'>1{
        if "`by'" !=""         if `by'[`i'] != `by'[`i'+1] loc shift 1
      }
  }
use `store', clear
end
