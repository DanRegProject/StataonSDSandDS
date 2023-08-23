*****************************************************************************
* stcuminc
*
* Fast cumulative incidence pseudovalues based on the  redistribute-to-the-right 
* representation of the Aalen-Johansen estimator
*
* Author: 	Anders Gorst-Rasmussen, Aalborg University Hospital, Aalborg University
*         	Email: agorstras@gmail.com
* 
* Version history:
*			:: 0.9 (10Feb2014)
*****************************************************************************
program stpcuminc, eclass
	version 11
	st_is 2 analysis

	syntax varlist(min=1 max=1 numeric)  [if] [in] , At(numlist>=0 min=1 ascending)  [Generate(string)]

	* Mark sample
	marksample touse
	quietly replace `touse' = 0 if _st==0

	* Check if some event time are left truncated.
	quietly sum _t0 if(`touse')
	local max=r(max)
	if(`max'>0) {
		display as error "The function does not support left truncated event times."
		exit
	}
	
	* No support for weights
	local w: char _dta[st_wv]
	if("`w'" != "") {
	   display as error "The function does not support weighted data"
	}

	* Defining and checking tmax.
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
		g `w'=`fw'
	}
	else {
		g `w'=1
	}
	g `d'=0*(_d==0 & `compvar'!=1)+1*(_d==1)+2*(_d==0 & `compvar'==1)
	
	local name="pseudo"	
	if(`"`generate'"'!="") {
		local name="`generate'"
	} 
	
	local n: word count `tmax'
	if(`n'>1) {
	forvalues i = 1/`n' {
		* Non-mata error message if variable exists
		capture confirm variable `name'`i' 
		if(!_rc) {
			di as err "variable `name'`i' exists"
			exit 110
		}
		 mata: mata_pseudoci("_t","`d'","`touse'","`: word `i' of `tmax''","`name'`i'")
	}
	} 
	else {
		capture confirm variable `name'
		if(!_rc) {
			di as err "variable `name'`i' exists"
			exit 110
		}
		mata: mata_pseudoci("_t","`d'","`touse'","`: word 1 of `tmax''","`name'")
	}

end

version  11
mata:
real matrix mata_pseudocigetIx(real vector x) {
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


void mata_pseudoci(string  scalar  tname,  string  scalar  dname, string scalar tousename,string tmaxname,string scalar var)
{
	tmax=strtoreal(tokens(tmaxname))
	ntmax=length(tmax)
	touse=st_data(., tousename)
	
	d = st_data(.,  tname+" "+dname,tousename) 	/* Get data, sort according to time */
	
	nRisk0 = rows(d)
	sortOrder = order(d,(1,-2)) 	/* Save sort order for matching back later */
	d = d[sortOrder, .]
	tmp = mata_pseudocigetIx(d[.,1])
	key = tmp[.,1] /* To get jump times*/
	grp = tmp[.,2] /* Key for matching w/unique event times*/

	keepIx = d[.,1] :<= tmax[1] /* We only need values up to tmax */
	
	jump = uniqrows(select(key,keepIx)):+1 /* Index of jump times */
	N = length(jump)
	jumpIx = (jump , (1 \ jump[1..length(jump)-1])) /* For extracting #events between jumps*/

	/* Cumulative event count + at-risk count */
	event = (0,0,0 \ (runningsum( select(d[.,2]:==0,keepIx)),runningsum( select(d[.,2]:==1,keepIx)),runningsum( select(d[.,2]:==2,keepIx))))
	cumEvent = event[jumpIx[.,1],.] - event[jumpIx[.,2],.]
	nRisk = (nRisk0..0)'[jumpIx[.,1]]
  
	/* Multiplier for orig/LOO of Gooley et al. 1999  CI representation */
	J = J(length(nRisk)+1,1,1)
	Jloo = J(length(nRisk)+1,1,1)
	for(i=2; i <= length(nRisk)+1; i++) {
		J[i] = J[i-1] * (1+cumEvent[i-1,1] / nRisk[i-1,1]) 
    	Jloo[i] = Jloo[i-1] * (1+cumEvent[i-1,1] / (nRisk[i-1,1] - 1)) 
	}
	J = J :/ nRisk0 
	Jloo = Jloo :/ (nRisk0-1)

	/* Cum. incidence/pre-cumulative incidence for orig/LOO CI */
	cuminc = runningsum(J[1..length(J)-1] :* cumEvent[.,2])
	cumincLoo = runningsum(Jloo[1..length(Jloo)-1] :* cumEvent[.,2])

	/* Placeholder for pseudovalues (col1: if dead; col2: if censored; col3: if competing) */
	Y = J(max(grp),3,cumincLoo[N])

	/* The updating formulas, vectorized */
	tmp = (0 \ cumincLoo[1..(N-1)]) :+ Jloo[1..N] :* cumEvent[.,2] + Jloo[1..N] :* (1 :+ cumEvent[,1] :/ nRisk) :* (cuminc[N] :- cuminc) :/ J[2..length(J)]
	Y[1..N,1] = tmp - Jloo[1..N]
	Y[1..N,2] = tmp - Jloo[1..N] :* (cuminc[N] :- cuminc) :/ J[2..length(J)] :/ nRisk
	Y[1..N,3] = tmp

	Y = rows(d) * cuminc[N] :- (rows(d) - 1)  :* Y

	out = (d[.,2]:==1) :* Y[grp,1]+ (d[.,2]:==0) :* Y[grp,2] + (d[.,2]:==2) :* Y[grp,3]

	/* Rever to original size/order */
	out = out[order(sortOrder,1),.]

	/* Save results */
	ids=st_addvar("double",var)
	st_varlabel(ids,"Pseudovalue at time "+strofreal(tmax[1]))
	st_store(.,ids,tousename,out)
	stata(`"disp as result "Generated pseudo variable: "'+var+`"""')
}

end
