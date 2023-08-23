*****************************************************************************
* stcuminc
*
* Fast cumulative incidence calculations based on the 
* redistribute-to-the-right representation of the Aalen-Johansen estimator
*
* Author: 	Anders Gorst-Rasmussen, Aalborg University Hospital, Aalborg University
*         	Email: agorstras@gmail.com
* 
* Version history:
*			:: 0.9 (10Feb2014). 
*****************************************************************************
program stcuminc, eclass
	version 11
	st_is 2 analysis
	* Replay hack - get results from bootstrap
 	if replay() {
     if ("`e(cmd)'" != "stcuminc") error 301
     if ("`e(cmd)'" == "stcuminc" & "`e(prefix)'" == "bootstrap") {
 	    ereturn di
     }
    }
    else    {
	syntax varlist(min=1 max=1 numeric) [if] [in] , [At(numlist>=0 min=1 ascending)  Generate(string)]
	
	* Mark sample
	marksample touse
	quietly replace `touse' = 0 if _st==0
	
	* Check for obs
	qui su `touse'
	local nobs=`r(sum)'
	if(`nobs'==0){
		di as err "No observations"
	exit
	}
	
    * Need one of At or Generate
    if("`at'"=="" & "`generate'"=="") {
		display as error "At least one of the options 'at()' or 'generate()' must be specified"
	   exit
    }
	* No support for weights
	local w: char _dta[st_wv]
	if("`w'" != "") {
	   display as error "The function does not support weighted data"
	   exit
	}

	* Check if some event times are left truncated.
	quietly sum _t0 if(`touse')
	local max=r(max)
	if(`max'>0) {
		display as error "The function does not support left truncated event times."
		exit
	}

	* Defining and checking tmax.
		if("`at'"!="") {
		
	quietly sum _t if(`touse')
	local max=r(max)
	foreach time of numlist `at' {
		if(`time'>`max') {
			display as error "The time point `time' is greater than the largest event time."
			exit
		}
	}
	
	numlist "`at'"
	local tmax=r(numlist)
	}

	* Checking the variable containing competing risk events.
	tempvar compvar
	quietly gen `compvar'=`varlist'==1
	
	capture confirm numeric variable `compvar'
	if(_rc) {
	 	display as error "The competing risk variable `compet' is not numeric."
	 	exit
	}
	quietly count if( `compvar'==1 & _d==1 )
	local count=r(N)
	if(`count'>0) {
		display as error "The competing risk variable marks events as being competing risk."
		exit
	}

	tempname w d
	if(`"`fw'"'!="") {
		gen `w'=`fw'
	}
	else {
		gen `w'=1
	}
	g `d'=0*(_d==0 & `compvar'!=1)+1*(_d==1)+2*(_d==0 & `compvar'==1)
	
	if(`"`generate'"'!="") {
		local name="`generate'"
	} 

	tempname b
	mata: mata_cuminc("_t","`d'","`touse'","`tmax'","`name'","`b'")
	
	if("`at'"!="") {
		tempname t	
		matrix `t'=`: subinstr local tmax " " ",", all'	
		matrix colnames `b' = `=subinstr("`:colnames `b''","c","t",.)'
		matrix colnames `t' = `:colnames `b''
	
		di _n as txt " Number of obs =" as res %6.0f `nobs'
		di  as txt "{hline 12}{c TT}{hline 15}" 
		di as txt _col(7) "Time" _col(13) "{c |}     Coef.   " 
		di  as txt "{hline 12}{c +}{hline 15}" 
		forvalues j = 1 / `=colsof(`b')' {
			di as txt %11.4f `t'[1,`j'] _col(13) "{c |}" as res %10.5f `b'[1,`j']
			}
		di as txt "{hline 12}{c BT}{hline 15}"
		ereturn post `b', esample(`touse')   obs(`nobs')
		ereturn matrix time=`t'
	}
	else {
		ereturn post, esample(`touse')  obs(`nobs')
	}
    ereturn local cmd "stcuminc"
}
end

version  11
mata:
real matrix mata_cumincgetIx(real vector x) {
    /* For input x sorted in ascending order 
	   return cbind(z,w) with:
			z[i]  the largest index j s.t. x[i]==x[j]
			w[i]  group identifier 1,2,... 
	*/
    tmp = x[2..length(x)] :!= x[1..(length(x)-1)]
    L = (tmp \ 1)
    M = (1 \ tmp)
    y = (0 \ select((1..length(L))',L)[sum(L)..1])
    z = y[runningsum(L[length(L)..1]):+1]
    return( ( z[length(z)..1], runningsum(M)  ))
}

void mata_cuminc(string  scalar  tname,  string  scalar  dname, string scalar tousename,string tmaxname,string scalar var,string scalar outname)
{
	tmax = strtoreal(tokens(tmaxname))
	ntmax = length(tmax)
	
	/* Get data, sort according to time */
	d=st_data(.,  tname+" "+dname,tousename)
	
	nRisk0 = rows(d)
	sortOrder = order(d,(1,-2))
	d = d[sortOrder, .]
	tmp = mata_cumincgetIx(d[.,1])
	key = tmp[.,1]
	grp = tmp[.,2]
		
	jump = uniqrows(key):+1
	jumpIx = (jump , (1 \ jump[1..length(jump)-1]))

	event = (0,0,0 \ (runningsum(d[.,2]:==0),runningsum(d[.,2]:==1),runningsum(d[.,2]:==2)))
	cumEvent = event[jumpIx[.,1],.] - event[jumpIx[.,2],.]
	nRisk = (nRisk0..0)'[jumpIx[.,1]]

	J = J(length(nRisk)+1,1,1)
	for(i=2; i <= length(nRisk)+1; i++) {
		J[i] = J[i-1] * (1+cumEvent[i-1,1] / nRisk[i-1,1]) 
	}
	J = J :/ nRisk0 
			
	out = runningsum(J[1..length(J)-1] :* cumEvent[.,2])
	
	/* Get cuminc at requested times */
	if(ntmax) {
	    citottmax=J(1,ntmax,0)
		t = d[jumpIx[,2],1]
		for(i=1; i<=ntmax; i++) {
			citottmax[i]=max(select(out,(t:<=tmax[i])))
			if(citottmax[i]==.) citottmax[i]=0
			if(var != "") {
				tmp = J(length(grp),1,citottmax[i])
				cnt = ntmax>1 ? strofreal(i) : ""
				ids=st_addvar("double",var+cnt)
				st_varlabel(ids,"Cumulative incidence at "+strofreal(tmax[i]))
				st_store(.,ids,tousename,tmp)
			}
		}
		st_matrix(outname,citottmax)
	}
	else {
	if(var != "") {
		out = out[grp]
		out=out[order(sortOrder,1),.]
		ids=st_addvar("double",var)
		st_varlabel(ids,"Cumulative incidence at _t")
		st_store(.,ids,tousename,out)
	}
   }
}
end
