*! version 1.3.0  04apr2017
program mnps, eclass sortpreserve
syntax varlist(fv min=3),  objpath(string) [stopmethod(string) sampw(varname numeric) ntrees(integer 10000) intdepth(integer 3) shrinkage(real 0.01) permtestiters(integer 0) rcmd(string) estimand(string) treatatt(string) plotname(string)]

* get current working dir
local cwd `"`c(pwd)'"'

* remove extraneous quotes from rcmd
* fix path name separators
local rcmd = subinstr("`rcmd'","'","",.)
local rcmd = subinstr("`rcmd'","\","/",.)

* Check if the c:\user\AppData\Local\TWANG exists and create it if not 
if c(os)=="Windows" {
	* rcmd is not optional on windows
	if "`rcmd'" == "" {
		di as error "option rcmd() required"
		exit 198
	}
	local user : env USERPROFILE
	local user = subinstr("`user'","\","/",.)
	local twangdir = "`user'/AppData/Local/TWANG"
	capture confirm file "`twangdir'/nul"
	if _rc >0 {
		!md "`twangdir'"
	}
	* make sure R path is correct
	* if Rscript is given without a path, check to see if it exists in the users PATH variable
	if "`rcmd'"=="Rscript"|"`rcmd'"=="Rscript.exe"|"`rcmd'"=="rscript"|"`rcmd'"=="rscript.exe" {
		qui ashell where "`rcmd'"
		if "`r(o1)'"=="" {
			* does not exist in path, so error out
			di as error "`rcmd' not found. Check that R is installed."
		exit 601
		}
		else {
			* exists in path so assign rcmd to output of where command
			local rcmd = subinstr("`r(o1)'","\","/",.)
		}		
	}
	* if given with path, validate it
	confirm file "`rcmd'"
}
if c(os)=="Unix"|c(os)=="MacOSX" {
	* default rcmd to Rscript if not specified
	if "`rcmd'" == "" {
		local rcmd = "Rscript"
	}
	* check R 
	qui ashell which "`rcmd'"
	if "`r(o1)'"=="" {
		di as error `"`rcmd' not found. Check that R is installed. If R is installed, it may be necessary to include the full path to the Rscript application. The default location for R version 3.3 is "/Library/Frameworks/R.framework/Versions/3.3/Resources/bin/Rscript". Replace 3.3 with the version of R installed on your computer."'
		exit 601
	}
	else{
		local user : env HOME
		local twangdir = "`user'/Library/TWANG"
		qui !mkdir "`twangdir'"
	}
}



* remove extraneous quotes from input params
local stopmethod = subinstr("`stopmethod'","'","",.)
local estimand = subinstr("`estimand'","'","",.)
local plotname = subinstr("`plotname'","'","",.)
local objpath = subinstr("`objpath'","'","",.)
local treatatt = subinstr("`treatatt'","'","",.)

* check for estimand

if "`estimand'"=="" {
	local estimand = "ATE"
}


* fix path name separators
local plotname = subinstr("`plotname'","\","/",.)

local objpath = subinstr("`objpath'","\","/",.)
* check existence of path names and files
if "`plotname'"!="" {
	* check if plotname includes a path
	gettoken word rest : plotname, parse("\/:")
	while `"`rest'"' != "" {
	  local plotpath `"`macval(plotpath)'`macval(word)'"'
	  gettoken word rest : rest, parse("\/:")
	}
	if inlist(`"`word'"', "\", "/", ":") {
		di as err `"incomplete path-filename for `plotname' ends in separator `word'"'
		exit 198
	}
	local plotfile `"`word'"'
	
	
	* if a valid path was given in plotname then use it
	if "`plotpath'" != "" {
		* a path was given. Validate it.
		quietly capture cd `"`plotpath'"'
		quietly cd `"`cwd'"'
	
		if _rc>0 {
			display as error "The path " _char(34) "`plotpath'" _char(34) " does not exist."
			exit 111
		}
	
		local plotnamefinal = "`plotpath'`plotfile'"
	}
}

* objpath
quietly capture cd `"`objpath'"'
if _rc==0 {
	local objpath `c(pwd)'
	local objpath = subinstr("`objpath'","\","/",.)
}


quietly cd `"`cwd'"'

if _rc>0 {
	display as error "The path " _char(34) "`objpath'" _char(34) " does not exist."
  exit 111
}

* validate enumerated parameters
local validsm = "ks.mean es.mean ks.max es.max"
local valides = "ATE ATT"
local validcl = "none pair covariate stop.method"

* if stopmethod is not specified, set to default
if "`stopmethod'"==""{
	local stopmethod es.mean
}


local chksm : list stopmethod in validsm
if `chksm' == 0 {
	display as error "One or more supplied stop methods invalid."
	display as error "Valid stop methods: `validsm'"
 	exit 111
}
	
local chkes : list estimand in valides
if `chkes' == 0 {
	display as error "Invalid estimand: `estimand'"
	display as error "Valid estimand options: `valides'"
 	exit 111
}


* if estimand = ATT, require treatatt
if "`estimand'"=="ATT" & "`treatatt'"=="" {
	display as error "The option 'treatatt' must be specified for estimand=ATT"
 	exit 111
}	

* if estimand = ATE, forbid treatatt
if "`estimand'"=="ATE" & "`treatatt'"!="" {
	display as error "The option 'treatatt' is not allowed for estimand=ATE"
 	exit 111
}	

* create tempID for merging weights
*gen tempid=_n

* preserve data in memory 
preserve

tokenize `varlist'
* first variable is treatment
local treatvar "`1'"
* check that depvar is not a factor
_fv_check_depvar `treatvar'

* all remaining vars are RHS variables
macro shift 1
local vars "`*'"

* check which vars are factor variables
local fvops = "`s(fvops)'" == "true" | _caller() >= 11
if `fvops' {
	* remove i. from factor vars
	qui fvrevar `vars', list
	foreach var of varlist `r(varlist)'{
		* note that vars still contains i. for FVs
		* see if var (an element of r(varlist)) is in vars 
		* if not, it is a FV
		local fv : list var in vars
		if `fv'==0{
			* add to class
			if "`class'" == "" {
				local class "`var'"
			}
			else{
				local class "`class' `var'"
			}
			*di "`class'"
		}
	}
	qui fvrevar `vars', list
	local vars "`r(varlist)'"
}

