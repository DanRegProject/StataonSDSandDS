/* SVN header
$Date: 2018-08-03 11:33:06 +0200 (fr, 03 aug 2018) $
$Revision: 118 $
$Author: FCNI6683 $
$Id: genFlowline.ado 118 2018-08-03 09:33:06Z FCNI6683 $
*/
/********************************************************************************
                                        #+NAME        : genFlowline.ado;
                                        #+TYPE        : Stata file;
                                        #+DESCRIPTION : Generate line for flowchart;
                                        #+OUTPUT      :;
                                        #+AUTHOR      : Flemming Skj¿th;
                                        #+CHANGELOG   :Date       Initials Status:
                                                       21.06.2017 FLS      Created;
********************************************************************************/
capture program drop genFlowline
program define genFlowline, rclass
version 13
syntax anything, text(string) CRITerion(string) [new SAMEline]
tokenize `anything'
local flowvar `1'
if "`new'"=="new" {
	cap drop `flowvar'
    gen `flowvar' = "OK"
    gl gl_flowline=100
}
if "`sameline'"=="" gl gl_flowline=$gl_flowline+1
replace `flowvar' = "$gl_flowline: `text'" if (`criterion') & `flowvar'=="OK"
display "Flowline $gl_flowline `text' is generated."
end
