/* SVN header
$Date: 2022-05-25 09:37:33 +0200 (on, 25 maj 2022) $
$Revision: 450 $
$Author: fskFleSkj $
$Id: plotCuminc.ado 450 2022-05-25 07:37:33Z fskFleSkj $
*/
/********************************************************************************
                                        #+NAME        : plotCuminc.ado;
                                        #+TYPE        : Stata file;
                                        #+DESCRIPTION : Plot cumulative incidence values (risk)
                                        #+OUTPUT      :;
                                        #+AUTHOR      : Flemming Skj¿th;
                                        #+CHANGELOG   :Date       Initials Status:
                                                       28.06.2017 FLS      Created;
********************************************************************************/
capture program drop plotCuminc
program define plotCuminc, rclass
version 13.0
syntax anything [if], ENDPoints(string) [BY(string) Maxt(real 0) mint(real 0) lineopt(string) plotopt(string) plotopt2(string) title(string asis) sep(string) ///
savingpath(string) name(string) orglegend(string) /*[SCale(real 1)]*/ survival ci atrisk atrisktimes(string) atriskposx(real 0.2) atriskposy(real 0.1) ///
atriskopt(string) atriskcap(string) headlev(string) quietly fewdata(integer 5) noflatline savedata]
tokenize `anything'
loc CIstub `1'
tempvar firstflag lastflag first last time type byvar tmpcilo
tempfile locsave insave

if  "`sep'"=="" loc sep ,
if  "`savingpath'"=="" loc savingpath .
if  "`headlev'"=="" loc headlev **
if  "`atriskcap'"=="" loc atriskcap Numbers at risk
if  "`atriskopt'"=="" loc atriskopt size(medsmall)

if "`atrisk'"=="atrisk" loc atriskflag TRUE
if "`atriskflag'"=="TRUE"{
	if strpos(`"`plotopt'"',"margin")==0 loc plotopt `plotopt' graphregion(margin(l=25))
	if "`atrisktimes'"==""{
		dis " ERROR in call to plotCuminc, atrisktimes not provided but atrisktable requested"
		exit(1)
	}
}
qui save `insave', replace
if "`if'" != "" keep `if'
loc orgby `by'
if "`by'"!="" & strpos(`"`plotopt'"',"order")==0 {
        preserve
		loc bys
        tempvar catby byvar0
        sort `by'
	local wc = wordcount("`by'")
	foreach v of numlist 1/`wc' {
		tempvar byvar`v'
		local wd =word("`by'",`v')
		capture decode `wd', gen(`byvar`v'')
		if _rc != 0{
			generate `byvar`v'' = `wd'
		}
		local bys `bys' `byvar`v''
	}
	/*
	if wordcount("`by'")>1 egen `byvar0' = concat(`bys'), punct("-")
	else gen `byvar0' = `bys'
	*/
	egen `byvar0' = concat(`bys'), punct("-")
	loc byby by `byvar0' :
	*noi codebook `byvar'
	capture encode `byvar0', gen(`catby')

	if _rc==0 {
		drop `byvar0'
		rename `catby' `byvar0'

	}
        capture confirm numeric variable `byvar0'
        if !_rc {
			cap decode `byvar0', g(`catby')
			if _rc!=0 cap tostring `byvar0', g(`catby')
			}
        else gen `catby' = `byvar0'
	drop `byvar0'
        rename `catby' `byvar0'
	keep `byvar0'
	duplicates drop `byvar0', force
	levelsof `byvar0', local(levels)
 
	loc order order(
	count
	foreach  i of numlist 1/`r(N)'{
		 local lab = `byvar0'[`i']
		 loc order `order' `i' `"`lab'"'
	}
	loc order `order')
	if strpos(`"`plotopt'"',"legend(")>0{
	loc plotopt = subinstr(`plotopt',"legend(","legend(`order'",.)
	}
	else{
	loc plotopt `plotopt' legend(`order')
	}
	restore
}
	if "`by'"!=""{
			egen `byvar' = group(`by'), label missing
			loc by `byvar'
	}
	if "`by'"==""{
		gen `byvar'=1
		loc by `byvar'
	}
  qui  save `locsave', replace
	loc firste 1
	foreach e in `endpoints'{
    if `firste'==0 use `locsave', clear
		loc firste 0

    if "`title'"!=""{
        loc loctitle = substr("`title'",1,strpos("`title'`sep'","`sep'")-1)
        loc loctitle title("`loctitle'")
        loc title = substr("`title'",strpos("`title'","`sep'")+1,strlen("`title'"))
    }
    if "`plotopt2'"!=""{
        loc locplotopt = substr("`plotopt2'",1,strpos("`plotopt2'`sep'","`sep'")-1)
        loc plotopt2 = substr("`plotopt2'",strpos("`plotopt2'","`sep'")+1,strlen("`plotopt2'"))
    }
    dis "`headlev' Endpoint `e' " _n
    $beginhide