* replace spaces with "+"
local rhs = subinstr("`vars'"," "," + ",.)


* reformat stopmethod and ensure no variable exists with the final weightvar name
local sm `stopmethod'
tokenize `sm'

foreach x of local sm{
	local smx "`smx',`x'" 
	capture confirm variable `=subinstr("`x'",".","",.)'`=lower("`estimand'")'
	if _rc == 0 {
		di as error "Please rename or drop the variable `=subinstr("`x'",".","",.)'`=lower("`estimand'")'." 
		di as error "The stopmethod `x' and the estimand `estimand' save their corresponding weight in the variable `=subinstr("`x'",".","",.)'`=lower("`estimand'")'."
		exit 110
	}
}
local smx = subinstr("`smx'",",","",1)
local smx = subinstr("`smx'",",",  "','" ,.) 

* process class variables if given
if "`class'" != "" {
	
	* validate that all class vars in in the RHS of the model
	local chkclass : list class in vars
	if `chkclass' == 0 {
		display as error "One or more supplied class variables were not included in the model."
  	exit 111
	}
	
	local cl `class'
	tokenize `cl'

	foreach x of local cl{
		local clx "`clx',`x'" 
	}
	local clx = subinstr("`clx'",",","",1)
	local clx = subinstr("`clx'",",",  "','" ,.) 
}




*  Make sure treatvar is non-missing and contains at least 3 distinct values

quietly count if missing(`treatvar')
if r(N)>0 {
	local count = r(N)
	display as error "The treatment variable `treatvar' has `count' missing values."
		exit 111
}

qui tab `treatvar', nofreq
if r(r)<3 {
	local count = r(r)	
	display as error "The treatmeant variable `treatvar' must have at least 3 distinct values."
	exit 111
}	


