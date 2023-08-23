/********************************************************************************
                                        #+NAME        : genGLM.ado;
                                        #+TYPE        : Stata file;
                                        #+DESCRIPTION : Generate generic regression analyses
                                        #+OUTPUT      :;
                                        #+AUTHOR      : Flemming Skjøth;
                                        #+CHANGELOG   :Date       Initials Status:
                                                       11.08.2017 FLS      Created;
********************************************************************************/
capture program drop genGLM
program define genGLM, rclass
version 13.0
syntax anything [if] [iweight aweight pweight fweight],  EXPosure(string) ///
       [Outcomestub(string) at(numlist) SAVing(string) label(string) glmopt(string) ADJust(string) ///
        ref(string) show append estore elabel(string) headlev(string) postest(string) engine(string) BYEXPosure]
tempfile tmpglm indata
tempvar stopfup
tokenize `anything'
loc first 0
loc Y `i'
*save `indata', replace
if "`append'"=="" loc first 1
if "`ref'"=="" loc ref 1
if "`glmopt'"=="" loc glmopt nolog noshow
if "`headlev'" == "" loc headlev **
if "`engine'"=="" loc engine glm
loc nexp = wordcount("`exposure'")
if "`byexposure'" == "" loc nexp 1

dis "`headlev' `engine' regression model specification `label'"
dis "- Outcome(s): ~[`outcomestub']`anything'[`at']~"
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
dis "- `engine' options: ~`glmopt'~"

if "`show'"=="show"  dis "`headlev' Analysis : `label'" _n
if "`at'"=="" loc at -1

foreach e in `anything'{
        if "`show'"=="show" {
            dis "`headlev'* Outcome `e' " _n
        }
    foreach t in `at'{
        foreach l of numlist 1/`nexp'{
			loc thisexp = word("`exposure'",`l')
			if `nexp' == 1 loc thisexp `exposure'
                        $beginhide
                        loc tt
                        if "`t'"!="-1" loc tt `t'
                        loc tstr = subinstr("`tt'",".","_",.)
        if "`show'"=="show" {
            $endhide
            if "`tt'"!="" dis "/Follow-up `tt'/" _n
            dis "#+BEGIN_EXAMPLE"
        }
		di "`engine' `outcomestub'`e'`tstr' ib`ref'.`thisexp' `adjust' [`weight'`exp'] `if', `glmopt'"
        if wordcount("`exposure'") == 1 capture noisily `engine' `outcomestub'`e'`tstr' ib`ref'.`thisexp' `adjust' [`weight'`exp'] `if', `glmopt'
		else if `nexp'== 1 capture noisily `engine' `outcomestub'`e'`tstr' `thisexp' `adjust' [`weight'`exp'] `if', `glmopt'
        else capture noisily `engine' `outcomestub'`e'`tstr' ib`ref'.`thisexp' `adjust' [`weight'`exp'] `if', `glmopt'
        if _rc==0{
            if "`postest'"!=""{
/*
if "`show'"=="" {
                    $endhide
                    dis "`headlev'* Outcome `e' " _n
                    if "`tt'"!="" dis "/Follow-up `tt'/" _n
                    dis "#+BEGIN_EXAMPLE"
                }
*/
tokenize "`postest'", parse("|")

                loc cnt 1
                while "``cnt''"!="" {
                    if  "``cnt''"!="|"{
                        loc `cnt' = subinstr("``cnt''","{e}","`outcomestub'`e'`tstr'",.)
*                        loc `cnt' = subinstr("``cnt''","_",".",.) /* her har MJ rettet til at _ bliver til . og ikke omvendt */
                        ``cnt''
                    }
                    loc cnt = `cnt'+1
                }
/*
if "`show'"=="" {
                    dis "#+END_EXAMPLE"
                    $beginhide
                }
*/

            }

        if "`estore'" != ""{
            if "`elabel'"=="" loc lab = subinstr("`label'`e'`tstr'"," ","",.)
            if "`elabel'"!="" loc lab = subinstr("`elabel'`e'`tstr'"," ","",.)
            if "`byexposure'"=="" loc lab = subinstr("`lab'",".","_",.)
            if "`byexposure'"!="" loc lab = subinstr("`lab'`l'",".","_",.)

                estimates store `lab'
                dis "Estimates stored in `lab'."
            }
        if "`show'"=="show" {
            dis "#+END_EXAMPLE"
            $beginhide
        }
        if "`saving'" != "" & (wordcount("`exposure'")==1 | "`byexposure'"!="") {
            qui levelsof `thisexp', local(grp)
            loc ngrp : word count `grp'
            foreach i in `grp'{
                if `i'!=`ref'{
                    if _rc==0 {
                        lincom `i'.`thisexp'
                        loc head`i' : label (`thisexp') `i'
                        if "`engine'"=="glm"{
                        if strpos("`glmopt'","link(log)")>0{
                            loc GLM`i' = exp(r(estimate))
                            loc GLMl`i' = exp(r(estimate)-$NC*r(se))
                            loc GLMu`i' = exp(r(estimate)+$NC*r(se))
                        }
                        if strpos("`glmopt'","link(identity)")>0 | strpos("`glmopt'","link(")==0{
                            loc GLM`i' = r(estimate)
                            loc GLMl`i' = r(estimate)-$NC*r(se)
                            loc GLMu`i' = r(estimate)+$NC*r(se)
                        }
                        }
                        if "`engine'"!="glm"{
                        if strpos("`glmopt'","or ")>0 | strpos("`glmopt'"," or")>0{
                            loc GLM`i' = exp(r(estimate))
                            loc GLMl`i' = exp(r(estimate)-$NC*r(se))
                            loc GLMu`i' = exp(r(estimate)+$NC*r(se))
                        }
                        else {
                            loc GLM`i' = r(estimate)
                            loc GLMl`i' = r(estimate)-$NC*r(se)
                            loc GLMu`i' = r(estimate)+$NC*r(se)
                        }
                        }
                    }
                }
            if _rc!=0 | `i'==`ref'{
                loc head`i' : label (`thisexp') `i'
                loc GLM`i' = .
                loc GLMl`i' = .
                loc GLMu`i' = .
            }
        }
        loc ngrp1 =`ngrp'-1
        qui{
            preserve
            drop _all
            set obs `ngrp'
            gen Endpoint =  "`e'"
            gen FUP = .
            if "`tt'" != "" replace FUP = `tt'
            gen exposure = "`thisexp'"
            gen level = ""
            gen analysis = "`label'"exp
            gen GLM = .
            gen GLMl = .
            gen GLMu = .
            loc row 1
            foreach l in `grp'{
                replace level = "`head`l''" if _n ==`row'
                replace GLM = `GLM`l''  if _n ==`row'
                replace GLMl = `GLMl`l''  if _n ==`row'
                replace GLMu = `GLMu`l''  if _n ==`row'
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
    }
}
}
*use `indata', clear
end
