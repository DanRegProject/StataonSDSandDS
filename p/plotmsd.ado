cap  program drop plotmsd
program plotmsd,
syntax varlist(min=2 max=3) [if], using(string) ROWs(string) [rowlabels(string) labelopt(string) vref(string) legend(string asis) title(string) ]

* get current working dir
local cwd `"`c(pwd)'"'
preserve
qui{
    tempfile newusing
    use `using', clear
    if "`if'" != "" keep `if'
    save `newusing', replace
}
restore
preserve
qui{
if "`if'" != "" keep `if'
tokenize `varlist'
local rows2 = subinstr("`rows'"," ",",",.)
tempvar keepflag v1 name msdunw msdw iafter
gen `keepflag'=0
gen `v1'=trim(`1')
foreach i of local rows{
    replace `keepflag'=1 if `v1'=="`i'"
}
keep if `keepflag'==1
if "`3'" == ""{
    loc 3 `2'
    loc 2
    }
rename `3' `msdunw'
keep `1' `2' `v1' `msdunw'
merge 1:1 `1' `2' using `newusing', keepusing( `1' `2' `3')
keep if _merge==3
drop _merge
rename `3' `msdw'

keep if !missing(`msdunw')

gen `name' = `v1'
loc count=1
foreach i of local rows{
   if "`rowlabels'" != "" replace `name' = word("`rowlabels'",`count') if `v1'=="`i'"
   loc `++count'
}
replace `name' = subinstr(`name',"|"," ",.)
replace `name' = subinstr(`name',"(", "{",.)
replace `name' = subinstr(`name',")", "}",.)

sort `msdunw' `name'
gen `iafter' = _n
labmask `iafter', values(`name')

cap count
loc numbRows = `r(N)'

if "`legend'"=="" loc legend legend(label(1 "Unweighted") label(2 "Weighted") position(5) ring(0) col(1) size(small))
if "`labelopt'"=="" loc labelopt  angle(0) labsize(small)
if "`vref'"=="" loc vref -0.1 0.1
}
scatter `iafter' `msdunw', msymbol(o) mcolor(black) || ///
scatter `iafter' `msdw', msymbol(o) mcolor(black) mfcolor(white)   ||,   ///
  xline(0, lcolor(gs13) lpattern(solid)) xline(`vref', lcolor(gs13) lpattern(dash)) yline(1/`numbRows', lcolor(gs13)) scheme(s1mono) ///
  xlabel(,format(%03.1f) `labelopt') ///
  ylabel(1/`numbRows', valuelabel `labelopt') ///
  ytitle("") scale(1) title(`title') ///
  `legend'

restore
end