* Validate treatatt if estimate is ATT
if "`estimand'"=="ATT" {
	capture confirm string variable `treatvar'
	if !_rc {
		* treatvar is a string
		qui count if `treatvar'=="`treatatt'"
	}
	else {
		* treatvar is numeric
		
		* find labelname of treatvar
		capture local treatvarlabel : value l `treatvar'
		
		* if label exists, need to convert numeric treatatt() to string treatatt()
		if "`treatvarlabel'"!=""{
			* check if treatatt is already the label value
			if regexm("`treatatt'","^[0-9]+$") {
				* find label corresponding to numeric and replace
				local treatatt  : label `treatvarlabel' `treatatt'
			}
		}

		* convert treatvar to a string if it has labels
		tempvar treatvarTEMP
		capture decode `treatvar' , gen(`treatvarTEMP')
		if !_rc {
			drop `treatvar'
			rename `treatvarTEMP' `treatvar'
		}
		
		* count the number of times treatatt appears in treatvar
		capture qui count if (`treatvar')=="`treatatt'"
		if _rc {
			capture qui count if string(`treatvar')=="`treatatt'"
		}

	}
	if r(N)==0 {
		display as error "The value `treatatt' was not found as a value for treatment variable `treatvar'"
		exit 111
	}
}


	 
* verify that sampw is non-negative and non-missing
if "`sampw'" != "" {
	quietly count if `sampw'<0
	if r(N)>0 {
		local count = r(N)	
		display as error "The sampw variable `sampw' has `count' negative values."
 		exit 111
	}
	quietly count if missing(`sampw')
	if r(N)>0 {
		local count = r(N)
		display as error "The sampw variable `sampw' has `count' missing values."
 		exit 111
	}
}

* remove any leftover files from previous calls
capture rm "`plotnamefinal'"
capture rm "`objpath'/datafile.csv"
capture rm "`objpath'/summary.csv"
capture rm "`objpath'/baltab.csv"
capture rm "`objpath'/wts.csv"
capture rm "`objpath'/wts.dta"
capture rm "`objpath'/mnps.RData"
capture rm "`objpath'/mnps.R"
capture rm "`objpath'/mnps.Rout"


qui outsheet using "`objpath'/datafile.csv", comma replace //nolabel
qui file open myfile using "`objpath'/mnps.R", write replace

file write myfile "options(warn=1)" _n
file write myfile "msg <- file(" _char(34) "`objpath'/mnps.Rout" _char(34) ", open=" _char(34) "wt" _char(34) ")" _n
file write myfile "sink(msg, type=" _char(34) "message" _char(34) ")" _n

file write myfile ".libPaths(" _char(39) "`twangdir'" _char(39) ")" _n
file write myfile "if (!is.element(" _char(34) "twang" _char(34) ", installed.packages()[,1])) install.packages(" _char(34) ///
                   "twang" _char(34) ", repos=" _char(34) "http://cran.us.r-project.org" _char(34) ")" _n

* Make sure the version of twang in &twangdir is always up to date -- it will be the package used by default if it exists 
file write myfile "update.packages(lib.loc=" _char(34) "`twangdir'" _char(34) "," _n
file write myfile "repos=" _char(34) "http://cran.us.r-project.org" _char(34) "," _n
file write myfile "instlib=" _char(34) "`twangdir'" _char(34) "," _n
file write myfile "ask=F," _n
file write myfile "oldPkgs=" _char(34) "twang" _char(34) ")" _n

file write myfile "library(twang)" _n
file write myfile "if(compareVersion(installed.packages()['twang','Version'],'1.4-0')== -1){stop('Your version of TWANG is out of date. \n It must version 1.4-0 or later.')}" _n

file write myfile "set.seed(1)" _n _n

file write myfile "inputds<-read.csv(" _char(34) "`objpath'/datafile.csv" _char(34) ")" _n
file write myfile "vnames <- names(inputds)" _n
file write myfile "#names(inputds) <- tolower(names(inputds))" _n

if "`class'" != "" {
	file write myfile "inputds[, c(" _char(39) "`clx'" _char(39) ")] <- lapply(inputds[,c(" _char(39)  "`clx'" _char(39) "), drop=F], as.factor)" _n
*	file write myfile "inputds[," _char(39) "`treatvar'" _char(39) "] <- as.factor(inputds[, " _char(39) "`treatvar'" _char(39) "])" _n 
}

file write myfile "inputds[," _char(39) "`treatvar'" _char(39) "] <- as.factor(inputds[, " _char(39) "`treatvar'" _char(39) "])" _n 
file write myfile "mnps1 <- mnps(`treatvar' ~ `rhs'," _n
file write myfile "data = inputds," _n
file write myfile "n.trees = `ntrees'," _n
file write myfile "interaction.depth = `intdepth'," _n
file write myfile "shrinkage = `shrinkage'," _n
file write myfile "perm.test.iters = `permtestiters'," _n
file write myfile "stop.method = c(" _char(39) "`smx'" _char(39) ")," _n
file write myfile "estimand = " _char(34) "`estimand'" _char(34) "," _n
if "`sampw'" != "" {
	file write myfile "sampw = inputds\$" "`sampw'" "," _n
}
else {
	file write myfile "sampw = NULL," _n
}
if "`estimand'" == "ATE" {
	file write myfile "treatATT = NULL," _n
}
else {
	capture confirm string variable `treatvar'
	if !_rc {
		* treatvar is a string
		file write myfile "treatATT = " _char(34) "`treatatt'" _char(34) "," _n
	}
	else {
		* treatvar is numeric
		file write myfile "treatATT = " "`treatatt'" "," _n
	}
}

