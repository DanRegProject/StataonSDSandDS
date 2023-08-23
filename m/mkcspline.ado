cap program drop mkcspline
program define mkcspline
version 13
gettoken name 0 : 0, parse(" =")
gettoken eqsign : 0, parse(" =")
gettoken var 0 : 0, parse(" =")
syntax varname , NKnots(numlist max=1) Center(numlist max=1)
tempvar c
tempname Rmat
rcsgen `varlist', gen(`name') orthog df(`nknots')
matrix `Rmat'=r(R)
local knotsage `r(knots)'
rcsgen , scalar(`center') rmatrix(`Rmat') gen(`c') knots(`knotsage')
forvalues i=1/`nknots'{
    replace `name'`i'= `name'`i'-`c'`i'
}
end
