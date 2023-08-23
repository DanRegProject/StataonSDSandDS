/* SVN header
$Date: 2019-01-08 10:46:22 +0100 (ti, 08 jan 2019) $
$Revision: 136 $
$Author: wnm6683 $
$Id: stsplitPeriods.ado 136 2019-01-08 09:46:22Z wnm6683 $
*/
/* stsplitPeriods.ado */
capture program drop stsplitPeriods
program define stsplitPeriods, rclass
version 13.0
noisily quietly:{
    syntax anything [if], using(string) split(string) splitstart(string) splitend(string) ///
        [datestub(string) statusstub(string) saving(string asis)]
    tokenize `anything'
    local id `1'
    local startdate `2'
    macro shift 2
    local endpoints `*'
    tempfile startdata dat0 dat1
    if ("`saving'" != "") save `startdata', replace
    tempvar  lastend newid splitbefore splitduring splitafter _splitend _splitstart ///
        N n block nextstart dat0flag _split
    if ("`datestub'"=="") local datestub EndDate
    if ("`statusstub'"=="") local statusstub Status
    if "`if'"!="" keep `if'

    preserve
    use `using', replace
    if "`if'"!="" keep `if'
    cap encode `split', g(`_split')
    if _rc==0{
        drop `split'
        rename `_split' `split'
    }
    keep `id' `split' `splitstart' `splitend'
    rename `splitstart' `_splitstart'
    rename `splitend' `_splitend'
    duplicates drop
    save `dat1', replace
    restore
    gen `newid' = `id' + strofreal(_n)
    /* Cartesian join */
    joinby `id' using `dat1', unmatched(master)
    * bysort `id': drop if `_splitend'<`startdate' & _merge==3 & _N>1 & _n!=_N
    drop _merge
    replace `_splitstart'=0 if missing(`_splitstart')
    replace `_splitstart'=0 if `_splitend'<`startdate'
    replace `split'=.       if `_splitend'<`startdate'
    replace `_splitend'=.   if `_splitend'<`startdate'
    gen `lastend'=0
    foreach i of local endpoints{
        replace `lastend' =`i'`datestub' if !missing(`i'`datestub') & `i'`datestub'>`lastend'
    }
    format `lastend' `_splitstart' `_splitend' %d
    preserve
    bysort `newid': keep if `startdate'>`lastend' & _N==1
    gen `dat0flag'=1
    save `dat0', replace
    restore
    sort `newid' `startdate' `_splitend'
    bysort `newid': drop if `_splitend'<`startdate' & _N!=_n
    bysort `newid': drop if `_splitstart'>=`lastend' & _n>1
    bysort `newid': drop if `_splitstart'==0 & missing(`_splitend') & _n>1
    gen `splitbefore'=(`_splitend'<`startdate')
    gen `splitduring'=(`_splitstart'<=`startdate' & `startdate'<=`_splitend' & !missing(`_splitend'))
    gen `splitafter'=(`_splitstart'>`startdate' & `_splitstart'<`lastend')
    /* hvis perioden er før startdate */
    replace `_splitstart'=. if `splitduring'==0 & `splitafter'==0 & `splitbefore'==1
    replace `_splitend'=.   if `splitduring'==0 & `splitafter'==0 & `splitbefore'==1
    replace `split'=0       if `splitduring'==0 & `splitafter'==0 & `splitbefore'==1
    replace `splitduring'=2 if `splitafter'==1
    replace `splitduring'=3 if `splitbefore'==1
    keep if `splitduring'==0 | `splitduring'==3 | `_splitstart'<`lastend'
    sort `newid' `splitduring' `_splitstart' `startdate'
    duplicates drop  `newid' `_splitstart' `_splitend' `startdate', force
    sort `newid' `startdate' `_splitstart'
    bysort `newid': gen `N'=_N
    bysort `newid': gen `n'=_n
    preserve
    replace `startdate' = `_splitstart'+1 if `splitduring'==2 & `_splitstart'<`lastend'
    replace `startdate' = `startdate'+1 if `splitduring'==1
    foreach i of local endpoints{
        replace `i'`statusstub'=0         if `i'`datestub'>`_splitend' & `split'>0 & !missing(`split') & !missing(`i'`datestub')
        replace `i'`datestub'=`_splitend' if `i'`datestub'>`_splitend' & `split'>0 & !missing(`split') & !missing(`i'`datestub')
    }
    gen `block'=1
    /* Dermed har vi alle behandlingsperioder */
    drop if `_splitstart'>=`lastend'
    save `dat1', replace
    restore
    /* Herefter mangler vi alle mellemperioder uden behandling */
    keep if `split'>0 & !missing(`split')
    preserve
    /* dan ubehandlet før første behandling */
    keep if `n'==1 & `_splitstart'>`startdate'
    replace `split'=0
/* not in use due to previous line
    foreach i of local endpoints{
        replace `i'`statusstub'=0         if `i'`datestub'>`_splitend' & `split'>0 & !missing(`split') & !missing(`i'`datestub')
        replace `i'`datestub'=`_splitend' if `i'`datestub'>`_splitend' & `split'>0 & !missing(`split') & !missing(`i'`datestub')
    }
*/
    foreach i of local endpoints{
        replace `i'`statusstub'=0             if `i'`datestub'>`_splitstart' & !missing(`i'`datestub')
        *replace `i'`datestub'=`_splitstart'-1 if `i'`datestub'>=`_splitstart' & !missing(`i'`datestub')
        replace `i'`datestub'=`_splitstart' if `i'`datestub'>=`_splitstart' & !missing(`i'`datestub')
		}
    gen `block'=2
    replace `splitduring'=0
    append using `dat1'
    save `dat1', replace
    restore
    preserve
    /* Dan ubehandlet efter sidste behandling*/
    keep if `n'==`N' & `_splitend'<`lastend'
    replace `startdate'=`_splitend'+1
    replace `split'=0
    gen `block'=3
    append using `dat1'
    save `dat1', replace
    restore
    /* dan behandlingsfri perioder mellem behandlingsperioder */
    keep if `N'>1
    replace `split'=0
    gen `nextstart'=.
    by `newid': replace `nextstart'=`_splitstart'[_n+1]
    keep if !missing(`nextstart') & `nextstart' != `_splitend'+1
    by `newid': replace `startdate' = `_splitend'+1
    foreach i of local endpoints{
        replace `i'`statusstub'=0         if `i'`datestub'>`nextstart' & !missing(`i'`datestub')
        replace `i'`datestub'=`nextstart' if `i'`datestub'>`nextstart' & !missing(`i'`datestub')
    }
    gen `block'=4
    append using `dat1'
    replace `block'=0
    foreach i of local endpoints{
        replace `i'`datestub'=.   if `i'`datestub'<`startdate'
        replace `i'`statusstub'=. if missing(`i'`datestub')
        replace `block'=1         if !missing(`i'`datestub')
    }
    replace `_splitstart'=. if `_splitstart'==0
    replace `split'=0 if missing(`split')
    drop if `block'==0
    append using `dat0'
    sort `id' `startdate'
    by `id': replace `startdate'=`startdate'-1 if (_n>1 | `splitduring'==1) & `dat0flag'==. & `splitduring'!=0
    sort `id' `startdate'

    drop `lastend' `newid' `splitbefore' `splitduring' `splitafter' `_splitend' `_splitstart' ///
        `N' `n' `block' `nextstart' `dat0flag'
    if "`saving'"!=""{
        save `saving'
        use `startdata', clear
    }
}
end