file write myfile "verbose = FALSE" _n
file write myfile ")" _n _n

file write myfile "baltab<-bal.table(mnps1, collapse.to=" _char(34) "pair" _char(34) ")" _n

	file write myfile "bnames <- as.character(baltab\$var)" _n
	file write myfile "bnames <- as.character(baltab\$var)" _n
	file write myfile "bnames1 <- sapply(strsplit(bnames, ':'), function(x){return(x[[1]])})" _n _n _n
	file write myfile "bnames1 <- vnames[match(bnames1, vnames)]" _n
	file write myfile "substr(bnames, 1, nchar(bnames1)) <- bnames1" _n
	file write myfile "baltab\$var <- bnames" _n

	file write myfile "baltab[baltab==Inf] <- NA" _n
	file write myfile "baltab[baltab==(-Inf)] <- NA" _n
	file write myfile "write.table(baltab,file=" _char(34) "`objpath'/baltab.csv" _char(34) ",row.names=FALSE,col.names=TRUE,sep=',',na='.')" _n
	file write myfile _n _n 

  file write myfile "w <- sapply(mnps1\$stopMethods, get.weights, ps1=mnps1)" _n
	file write myfile "w<-as.data.frame(w)" _n
  file write myfile "names(w) <- paste(mnps1\$stopMethods, mnps1\$estimand, sep='')" _n
	file write myfile "w\$tempid<- inputds\$tempid" _n _n
	
	file write myfile "write.table(w,file=" _char(34) "`objpath'/wts.csv" _char(34) ",row.names=FALSE,col.names=TRUE,sep=',')" _n
	file write myfile "if(" _char(34) "`estimand'" _char(34) "==" _char(34) "ATE" _char(34) "){" _n 
  file write myfile "   summ <- summary(mnps1)" _n
  file write myfile "   summ1 <- summ[[1]]" _n
  file write myfile "   summ2 <- summ[[2]]" _n
  file write myfile "   write.table(summ1,file=" _char(34) "`objpath'/summary1.csv" _char(34) ",row.names=FALSE,col.names=TRUE,sep=',',na='.')" _n
  file write myfile "   write.table(summ2,file=" _char(34) "`objpath'/summary2.csv" _char(34) ",row.names=FALSE,col.names=TRUE,sep=',',na='.')" _n
  file write myfile "}else{" _n
  file write myfile "   summ<-summary(mnps1)" _n
  file write myfile "   ctx <- nrow(summ\$summaryList[[1]])" _n
  file write myfile "   ctx <- rep(summ\$levExceptTreatATT, each=ctx)" _n
  file write myfile "   summ <- do.call(rbind, summ\$summaryList)" _n
  file write myfile "   tmp <- row.names(summ)" _n
  file write myfile "   rownames(summ) <- NULL" _n
  file write myfile "   summ <- data.frame(comp_treat=ctx, row_name=tmp, summ)" _n
  file write myfile "   write.table(summ,file=" _char(34) "`objpath'/summary.csv" _char(34) ",row.names=FALSE,col.names=TRUE,sep=',',na='.')" _n
  file write myfile "}" _n _n


* if plotname is given then plot
if !missing("`plotnamefinal'") {
  file write myfile "pdf('`plotnamefinal'')" _n 
  file write myfile "plot(mnps1,plots=1, multiPage=TRUE)" _n 
  file write myfile "plot(mnps1,plots=2, multiPage=TRUE)" _n 
  file write myfile "plot(mnps1,plots=3, multiPage=TRUE)" _n 
  file write myfile "plot(mnps1,plots=4, multiPage=TRUE)" _n 
  file write myfile "plot(mnps1,plots=5, multiPage=TRUE)" _n 

  file write myfile "dev.off()" _n 
}

file write myfile "save(mnps1, file='`objpath'/mnps.RData')" _n 
file close myfile


di ""
di as text "Running R script, please wait..."
shell "`rcmd'" "`objpath'/mnps.R"

