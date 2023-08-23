program define _idiboot, eclass
	version 11
	syntax anything
	marksample touse
	tokenize `anything'
	tempname bb
	regress `1' `2'
	local x1 =  e(r2)
	regress `1' `3'
	local x2 =  e(r2)
	matrix `bb' = `x2'-`x1'
	matrix colnames `bb' = IDI
	ereturn post `bb', esample(`touse')
end
