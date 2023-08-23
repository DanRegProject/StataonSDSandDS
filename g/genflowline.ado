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
if "`sameline'"!=""{
 local text $gl_flowtxt + `text'
	replace `flowvar' = "$gl_flowline: `text'" if strpos(`flowvar',"$gl_flowtxt")>0
 }
replace `flowvar' = "$gl_flowline: `text'" if (`criterion') & `flowvar'=="OK"
gl gl_flowtxt `text'
display "Flowline $gl_flowline `text' is generated."
end
