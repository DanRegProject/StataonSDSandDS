/********************************************************************************
                                        #+NAME        : genHR.ado;
                                        #+TYPE        : Stata file;
                                        #+DESCRIPTION : Generate Cox HR rates
                                        #+OUTPUT      :;
                                        #+AUTHOR      : Flemming Skjøth;
                                        #+CHANGELOG   :Date       Initials Status:
                                                       11.08.2017 FLS      Created;
********************************************************************************/
capture program drop genHR
program define genHR, rclass
version 13.0
syntax [if] [iweight aweight pweight fweight], ENDPoints(string) at(numlist) Origin(string) Enter(string) Scale(string) EXPosure(string) ///
    [SAVing(string) label(string) id(string) coxopt(string) ADJust(string) ref(string) show append estore elabel(string) postest(string) headlev(string) assumption]
tempfile tmpcox indata
tempvar stopfup
loc first 0
save `indata', replace
if "`if'" != "" keep `if'
if "`append'"=="" loc first 1
if "`id'"!="" loc id id(`id')
if "`ref'"=="" loc ref 1
if "`coxopt'"=="" loc coxopt nolog noshow
if "`headlev'" == "" loc headlev **

dis "`headlev' Cox regression model specification `label'"
dis "- Endpoints: ~`endpoints'~"
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
dis "- STCOX options: ~`coxopt'~"

if "`show'"=="show"  dis "`headlev' Analysis : `label'" _n
foreach e in `endpoints'{
        if "`show'"=="show" {
            dis "`headlev'* Endpoint `e' " _n
        }
        foreach t in `at'{
            loc ttxt = subinstr("`t'",".","_",.)
        $beginhide
        cap drop `stopfup'
        gen `stopfup' = `origin'+`t'*`scale'
        stset `e'EndDate  [`weight'`exp'] if `e'Status<., failure(`e'Status) origin(`origin') enter(`enter') scale(`scale') exit(`stopfup') `id'
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

        if "`assumption'"!="" & strpos("`adjust'","i.")==0{
/* proportional hazards assumptions plot*/
		noi{

			if "`adjust'"==""{
				stphplot, by(`exposure')
				graph export $LocalOutDir/phgraph_`e'_fup_`ttxt'_crude.png, replace
			}
			else{
				stphplot, strata(`exposure') adj(`adjust')
				graph export $LocalOutDir/phgraph_`e'_fup_`ttxt'_adjusted.png, replace
			}
		}
		/* end of proportional hazards assumptions plot */
}

        if wordcount("`exposure'") == 1 capture noisily stcox ib`ref'.`exposure' `adjust' `if', `coxopt'
        if wordcount("`exposure'") > 1 capture noisily stcox `exposure' `adjust' `if', `coxopt'
        if _rc==0{
            if "`postest'"!=""{
tokenize "`postest'", parse("|")

                loc cnt 1
                while "``cnt''"!="" {
                    if  "``cnt''"!="|"{
                        loc `cnt' = subinstr("``cnt''","{e}","`e'`ttxt'",.)
*                        loc `cnt' = subinstr("``cnt''",".","_",.)
                        ``cnt''
                    }
                    loc cnt = `cnt'+1
                }
            }

			/* assumptiontest proportion hazard ratio */
		if "`assumption'"!=""{
			if "`show'"=="" {
                    $endhide
            }

			if "`adjust'"==""{
				estat phtest
				dis "#+END_EXAMPLE"
				dis "[[$LocalOutDir/phgraph_`e'_fup_`ttxt'_crude.png]]" _n
				dis "file: ($LocalOutDir/phgraph_`e'_fup_`ttxt'_crude.png)" _n
				dis "#+BEGIN_EXAMPLE"

			}
			else{
				estat phtest
				if strpos("`adjust'","i.")==0{
				dis "#+END_EXAMPLE"
				dis "[[$LocalOutDir/phgraph_`e'_fup_`ttxt'_adjusted.png]]" _n
				dis "file: ($LocalOutDir/phgraph_`e'_fup_`ttxt'_adjusted.png)" _n
				dis "#+BEGIN_EXAMPLE"
				}
			}

			if "`show'"=="" {
                    $beginhide
            }
		}
			/* end of assumptiontest proportion hazard ratio*/

        if "`estore'" != ""{
            if "`elabel'"==""   loc lab = subinstr("`label'`e'`t'"," ","",.)
            if "`elabel'"!=""   loc lab = subinstr("`elabel'`e'`t'"," ","",.)

            loc lab = subinstr("`lab'",".","_",.)
            estimates store `lab'
            dis "Estimates stored in `lab'."
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
                    loc HR`l' = exp(r(estimate))
                    loc HRl`l' = exp(r(estimate)-$NC*r(se))
                    loc HRu`l' = exp(r(estimate)+$NC*r(se))
                    loc p`l' = r(p)
                }
            }
            if _rc!=0 | `l'==`ref'{
                loc head`l' : label (`exposure') `l'
                loc HR`l' = .
                loc HRl`l' = .
                loc HRu`l' = .
				loc p`l' = .
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
            gen HR = .
            gen HRl = .
            gen HRu = .
            gen pval = .
            loc row 1
            foreach l in `grp'{
                replace level = "`head`l''" if _n ==`row'
                replace HR = `HR`l''  if _n ==`row'
                replace HRl = `HRl`l''  if _n ==`row'
                replace HRu = `HRu`l''  if _n ==`row'
                replace pval = `p`l''  if _n ==`row'
                loc row=`row'+1
            }
            if `first'==0 | "`append'"=="append" append using `saving'
            save `saving', replace
            loc first 0
            restore
        }
        }

            }
        $endhide
		loc show `tempshow'
    }
}
*use `indata', clear
end