*n shell "`rcmd'" CMD BATCH --vanilla `objpath'/mnps.R
*shell echo Starting R, please wait... & "`rcmd'" CMD BATCH --vanilla `objpath'/mnps.R

* check for errors
capture confirm file "`objpath'/mnps.Rout"
if _rc >0 {
	display as error "Error: R did not complete successfully."
}

qui infix str v1 1-1000 using "`objpath'/mnps.Rout", clear
qui replace v1=ltrim(v1)
qui count if regexm(v1,"Execution halted")
qui gen x=.
if r(N)>0 {
		display as error "Return message from R is as follows:"
  	qui gen r=regexm(v1,"Error")|regexm(v1,"error")
  	qui replace x=_n if r==1
    qui egen mx=min(x)
    qui keep if _n>=mx
    local N = _N
    forvalues i = 1/`N' {
      di as error v1[`i']
    }
  	exit 111
}

qui infix str v1 1-1000 using "`objpath'/mnps.Rout", clear
qui replace v1=ltrim(v1)
qui count if regexm(v1,"Warning")|regexm(v1,"warning")
qui gen x=.
if r(N)>0 {
		display as error "R completed with warnings:"
  	qui gen r=regexm(v1,"Warning")|regexm(v1,"warning")
  	qui replace x=_n if r==1
    qui egen mx=min(x)
    qui keep if _n>=mx
    local N = _N
    forvalues i = 1/`N' {
      di as error v1[`i']
    }
}


* For ATE, need to retrieve two summary matricies
if "`estimand'" == "ATE" {
	clear
	qui insheet using "`objpath'/summary1.csv", comma
	local sumvarnames 
	foreach var of varlist _all {
		if "`var'" != "stopmethod" {
		local sumvarnames `sumvarnames' `var' 
		}
	}
	mkmat `sumvarnames', mat(summat1) rownames(stopmethod)
	ereturn matrix summary1=summat1

	clear
	qui insheet using "`objpath'/summary2.csv", comma
	local sumvarnames 
	foreach var of varlist _all {
		if "`var'" != "treatment" {
		local sumvarnames `sumvarnames' `var' 
		}
	}
	mkmat `sumvarnames', mat(summat2) rownames(treatment)
	ereturn matrix summary2=summat2
}


* For ATT, only need to retrieve one summary matrix but combined string vars in rowname
if "`estimand'" == "ATT" {
	clear
	qui insheet using "`objpath'/summary.csv", comma
	capture qui replace row_name= string(comp_treat) + ": " + row_name
	if _rc {
		qui replace row_name= (comp_treat) + ": " + row_name
	}
	drop comp_treat
	mkmat ntreat-iter, mat(summat) rownames(row_name)
	ereturn matrix summary=summat
}

* Balance table
clear
qui insheet using "`objpath'/baltab.csv", comma
tempvar tempid
gen `tempid'=_n
sort `tempid'

* get rid of unwanted labels in stop.method
qui replace stopmethod = subinstr(stopmethod, ".", "", .) 


* processing is dependent on choice of estimand (ATT vs ATE)

* ATT
if "`estimand'" == "ATT" {
  encode var, gen(_var)
  qui levelsof _var, local(levels)
  local lbe : value label _var
  foreach l of local levels {
    local x : label `lbe' `l'
    local lbl_var `lbl_var' `l' "`x'" 
  }
  ereturn local l_var `"`lbl_var'"'
  
  
  capture encode control, gen(_control)
  if _rc>0 {
	tempvar cont
	gen `cont' = string(control)
	drop control
	rename `cont' control
	encode control, gen(_control)
  }
  qui levelsof _control, local(levels)
  local lbe : value label _control
  foreach l of local levels {
    local x : label `lbe' `l'
    local lbl_control `lbl_control' `l' "`x'" 
  }
  ereturn local l_control `"`lbl_control'"'
  
  encode stopmethod, gen(_stopmethod)
  qui levelsof _stopmethod, local(levels)
  local lbe : value label _stopmethod
  foreach l of local levels {
    local x : label `lbe' `l'
    local lbl_sm `lbl_sm' `l' "`x'" 
  }
  ereturn local l_stopmethod `"`lbl_sm'"'

  capture mkmat _var txmn txsd ctmn ctsd stdeffsz stat p ks kspval _control _stopmethod, mat(baltab)
  
}


