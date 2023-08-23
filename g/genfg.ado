/********************************************************************************
                                        #+NAME        : genFG.ado;
                                        #+TYPE        : Stata file;
                                        #+DESCRIPTION : Generate FG subdist HR rates
                                        #+OUTPUT      :;
                                        #+AUTHOR      : Flemming Skjøth;
                                        #+CHANGELOG   :Date       Initials Status:
                                                       11.08.2017 FLS      Created;
********************************************************************************/
capture program drop genFG
program define genFG, rclass
version 13.0
syntax [iweight aweight pweight fweight], ENDPoints(string) compete(string) at(numlist) Origin(string) Enter(string) Scale(string) EXPosure(string) ///
    [SAVing(string) label(string) id(string) crregopt(string) ADJust(string) ref(string) show append estore headlev(string)]
tempfile tmpfg indata
tempvar stopfup
qui save `indata', replace

loc first 0
if "`append'"=="" loc first 1
if "`id'"!="" loc id id(`id')
if "`ref'"=="" loc ref 1
if "`crregopt'"=="" loc crregopt nolog noshow
if  "`headlev'"=="" loc headlev **
dis "`headlev' Fine & Gray sub-distribution regression model specification `label'"
dis "- Endpoints: ~`endpoints'~"
dis "- Competing events: ~`compete'~"
dis "- Exposure or covariates of interest: ~`exposure'~"
if "`adjust'"!=""{
    dis "- Covariates for adjustment: ~`adjust'~"
}
if "`if'"!=""{
    dis "- Population restriction: ~`if'~"
}
if "`weight'`exp'"!=""{
    dis "- Weight specification: ~`weight'`exp'~"
}
dis "- STSET setup: Origin: ~`origin'~, Enter: ~`enter'~, Timescaling: ~`scale'~, Exit: ~`at'~, Clusters (optional): ~[`id']~"
dis "- STCREG options: ~[`crregopt']~"



    if "`show'"=="show"  dis "`headlev' Fine & Gray Analysis : `label'" _n
foreach e in `endpoints'{
        if "`show'"=="show" {
            dis "`headlev'* Endpoint `e' " _n
        }
       qui{
			tempvar `e'Status `e'EndDate
			gen ``e'Status' = `e'Status
			gen ``e'EndDate' = `e'EndDate
			loc ncomp 2
			loc complist
			foreach cv in `compete'{
				loc complist = `complist' `ncomp'
				replace ``e'Status'=`ncomp' if  `cv'EndDate<``e'EndDate' & ``e'EndDate'<. &  `cv'Status==1
				replace ``e'Status'=`ncomp' if  `cv'EndDate==``e'EndDate' & `cv'Status==1 & ``e'Status'==0
				replace ``e'EndDate'=`cv'EndDate if ``e'Status'==`ncomp' & `cv'EndDate<``e'EndDate' & ``e'EndDate'<. &  `cv'Status==1
				loc ncomp = `ncomp' + 1
			}
	}
    foreach t in `at'{
        $beginhide
        cap drop `stopfup'
        gen `stopfup' = `origin'+`t'*`scale'
        stset ``e'EndDate'  [`weight'`exp'] if ``e'Status'<., failure(``e'Status'==1) origin(`origin') enter(`enter') scale(`scale') exit(`stopfup') `id'

        qui{
				summarize _d
				loc FAILS = `r(sum)'
			}
			loc tempshow `show'
			if `FAILS' < 4 & `FAILS'!=0{
				$endhide
				dis "This analysis is not displayed due to low number of events (`FAILS'<4)'"
				$beginhide
				loc show
			}
        if "`show'"=="show" {
            $endhide
            dis "/Follow-up `t' year(s)/" _n
            dis "#+BEGIN_EXAMPLE"
        }
        if wordcount("`exposure'") == 1 capture noisily stcrreg ib`ref'.`exposure' `adjust', compete(``e'Status'== `complist') `crregopt'
        if wordcount("`exposure'") > 1 capture noisily stcrreg `exposure' `adjust', compete(``e'Status'== `complist') `crregopt'
        if _rc==0{
            if "`estore'" != ""{
                loc lab = subinstr("`label'`e'`t'"," ","",.)
                loc lab = subinstr("`lab'",".","_",.)
                estimates store est`lab'
                dis "Estimates stored in est`lab'."
            }
            if "`show'"=="show" {
                dis "#+END_EXAMPLE"
                $beginhide
            }
            if "`saving'" != "" & wordcount("`exposure'")==1{
		qui levelsof `exposure', local(grp)
		loc ngrp : word count `grp'
                foreach l in `grp'{
                    if `l'!=`ref'{
                        if _rc==0 {
                            lincom `l'.`exposure'
                            loc head`l' : label (`exposure') `l'
                            loc sdHR`l' = exp(r(estimate))
                            loc sdHRl`l' = exp(r(estimate)-$NC*r(se))
                            loc sdHRu`l' = exp(r(estimate)+$NC*r(se))
                        }
                    }
                    if _rc!=0 | `l'==`ref'{
                        loc head`l' : label (`exposure') `l'
                        loc sdHR`l' = .
                        loc sdHRl`l' = .
                        loc sdHRu`l' = .
                    }
                }
                loc ngrp1 =`ngrp'-1
                qui{
                    preserve
                    drop _all
                    set obs `ngrp'
                    gen Endpoint =  "`e'"
                    gen FUP = `t'
                    gen exposure = "`exposure'"
                    gen level = ""
                    gen analysis = "`label'"
                    gen sdHR = .
                    gen sdHRl = .
                    gen sdHRu = .
                    loc row 1
                    foreach l in `grp'{
                        replace level = "`head`l''" if _n ==`row'
                        replace sdHR = `sdHR`l''  if _n ==`row'
                        replace sdHRl = `sdHRl`l''  if _n ==`row'
                        replace sdHRu = `sdHRu`l''  if _n ==`row'
                        loc row=`row'+1
                    }
                    if `first'==0 | "`append'"=="append" append using `saving'
                    qui save `saving', replace
                    loc first 0
                    restore
                }
            }
        $endhide
        }
		loc show `tempshow'
    }
}
use `indata', clear

end
