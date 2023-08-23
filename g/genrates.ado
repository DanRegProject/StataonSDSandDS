/********************************************************************************
                                        #+NAME        : genRates.ado;
                                        #+TYPE        : Stata file;
                                        #+DESCRIPTION : Generate incidence rates
                                        #+OUTPUT      :;
                                        #+AUTHOR      : Flemming Skj¿th;
                                        #+CHANGELOG   :Date       Initials Status:
                                                       28.06.2017 FLS      Created;
                                                       07.08.2017 FLS      Multiline record support added
********************************************************************************/
capture program drop genRates
program define genRates, rclass
version 13.0
syntax [iweight aweight pweight fweight] [if], ENDPoints(string) at(numlist) Origin(string) Enter(string) Scale(string) Per(string)  SAVing(string) [BY(string) id(string) append label(string)]
tempfile tmprate1 tmprate2
tempvar stopfup one
loc first 1
*if "`append'"=="" loc first 1
if "`id'"!="" loc id id(`id')
if "`by'"==""{
 loc by `one'
 gen `one'=1
}
foreach e in `endpoints'{
	if "`if'"!="" loc iff `if' & `e'EndDate<.
	if "`if'"=="" loc iff if `e'EndDate<.
    foreach t in `at'{
        $beginhide
        cap drop `stopfup'
        gen `stopfup' = `origin'+`t'*`scale'
        stset `e'EndDate `iff'  [`weight'`exp'] , failure(`e'Status) origin(`origin') enter(`enter') scale(`scale') exit(`stopfup') `id'
        strate `by', per(`per')  output(`tmprate1',replace)
        preserve
        use `tmprate1', clear
        gen Endpoint = "`e'"
        gen FUP = `t'
        qui{
            if `first'==0 append using `tmprate2'
            save `tmprate2', replace
        }
        restore
        loc first 0
        $endhide
    }
}
preserve
qui{
    use `tmprate2', clear
    gen analysis = "`label'"

 loc cmd gen strata =
* if "`append'"=="append" loc cmd replace strata =
    foreach v in `by'{
        tempvar n_`v'
        capture confirm numeric variable `v'
        if !_rc{
            cap decode `v', g(`n_`v'')
            if _rc!=0 cap tostring `v', g(`n_`v'')
        }
        else gen `n_`v'' = `v'
        loc cmd `cmd' `n_`v'' + " " +
        }
    `cmd' " "
    drop `by'
    if "`append'"!="" append using `saving'
    save `saving', replace
}
restore
end
