/* SVN header
$Date: 2022-03-23 10:53:41 +0100 (on, 23 mar 2022) $
$Revision: 445 $
$Author: fskFleSkj $
$Id: genCuminc.ado 445 2022-03-23 09:53:41Z fskFleSkj $
*/
/********************************************************************************
                                        #+NAME        : genCuminc.ado;
                                        #+TYPE        : Stata file;
                                        #+DESCRIPTION : Generate cumulative incidence values (risk)
                                        #+OUTPUT      :;
                                        #+AUTHOR      : Flemming Skjøth;
                                        #+CHANGELOG   :Date       Initials Status:
                                                       28.06.2017 FLS      Created;
                                                       07.08.2017 FLS      Multiline record support added
********************************************************************************/
capture program drop genCuminc
program define genCuminc, rclass
version 13.0
syntax anything [iweight aweight pweight fweight], ENDPoints(string) Origin(string) Enter(string) Scale(string) type(string) [BY(string) compete(string) id(string) endtime(string)]
tokenize `anything'
loc CIstub `1'
tempvar index tmpcilo
tempvar status eEndDate eStatus
tempvar byvar
qui{
    if "`id'"!="" loc id id(`id')
    if "`by'"!=""{
        tempvar byvar
        egen `byvar' = group(`by'), missing
        loc by by(`byvar')
    }
    if "`endtime'"!=""{
        tempvar stopfup
        loc exit exit(`stopfup')
        gen `stopfup' = `origin'+`endtime'*`scale'
    }
    foreach e in `endpoints'{
        $beginhide
        cap drop `CIstub'`e' `CIstub'`e'time `CIstub'`e'lo `CIstub'`e'hi
        cap drop `eEndDate' `eStatus'
        gen `eEndDate' = `e'EndDate
        gen `eStatus' = `e'Status
        if lower("`type'")=="cox"{
            tempvar xbeta stdp surv
            stset `eEndDate' [`weight'`exp'] if !missing(`eStatus'), failure(`eStatus') origin(`origin') enter(`enter') scale(`scale') `id' `exit'
            gen `CIstub'`e'time=_t
            stcox i.`byvar'
            predict double `surv', basesurv
            predict double `xbeta', xb
            predict double `stdp', stdp
            gen `CIstub'`e' = 1-`surv'^exp(`xbeta')
            gen `CIstub'`e'hi = 1-`surv'^exp(`xbeta'-`stdp')
            gen `CIstub'`e'lo = 1-`surv'^exp(`xbeta'+`stdp')
        }
        if lower("`type'")=="km"{
            stset `eEndDate' [`weight'`exp'] if !missing(`eStatus'), failure(`eStatus') origin(`origin') enter(`enter') scale(`scale') `id' `exit'
            gen `CIstub'`e'time=_t
            if "`weight'"=="" loc ci `CIstub'`e'lo = lb `CIstub'`e'hi = ub
            sts gen `CIstub'`e' = s `ci', `by'
	    replace `CIstub'`e' = 1 - `CIstub'`e'
            if "`weight'"==""{
                gen `tmpcilo' = `CIstub'`e'lo
                replace `CIstub'`e'lo = 1 - `CIstub'`e'hi
                replace `CIstub'`e'hi = 1 - `tmpcilo'
                drop `tmpcilo'
            }
            if "`weight'"!=""{
                gen `CIstub'`e'lo = .
                gen `CIstub'`e'hi = .
            }
        }
        if lower("`type'")=="stcompet" & "`compete'"!=""{
            cap drop `status'
            gen `status' = `eStatus'
            foreach c in `compete'{
                replace `eStatus'=90 if `c'Status & `c'EndDate<`eEndDate'
				replace `eStatus'=90 if `c'Status & `c'EndDate==`eEndDate' &  `eStatus'==0
                replace `eEndDate'=`c'EndDate if `c'Status & `c'EndDate<`eEndDate'
            }
            stset `eEndDate' [`weight'`exp'] if !missing(`eStatus'), failure(`eStatus'==1) origin(`origin') enter(`enter') scale(`scale') `id'
            gen `CIstub'`e'time=_t
            if "`weight'"=="" loc ci `CIstub'`e'lo = lo `CIstub'`e'hi = hi
            stcompet `CIstub'`e'=ci  `ci', compet(90) `by'
            if "`weight'"!=""{
                gen `CIstub'`e'lo = .
                gen `CIstub'`e'hi = .
            }
            replace `CIstub'`e'=. if `eStatus' != 1
            replace `CIstub'`e'lo=. if `eStatus' != 1
            replace `CIstub'`e'hi=. if `eStatus' != 1
        }
        if lower("`type'")=="stcuminc" & "`compete'"!=""{
            if "`by'"!=""{
                levelsof `byvar', missing
                local byvalue "`r(levels)'"
            }
            if "`by'"==""{
                local byvalue 0
                cap drop `byvar'
                gen `byvar'=0
            }
            tempvar order
            gen `order'=_n
            tempfile mydata store
            loc first 1
            save `store', replace
            foreach X of local byvalue{
                use `store', clear
                keep if `byvar'==`X'
*                cap drop `status'
                tempvar compet
*                gen `status' = `eStatus'
                gen `compet' = 0
            loc ncomp 1
            foreach cv in `compete'{
                replace `compet'=`ncomp' if  `cv'EndDate<`eEndDate' & `cv'Status==1
                replace `compet'=`ncomp' if  `cv'EndDate==`eEndDate' & `cv'Status==1 & `eStatus'==0
                replace `eStatus'=0 if `compet'==`ncomp' & `cv'EndDate<`eEndDate' & `cv'Status==1
                replace `eEndDate'=`cv'EndDate if `compet'==`ncomp' & `cv'EndDate<`eEndDate' & `cv'Status==1
                * loc ncomp = `ncomp' + 1
            }
/*                foreach c in `compete'{
                    replace `compet'=1 if `c'Status & `c'EndDate<`eEndDate'
                }
*/
    stset `eEndDate' [`weight'`exp'] if !missing(`eStatus'), failure(`eStatus'==1) origin(`origin') enter(`enter') scale(`scale') `id'
                gen `CIstub'`e'time=_t
                stcuminc `compet', generate(`CIstub'`e')
                gen `CIstub'`e'lo = .
                gen `CIstub'`e'hi = .
                replace `CIstub'`e'=. if `eStatus' != 1
                if `first'==0 append using `mydata'
                loc first 0
                save `mydata', replace
            }
            sort `order'
        }
        $endhide
    }
}
end
