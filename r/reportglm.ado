/* SVN header
$Date: 2018-04-04 14:12:01 +0200 (on, 04 apr 2018) $
$Revision: 76 $
$Author: fskJetNot $
$ID: $
*/
/********************************************************************************
                                        #+NAME        : reportGLM.ado;
                                        #+TYPE        : Stata file;
                                        #+DESCRIPTION : Report glm output tables;
                                        #+OUTPUT      :;
                                        #+AUTHOR      : Flemming Skjøth;
                                        #+CHANGELOG   :Date       Initials Status:
                                                       11.08.2017 FLS      Created;
********************************************************************************/
capture program drop reportGLM
program define reportGLM, rclass
version 13.0
syntax [if] , using(string) [ by(string) format(string) sorting(string) ]
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
foreach i of numlist 1/`N'{
    if `shift'==1{
        dis "" _n(2)
      if "`by'"!=""  dis "`by' : " `by'[`i'] " "
        dis "| Analysis | FUP | Outcome | Exposure | level | GLM | 95%CI |"
        dis "|----------+-----|----------+----------+-------+----+-------|"
        loc shift 0
    }
 dis "| " analysis[`i'] " | " FUP[`i'] " | " Endpoint[`i'] "| " exposure[`i'] " | " level[`i'] " | " ///
              `format' GLM[`i'] " | (" `format' GLMl[`i'] "-" `format' GLMu[`i'] ") |"
    if `i'>1{
      if "`by'"!=""  if `by'[`i'] != `by'[`i'+1] loc shift 1
      }
  }
use `store', clear
end
