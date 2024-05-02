/********************************************************************************
                                        #+NAME        : genGLM.ado;
                                        #+TYPE        : Stata file;
                                        #+DESCRIPTION : GLM regression call
                                        #+OUTPUT      :;
                                        #+AUTHOR      : Flemming Skjøth;
                                        #+CHANGELOG   :Date       Initials Status:
                                                       11.08.2017 FLS      Created;
********************************************************************************/
capture program drop genGLM
program define genGLM, rclass
version 13.0
syntax anything [iweight aweight pweight fweight] [if],  EXPosure(string) ///
    [Outcomestub(string) at(numlist) SAVing(string) label(string) glmopt(string) ADJust(string) ///
     ref(string) show append estore elabel(string) postest(string) headlev(string) engine(string) BYEXPosure]
tempfile tmpglm indata
tempvar stopfup
tokenize `anything'
loc first 0
loc Y `1'
*save `indata', replace
if "`append'"=="" loc first 1
*if "`ref'"=="" loc ref 1
if "`glmopt'"=="" loc glmopt nolog noshow
if "`headlev'"=="" loc headlev **
if "`engine'"=="" loc engine glm
loc nexp = wordcount("`exposure'")
if "`byexposure'"=="" loc nexp 1

dis `"`headlev' `engine' regression model specification `label'"'
dis `"- Outcome(s): ~[`outcomestub']`anything'[`at']~"'
dis `"- Exposure or covariates of interest: ~`exposure'~"'
if "`adjust'"!=""{
    dis `"- Covariates for adjustment: ~`adjust'~"'
}
if "`if'"!=""{
    dis `"- Population restriction: ~`if'~"'
}
if "`weight'`exp'"!=""{
    dis `"- Weight specification: ~`weight'`exp'~"'
}
dis `"- `engine' options: ~[`glmopt']~"'


if "`show'"=="show"  dis "`headlev' Analysis : `label'" _n
if "`at'"=="" loc at -1
if "`ref'"!="" loc ref ib`ref'.
foreach e in `anything'{
    if "`show'"=="show" {
        dis "`headlev'* Outcome `e' " _n
        }
    foreach t in `at'{
        foreach expo of numlist 1/`nexp' {
            loc thisexp = word("`exposure'",`expo')
            if `nexp'==1 loc thisexp `exposure'
        $beginhide
        loc tt
        if "`t'"!="-1" loc tt `t'
        loc tstr = subinstr("`tt'",".","_",.)
        if "`show'"=="show" {
            $endhide
            if "`tt'"!= "" dis "/Follow-up `tt'/" _n
            dis "#+BEGIN_EXAMPLE"
        }
        if wordcount("`exposure'") == 1 capture noisily `engine' `outcomestub'`e'`tstr' `ref'`thisexp' `adjust' [`weight'`exp'] `if'  , `glmopt'
        else if `nexp'==1 capture noisily `engine' `outcomestub'`e'`tstr' `thisexp' `adjust' [`weight'`exp']  `if', `glmopt'
        else capture noisily `engine' `outcomestub'`e'`tstr' 'ref'`thisexp' `adjust' [`weight'`exp']  `if', `glmopt'
if _rc==0{
if "`postest'"!=""{
/*
if "`show'"=="show" {
            $endhide
            if "`tt'"!= "" dis "/Follow-up `tt'/" _n
            dis "#+BEGIN_EXAMPLE"
        }
*/
    tokenize "`postest'", parse("|")
        loc cnt 1
        while "``cnt''"!=""{
            if "``cnt''"!="|"{
                loc `cnt' = subinstr("``cnt''","{e}","`outcomestub'`e'`tstr'",.)
*                loc `cnt' = subinstr("``cnt''",".","_",.)
                ``cnt''
            }
            loc cnt = `cnt' +1
        }
/*
if "`show'"=="show" {
            dis "#+END_EXAMPLE"
            $beginhide
        }
*/
}

    if "`estore'" != ""{
            if "`elabel'"=="" loc lab = subinstr("`label'`e'`tstr'"," ","",.)
            if "`elabel'"!="" loc lab = subinstr("`elabel'`e'`tstr'"," ","",.)
            if "`byexposure'"=="" loc lab = subinstr("`lab'",".","_",.)
            if "`byexposure'"!="" loc lab = subinstr("`lab'`exp'",".","_",.)

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
	if "`ref'"=="" loc grp 0
        foreach l in `grp'{
	    if strpos("`ref'","`l'")==0{
                if _rc==0 {
		    if "`ref'"=="" lincom `thisexp'
                    else lincom `l'.`thisexp'
                    loc head`l' : label (`thisexp') `l'
                    if "`engine'"=="glm"{
                    if strpos("`glmopt'","link(log")>0 {
                        loc GLM`l' = exp(r(estimate))
                        loc GLMl`l' = exp(r(estimate)-$NC*r(se))
                        loc GLMu`l' = exp(r(estimate)+$NC*r(se))
                    }
                    if strpos("`glmopt'","link(identity)")>0 | strpos("`glmopt'","link(")==0  {
                        loc GLM`l' = r(estimate)
                        loc GLMl`l' = r(estimate)-$NC*r(se)
                        loc GLMu`l' = r(estimate)+$NC*r(se)
                    }
                }
                    if "`engine'"!="glm"{
                    if strpos("`glmopt'"," or ")>0 {
                        loc GLM`l' = exp(r(estimate))
                        loc GLMl`l' = exp(r(estimate)-$NC*r(se))
                        loc GLMu`l' = exp(r(estimate)+$NC*r(se))
                    }
                    else {
                        loc GLM`l' = r(estimate)
                        loc GLMl`l' = r(estimate)-$NC*r(se)
                        loc GLMu`l' = r(estimate)+$NC*r(se)
                    }
                }
            }
            }
            if _rc!=0 | "`l'"=="`ref'"{
                loc head`l' : label (`thisexp') `l'
                loc GLM`l' = .
                loc GLMl`l' = .
                loc GLMu`l' = .
            }
        }
        loc ngrp1 =`ngrp'-1
        qui{
            preserve
            drop _all
            set obs `ngrp'
            gen Endpoint =  "`e'"
            gen FUP = .
            if "`tt'"!="" replace FUP = `tt'
            gen exposure = "`thisexp'"
            gen level = ""
            gen analysis = "`label'"
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
*use `indata' ,clear
end