* ATE
if "`estimand'" == "ATE" {
  encode var, gen(_var)
  qui levelsof _var, local(levels)
  local lbe : value label _var
  foreach l of local levels {
    local x : label `lbe' `l'
    local lbl_var `lbl_var' `l' "`x'" 
  }
  ereturn local l_var `"`lbl_var'"'
  
  capture encode tmt1, gen(_tmt1)
  if _rc>0 {
	tempvar tmt1
	gen `tmt1' = string(tmt1)
	drop tmt1
	rename `tmt1' tmt1
	encode tmt1, gen(_tmt1)
  }
  qui levelsof _tmt1, local(levels)
  local lbe : value label _tmt1
  foreach l of local levels {
    local x : label `lbe' `l'
    local lbl_tmt1 `lbl_tmt1' `l' "`x'" 
  }
  ereturn local l_tmt1 `"`lbl_tmt1'"'

  capture encode tmt2, gen(_tmt2)
  if _rc>0 {
	tempvar tmt2
	gen `tmt2' = string(tmt2)
	drop tmt2
	rename `tmt2' tmt2
	encode tmt2, gen(_tmt2)
  }
  qui levelsof _tmt2, local(levels)
  local lbe : value label _tmt2
  foreach l of local levels {
    local x : label `lbe' `l'
    local lbl_tmt2 `lbl_tmt2' `l' "`x'" 
  }
  ereturn local l_tmt2 `"`lbl_tmt2'"'

  
  encode stopmethod, gen(_stopmethod)
  qui levelsof _stopmethod, local(levels)
  local lbe : value label _stopmethod
  foreach l of local levels {
    local x : label `lbe' `l'
    local lbl_sm `lbl_sm' `l' "`x'" 
  }
  ereturn local l_stopmethod `"`lbl_sm'"'

  capture mkmat _tmt1 _tmt2 _var mean1 mean2 popsd stdeffsz p ks kspval _stopmethod, mat(baltab)

}

capture ereturn matrix baltab=baltab


/*
* replace NA with missing
* generate a tempvar that indicates which rows correspond to missing data indicators
tempvar missing
qui gen `missing' = regexm(row_name,"<NA>")
* separate out the class variables from the rest
tempvar class_missing
qui gen `class_missing' = (1-`missing')*regexm(row_name,regexr("`class'"," ","|")) 
* replace the rowname to indicate missingness
qui replace row_name = "Missingness:" + regexr(row_name,":<NA>","") if `missing'==1
* sort by missingness and factor variable status
sort `missing' `class_missing' row_name
*/


*drop tempid
*display " -- Balance tables --"
*by tablename: list, table

clear
qui insheet using "`objpath'/wts.csv", comma
*sort tempid
*drop tempid
qui save "`objpath'/wts.dta", replace

clear

* restore original data
restore

* merge weights on to main dataset
*gen tempid = _n
*sort tempid
qui merge 1:1 _n using "`objpath'/wts.dta", nogenerate
qui erase "`objpath'/wts.dta"

ereturn local cmd "mnps"
ereturn local estimand `"`estimand'"'
ereturn scalar N = _N 
local weightvars = subinstr("`stopmethod'",".","",.)

ereturn local weightvars "`weightvars'"
ereturn local Robject "`objpath'/mnps.RData"
ereturn local rcmd "`rcmd'"
ereturn local objpath "`objpath'"


balance

if !missing("`plotnamefinal'") {
	di "Plot written to `plotnamefinal'"
}

qui cd `"`cwd'"'

end




 /********************/
/** ashell command **/

*! version 1.0 05February2009

program def ashell, rclass
version 8.0
syntax anything (name=cmd)

/*
 This little program immitates perl's backticks.
 Author: Nikos Askitas
 Date: 04 April 2007
 Modified and tested to run on windows. 
 Date: 05 February 2009
*/

* Run program 

  display `"We will run command: `cmd'"'
  display "We will capture the standard output of this command into"
  display "string variables r(o1),r(o2),...,r(os) where s = r(no)."
  local stamp = string(uniform())
  local stamp = reverse("`stamp'")
  local stamp = regexr("`stamp'","\.",".tmp")
  local fname = "`stamp'"
  shell `cmd' >> `fname'
  tempname fh
  local linenum =0
  file open `fh' using "`fname'", read
  file read `fh' line
   while r(eof)==0 {
    local linenum = `linenum' + 1
    scalar count = `linenum'
    return local o`linenum' = `"`line'"'
    return local no = `linenum'
    file read `fh' line
   }
  file close `fh'

if("$S_OS"=="Windows"){
 shell del `fname'
}
else{
 shell rm `fname'
}

end


