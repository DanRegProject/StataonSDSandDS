*! version 1.3.0  04apr2017
program ps, eclass
syntax varlist(fv min=2 numeric),  objpath(string) [stopmethod(string) sampw(varname numeric) ntrees(integer 10000) intdepth(integer 3) shrinkage(real 0.01) permtestiters(integer 0) rcmd(string) estimand(string) plotname(string) BAGfraction(real 1) seed(integer 1)]

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

* check bag fraction
if `bagfraction'<=0 | `bagfraction'>1 {
	display as error "The bag fraction must be in (0,1]."
	exit
}

* remove extraneous quotes from input params
local stopmethod = subinstr("`stopmethod'","'","",.)
local estimand = subinstr("`estimand'","'","",.)
local plotname = subinstr("`plotname'","'","",.)
local objpath = subinstr("`objpath'","'","",.)

* check for estimand - set to default
if "`estimand'"=="" {
	local estimand = "ATE"
}


* fix path name separators
local plotname = subinstr("`plotname'","\","/",.)
local objpath = subinstr("`objpath'","\","/",.)

* objpath -- expand and validate
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


* check existence of path names and files
if "`plotname'"!="" {
	* check if plotname includes a path
	gettoken word rest : plotname, parse("\/:")
	while `"`rest'"' != "" {
	  local plotpath `"`macval(plotpath)'`macval(word)'"'
	  gettoken word rest : rest, parse("\/:")
	}
	if inlist(`"`word'"', "\", "/", ":") {
		di as err `"incomplete path-filename for `plotname'; ends in separator `word'"'
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
	else{
		local plotnamefinal = "`objpath'/`plotfile'"
	}
}

* validate enumerated parameters
local validsm = "ks.mean es.mean ks.max es.max"
local valides = "ATE ATT"

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
		else{
			* drop variable labels on non-class variables 
			label values `var' 
		}
		* check that all vars are numeric
		* should have been done by syntax, but messes up with factor variables
		capture confirm numeric variable `var'
		if _rc != 0 {
			di as error "varlist:  `var':  string variable not allowed"
			exit 109
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
		local exit 110
	}
}
if "`exit'"!=""{
	exit `exit'
}
local smx = subinstr("`smx'",",","",1)
local smx = subinstr("`smx'",",",  "','" ,.) 

* this is no longer necessary due to the conversion to factor variables
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

* make sure treatvar is only 0 or 1 and remove variable labels
label values `treatvar' 
quietly capture assert `treatvar' == 0 | `treatvar' == 1 
if _rc>0 {
	display as error "Treatment variable must be 0 or 1."
 	exit 111
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
capture rm "`objpath'/ps.RData"
capture rm "`objpath'/ps.R"
capture rm "`objpath'/ps.Rout"


qui outsheet using "`objpath'/datafile.csv", comma replace //nolabel
qui file open myfile using "`objpath'/ps.R", write replace

file write myfile "options(warn=1)" _n
file write myfile "msg <- file(" _char(34) "`objpath'/ps.Rout" _char(34) ", open=" _char(34) "wt" _char(34) ")" _n
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

file write myfile "set.seed(`seed')" _n _n

file write myfile "inputds<-read.csv(" _char(34) "`objpath'/datafile.csv" _char(34) ")" _n
if "`class'" != "" {
	file write myfile "inputds[, c(" _char(39) "`clx'" _char(39) ")] <- lapply(inputds[,c(" _char(39)  "`clx'" _char(39) "), drop=F], as.factor)" _n
}
file write myfile "ps1 <- ps(`treatvar' ~ `rhs'," _n
file write myfile "data = inputds," _n
file write myfile "n.trees = `ntrees'," _n
file write myfile "bag.fraction = `bagfraction'," _n
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
file write myfile "verbose = FALSE" _n
file write myfile ")" _n _n

file write myfile "baltab<-bal.table(ps1)" _n _n

file write myfile "w<-as.data.frame(ps1\$w)" _n 
file write myfile "w\$tempID<-as.numeric(row.names(w))" _n 
file write myfile "write.table(w,file=" _char(34) "`objpath'/wts.csv"_char(34) ",row.names=FALSE,col.names=TRUE,sep=',')" _n 
file write myfile "baltab <- data.frame(do.call(rbind, baltab), table.name=rep(names(baltab), each=nrow(baltab[[1]])))" _n 
file write myfile "baltab <- data.frame(row_name=row.names(baltab), baltab)" _n 
file write myfile "baltab[baltab==Inf] <- NA" _n
file write myfile "baltab[baltab==(-Inf)] <- NA" _n
file write myfile "write.table(baltab,file="_char(34) "`objpath'/baltab.csv"_char(34) ",row.names=FALSE,col.names=TRUE,sep=',',na='.')" _n 
file write myfile "summ<-as.data.frame(rbind(summary(ps1)))" _n 
file write myfile "summ <- data.frame(row_name=row.names(summ), summ)" _n 
file write myfile "write.table(summ,file="_char(34) "`objpath'/summary.csv"_char(34) ",row.names=FALSE,col.names=TRUE,sep=',',na='.')" _n 

* if plotname is given then plot
if !missing("`plotnamefinal'") {
  file write myfile "pdf('`plotnamefinal'')" _n 
  file write myfile "plot(ps1,plots=1, main='Plot 1 (optimize): GBM Optimization')" _n 
  file write myfile "plot(ps1,plots=2, main='Plot 2 (boxplot): Boxplot of Propensity Scores')" _n 
  file write myfile "plot(ps1,plots=3, main='Plot 3 (es): Standardized Effect Sizes Pre/Post Weighting')" _n 
  file write myfile "plot(ps1,plots=4, main='Plot 4 (t): T-test P-values of Group Means of Covariates')" _n 
  file write myfile "plot(ps1,plots=5, main='Plot 5 (ks): K-S P-values of Group Distns of Covariates')" _n 
*	file write myfile "plot(ps1,plots=6, main='Plot 6 (histogram): Histogram of Weights by Group')" _n
*	di "Plot written to `plotnamefinal'"

  file write myfile "garbage <- dev.off()" _n 
}

file write myfile "save(ps1, file='`objpath'/ps.RData')" _n 
file close myfile

di ""
di "Running R script, please wait..."
shell "`rcmd'" "`objpath'/ps.R"

* check for errors;
capture confirm file "`objpath'/ps.Rout"
if _rc >0 {
	display as error "Error: R did not complete successfully."
}

qui infix str v1 1-1000 using "`objpath'/ps.Rout", clear
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

qui infix str v1 1-1000 using "`objpath'/ps.Rout", clear
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


clear
qui insheet using "`objpath'/summary.csv", comma
* rm _ATE
qui replace row_name = regexr(row_name,".(ATE|ATT)$","")
mkmat ntreat-iter, mat(summat) rownames(row_name)
ereturn matrix summary=summat


clear
qui insheet using "`objpath'/baltab.csv", comma
tempvar tempid
qui gen `tempid'=_n
sort tablename `tempid'

* get rid of unwanted labels in rownames
qui replace row_name = subinstr(row_name, "unw.", "", .) 
qui replace row_name = subinstr(row_name, "es.mean.ATE.", "", .) 
qui replace row_name = subinstr(row_name, "es.max.ATE.", "", .) 
qui replace row_name = subinstr(row_name, "es.max.direct.ATE.", "", .) 
qui replace row_name = subinstr(row_name, "ks.mean.ATE.", "", .) 
qui replace row_name = subinstr(row_name, "ks.max.ATE.", "", .) 
qui replace row_name = subinstr(row_name, "ks.max.direct.ATE.", "", .) 
qui replace row_name = subinstr(row_name, "es.mean.ATT.", "", .) 
qui replace row_name = subinstr(row_name, "es.max.ATT.", "", .) 
qui replace row_name = subinstr(row_name, "es.max.direct.ATT.", "", .) 
qui replace row_name = subinstr(row_name, "ks.mean.ATT.", "", .) 
qui replace row_name = subinstr(row_name, "ks.max.ATT.", "", .) 
qui replace row_name = subinstr(row_name, "ks.max.direct.ATT.", "", .) 

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


capture mkmat txmn-kspval if tablename=="unw", mat(unw) rowname(row_name) 
capture mkmat txmn-kspval if regexm(tablename,"es.mean."), mat(esmean) rowname(row_name) 
capture mkmat txmn-kspval if regexm(tablename,"es.max."), mat(esmax) rowname(row_name) 
capture mkmat txmn-kspval if regexm(tablename,"es.max.direct."), mat(esmaxdirect) rowname(row_name) 
capture mkmat txmn-kspval if regexm(tablename,"ks.mean."), mat(ksmean) rowname(row_name) 
capture mkmat txmn-kspval if regexm(tablename,"ks.max."), mat(ksmax) rowname(row_name) 
capture mkmat txmn-kspval if regexm(tablename,"ks.max.direct."), mat(ksmaxdirect) rowname(row_name) 


capture ereturn matrix unw=unw
capture ereturn matrix esmean=esmean
capture ereturn matrix esmax=esmax
capture ereturn matrix esmaxdirect=esmaxdirect

capture ereturn matrix ksmean=ksmean
capture ereturn matrix ksmax=ksmax
capture ereturn matrix ksmaxdirect=ksmaxdirect


clear
qui insheet using "`objpath'/wts.csv", comma
sort tempid
drop tempid
qui save "`objpath'/wts.dta", replace

clear

* restore original data
restore

* merge weights on to main dataset
qui merge 1:1 _n using "`objpath'/wts.dta", nogenerate
qui erase "`objpath'/wts.dta"

ereturn local cmd "ps"
ereturn local estimand `"`estimand'"'
ereturn scalar N = _N 
local weightvars = subinstr("`stopmethod'",".","",.)

ereturn local weightvars "`weightvars'"
ereturn local Robject "`objpath'/ps.RData"
ereturn local rcmd "`rcmd'"
ereturn local objpath "`objpath'"

balance

if !missing("`plotnamefinal'") {
	di as text "Plot written to `plotnamefinal'"
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


