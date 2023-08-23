* ereturn for getting NRI-statistics given up/down-reclassifications
* log 20/12/16                      :: corrected to allow categorical with non-changed scores

cap program drop _nriboot
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

* P(down)
	su `down'
	local c=`r(mean)'
local d=1-`b'-`c'
dis "p(up)=`b' p(down)=`c' p(equal)=`d'"

	* Probabilities of up/down reclassification
	regress `pv' `up' `down'

	* P(event) = P(event|up)*P(up) + P(event|down)*P(down)
*	lincom `b' * _b[_cons]+ `b' *_b["`up'"] + `c' * _b[_cons]+ `c' *_b["`down'"] + `d'*_b[_cons]
	lincom  `b' *_b["`up'"] + `c' *_b["`down'"] + _b[_cons]
	local Pevent = r(estimate)
dis "p(event) =`Pevent'"
dis "P(event|up)= " _b["`up'"]+_b[_cons]  "P(event|down)= " _b["`down'"]+_b[_cons]
	* P(Up|event) = P(event|up) * P(up)/P(event)
	lincom `b' *( _b["`up'"]+_b[_cons])
	local p1 = `=r(estimate)/`Pevent''
	* P(down|event) = P(event|down) * P(down)/P(event)
	lincom `c' * (_b["`down'"]+_b[_cons])
	local p2 = `=r(estimate)/`Pevent''
	* P(down|non-event) = P(non-event|down) * P(down) / P(non-event)
	lincom `c' * (1-_b["`down'"]-_b[_cons])
	local p3 = `=r(estimate)/(1-`Pevent')'
	* P(up|non-event) = P(non-event|up) * P(up) / P(non-event)
	lincom `b' * (1-_b["`up'"]-_b[_cons])
	local p4 = `=r(estimate)/(1-`Pevent')'
	* NRI for cases
	local nriplus = (`p1'-`p2')
	* NRI for non-cases
	local nriminus = (`p3'-`p4')

	matrix `bb' = (`p1',`p4',`p2',`p3',`nriplus',`nriminus',`nriplus'+`nriminus', _b["`up'"]+_b[_cons],_b["`down'"]+_b[_cons])

	matrix colnames `bb' = upI+ upI- downI+ downI- NRI+ NRI- NRI PEup PEdown
	ereturn post `bb', esample(`touse')
end


