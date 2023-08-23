capture program drop reportData
program define reportData, rclass
version 13.0

syntax anything, [if(string) using(string) by(string) format(string) sorting(string) headings(string)]
tempvar  byvar catby
loc varlist `anything'
if "`using'"!=""{
		tempfile store
		qui save `store', replace
		use `using', clear
}
if "`if'"!="" keep if `if'
if "`by'`sorting'"!="" sort `by' `sorting'
qui{
	loc bys
	if "`by'"!=""{
		loc wc = wordcount("`by'")
		foreach v of numlist 1/`wc'{
			tempvar byvar`v'
			loc wd = word("`by'",`v')
			capture decode `wd', gen(`byvar`v'')
			if _rc != 0{
				gen `byvar`v'' = `wd'
			}
			loc bys `bys' `byvar`v''
		}
		if `wc'>1 egen `byvar' = concat(`bys'), punct("-")
		else gen `byvar'=`bys'
		loc byby by `byvar'
		cap encode `byvar', gen(`catby')
		if _rc == 0{
			drop `byvar'
			rename `catby' `byvar'
		}
		cap confirm numeric variable `byvar'
		if !_rc{
			cap decode `byvar', g(`catby')
			if _rc != 0 cap tostring `byvar'. g(`catby')
		}
		else gen `catby'=`byvar'
		drop `byvar'
		rename `catby' `byvar'
	}
	else {
		gen `byvar'="1"
	}
}

qui{
	count
	loc N=r(N)
	loc shift 1
	loc wcv = wordcount("`varlist'")
	loc wch = wordcount("`headings'")
}
	if `wch'!=0 & `wcv'!=`wch' dis "Number of variables in varlist does not match heading labels"
	
qui{
	loc head
	loc head2 | 
	if "`varlist'"!="" loc head = subinstr("`varlist'"," "," | ",.)
	if "`heading'"!="" loc head = subinstr("`heading'"," "," | ",.)
	foreach i of numlist 2/`wcv'{
		loc head2 `head2'-+
	}
	loc head2 `head2'-|
	levelsof `byvar', local(levels)
	
}
foreach byval in `levels'{
	dis "" _n(2)
	if "`by'"!="" dis "`by' : `byval' "
	dis "| `head' |"
	dis "`head2'"
	preserve
	qui if "`by'"!="" keep if `byvar'=="`byval'"
	qui count
	loc N=r(N)
	foreach l of numlist 1/`N'{
		foreach i of numlist 1/`wcv'{
			loc var = word("`varlist'", `i')
			loc fmt
			if strpos("`format'","`var'")>0{
				loc subformat = substr("`format'",strpos("`format'","`var'"),.)
				loc fmt = substr("`subformat'",length("`var'")+2,strpos("`subformat'",")")-length("`var'")-2)
			}
			dis "| " `fmt' `var'[`l'] " ", _c
		}
		dis "|"
	}
	restore
}
if "`using'"!=""{
	use `store', clear
}
end