capture noisily{
    cap drop `time'
	gen `time'=`CIstub'`e'time
    *gen `time' = (`e'EndDate - $index)/`scale'
    sort `time'

    if `maxt'==0{
        loc maxt =`time'[_N]
    }
    if "`atriskflag'" == "TRUE"{
        summarize `CIstub'`e', meanonly
        loc maxy = r(max)
        loc calcatriskposy = -`atriskposy'*`maxy'
        loc calcatriskposx = -`atriskposx'*`maxt'
        levelsof `by', local(bylev)
        loc atrisk text(`calcatriskposy' `calcatriskposx'
                        if "`atriskcap'"!="" loc atrisk `atrisk' `"`atriskcap'"'
                        foreach b of local bylev{
                            loc head : label (`by') `b'
                            loc atrisk `atrisk' `"`head'"'
                        }
                        foreach t in `atrisktimes'{
                            loc atrisk `atrisk' `calcatriskposy' `t'
                            if "`atriskcap'"!="" loc atrisk `atrisk' `" "'
                            foreach b of local bylev{
                                qui count if `by'==`b' & `CIstub'`e'time>=`t' & !missing(`CIstub'`e'time)
                                loc atrisk `atrisk' `"`r(N)'"'
                            }
                        }
                        loc atrisk `atrisk', place(c) `atriskopt')
        loc note note(
            if "`atriskcap'"!="" loc note `note' " "
    }

    keep if `e'Status==1
    loc type 0
	preserve
	keep if `CIstub'`e'<.
    if `CIstub'`e'[1]>`CIstub'`e'[_N] loc type 1
	restore
    keep if `mint'<=`time' & `time'<=`maxt'
    bysort `by' (`time'): gen `first' = (_n==1)
    bysort `by' (`time'): gen `last' = (_n==_N)
    expand 2 if `first', gen(`firstflag')
    expand 2 if `last', gen(`lastflag')
    drop if `firstflag' & `lastflag'
    replace `time'=`mint' if `firstflag'
    replace `CIstub'`e'= `type' if `firstflag'
    replace `CIstub'`e'lo= `type' if `firstflag'
    replace `CIstub'`e'hi= `type' if `firstflag'
    if "`survival'"=="survival"{
        replace `CIstub'`e' = 1 - `CIstub'`e'
        gen `tmpcilo' = `CIstub'`e'lo
        replace `CIstub'`e'lo = 1 - `CIstub'`e'hi
        replace `CIstub'`e'hi = 1 - `tmpcilo'
        drop `tmpcilo'
    }
    if "`noflatline'"!="noflatline" replace `time' = `maxt' if `lastflag'
    duplicates drop `time' `CIstub'`e' `by', force
    sort `by' `time'
    loc ttxt = subinstr("`maxt'",".","-",.)
    loc plotl
    loc bounds
    if  "`lineopt'"!=""{
        loc lineoptst 1
        loc lineopt = "`lineopt'"+"`sep'"
        loc lineoptlen = strlen("`lineopt'")
    }
    levelsof `by', local(bylev)
    foreach b of local bylev{
        if "`lineopt'"!=""{
            loc lineoptend = strpos(substr("`lineopt'",`lineoptst',`lineoptlen'),"`sep'")
            loc loclineopt = substr("`lineopt'",`lineoptst',`lineoptend'-1)
            loc lineoptst = `lineoptst' + `lineoptend' + 1
        }
	if "`atriskflag'"=="TRUE" loc note `note' " "
        qui count if `by'==`b'
        if r(N)-2>=`fewdata'{
	   loc plotl `plotl' (line `CIstub'`e' `time' if `by'==`b', connect(stairstep) `loclineopt')
	   if "`ci'"=="ci" loc bounds `bounds' (rarea `CIstub'`e'lo `CIstub'`e'hi `time' if `by'==`b', ) /*til confidensintervaller*/
	}
	if r(N)-2<`fewdata' dis "WARNING: Plotcuminc, data hidden due to low number of events."   
    }
    if "`atriskflag'"=="TRUE" loc note `note' )
    }
   if "`quietly'"=="quietly" set graphics off
   if "`plotl'" == ""{
		dis "WARNING: Plotcuminc, no valid plot statement." 
		dis "file: (`name'`CIstub'`ttxt'`e'.(gph,png,pdf,eps) not created for some reason, perhaps missing events" _n
   }
   else {
	   twoway `bounds' `plotl', ///
		   `plotopt' `locplotopt' `loctitle' ///
			   `note' `atrisk' ///
			   saving("`savingpath'/`name'`CIstub'`ttxt'`e'.gph", replace) 
		`quietly' graph export "`savingpath'/`name'`CIstub'`ttxt'`e'.png", replace
		`quietly' graph export "`savingpath'/`name'`CIstub'`ttxt'`e'.pdf", replace
		`quietly' graph export "`savingpath'/`name'`CIstub'`ttxt'`e'.eps", replace
		if "`quietly'"=="quietly" set graphics on
		if "`savedata'"!=""{
			gen id = "`name'"
			replace `CIstub'`e'time= `time'
			keep id `orgby' `CIstub'`e'*
			duplicates drop
			qui save "`savingpath'/`name'`CIstub'`ttxt'`e'.dta", replace
		}
	   }   
$endhide
    dis "`orglegend'" _n

if _rc ==0{
    dis "[[./`name'`CIstub'`ttxt'`e'.eps]]" _n
    dis "file: (`name'`CIstub'`ttxt'`e'.(png,pdf,eps)" _n
    }
    else{
        dis "file: (`name'`CIstub'`ttxt'`e'.(gph,png,pdf,eps) not created for some reason, perhaps missing events" _n
    }
}
    use `insave', clear
end
