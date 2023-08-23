* ereturn for getting NRI-statistics given up/down-reclassifications and 
program define _nriboot, eclass
	syntax anything [if] [in]
	version 11
	
	marksample touse
	tokenize `anything'
	
	* pv: pseudovalues; up: up-reclassifications (=1); down: down-reclassifications (=1)
	local pv `1'
	local up `2'
	local down `3'

	* P(up)
	tempname bb
	su `up'
	local b=`r(mean)'

	* Probabilities of up/down relcassification
	regress `pv' `up' `down', nocons

	* P(event)
	lincom `b' * _b["`up'"] + `=1-`b'' * _b["`down'"]
	local Pevent = r(estimate)

	* P(event|up) * P(up)
	lincom `b' * _b["`up'"]
	local p1 = `=r(estimate)/`Pevent''
	* P(event|down) * P(down)
	lincom `=1-`b'' * _b["`down'"]
	local p2 = `=r(estimate)/`Pevent''
	* P(non-event|down) * P(down)
	lincom `=1-`b'' * (1-_b["`down'"]) 
	local p3 = `=r(estimate)/(1-`Pevent')'
	* P(non-event|up) * P(up)
	lincom `b' * (1-_b["`up'"])
	local p4 = `=r(estimate)/(1-`Pevent')'
	* NRI for cases
	local nriplus = (`p1'-`p2')
	* NRI for non-cases
	local nriminus = (`p3'-`p4')

	matrix `bb' = (`p1',`p4',`p2',`p3',`nriplus',`nriminus',`nriplus'+`nriminus')

	matrix colnames `bb' = upI+ upI- downI+ downI- NRI+ NRI- NRI
	ereturn post `bb', esample(`touse')
end


