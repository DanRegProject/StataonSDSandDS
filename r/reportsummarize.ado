


capture program drop reportSummarize
program define reportSummarize, rclass
version 13.0

syntax [if], varlist(string) [by(string) percentile]
qui{

	loc dropafter FALSE
	if "`by'" == "" {
		generate level = 1
		loc by level
		loc dropafter TRUE
	}

	
	levelsof `by' , local(levels)
	
	loc num = 1
	foreach i in `varlist'{
		foreach j in `levels'{
			summarize `i' if `by' == `j', detail
			loc row`num' "|" "`i'" "|" "`j'" "|" "`r(N)'" "|" round(`r(mean)',0.001) "|" round(`r(sd)',0.001) "|" round(`r(min)',0.001) "|" round(`r(max)',0.001) "|" 
			loc row1`num' "|" "`i'" "|" "`j'" "|" round(`r(p10)',0.001) "|" round(`r(p25)',0.001) "|" round(`r(p50)',0.001) "|" round(`r(p75)',0.001) "|" round(`r(p90)',0.001) "|"
			
			if `r(N)' < 4{
			loc row`num' "|" "`i'" "|" "`j'" "|" "-" "|" "-" "|" "-" "|" "-" "|" "-" "|" 	
			}
			loc num = `num' + 1
		}
	}
	
	if "`dropafter'" == "TRUE"{
		drop level
	}
}


dis "|  Variable  | `by' | Obs | Mean | Std. Dev. | Min | Max |"
dis "|------------|------|-----|------|-----------|-----|-----|"
foreach j of numlist 1/`num'{
	dis "`row`j''"
}

if "`percentile'" != ""{
	dis "|  Variable  | `by' | 10% | 25% | 50% | 75% | 90% |"
	dis "|------------|------|-----|------|-----------|-----|-----|"
	foreach j of numlist 1/`num'{
		dis "`row1`j''"
	}
}


end
