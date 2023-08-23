*! version 1.3.0  04apr2017
program dxwts, eclass 
syntax varlist(fv min=2 numeric), weightvars(varlist numeric) objpath(string)  [ permtestiters(integer 0) sampw(string)  rcmd(string) estimand(string)]  

* clear out any previous balance/summary tables
ereturn clear

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
		di as error "`rcmd' not found. Check that R is installed."
		exit 601
	}
	else{
		local user : env HOME
		local twangdir = "`user'/Library/TWANG"
		qui !mkdir "`twangdir'"
	}
}


* remove extraneous quotes from input params
*local sampw = subinstr("`sampw'","'","",.)
local estimand = subinstr("`estimand'","'","",.)
local weightvars = subinstr("`weightvars'","'","",.)
local objpath = subinstr("`objpath'","'","",.)

* check for estimand
if "`estimand'"=="" {
	local estimand = "ATE"
}

* check that weight var is not included in other vars
foreach var of varlist `weightvars'{
	local check : list var in varlist
	if `check'!=0{
		* error
		display as error "The variable " _char(34) "`var'" _char(34) " is specified as both a weight and a covariate/treatment."
		exit 111
	}
}

* fix path name separators
local objpath = subinstr("`objpath'","\","/",.)


* objpath
local cwd `"`c(pwd)'"'
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
local valides = "ATE ATT"
	
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


* replace spaces with commas
local rhs = "c('" + subinstr("`vars'"," ","','",.) + "')"


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

* di "treatvar=`treatvar'"
* di "RHS=`rhs'"

* reformat weightvars
local wv `weightvars'
tokenize `wv'

foreach x of local wv{
local wvx "`wvx',`x'" 
}
local wvx = subinstr("`wvx'",",","",1)
local wvx = subinstr("`wvx'",",",  "','" ,.) 

* di "weightvars=`wvx'"

* remove any leftover files from previous calls
capture rm "`objpath'/dxwtsdatafile.csv"
capture rm "`objpath'/dxwtsbaltab.csv"
capture rm "`objpath'/dxsummary.csv"
capture rm "`objpath'/dxwts.R"
capture rm "`objpath'/dxwts.Rout"


qui outsheet using "`objpath'/dxwtsdatafile.csv", comma replace //nolabel

qui file open myfile using "`objpath'/dxwts.R", write replace

file write myfile "options(warn=1)" _n
file write myfile "msg <- file(" _char(34) "`objpath'/dxwts.Rout" _char(34) ", open=" _char(34) "wt" _char(34) ")" _n
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
file write myfile "set.seed(1)" _n _n

file write myfile "inputds<-read.csv(" _char(34) "`objpath'/dxwtsdatafile.csv" _char(34) ")" _n _n

file write myfile "vnames <- names(inputds)          " _n
file write myfile "names(inputds) <- tolower(names(inputds))" _n _n

if "`class'" != "" {
	file write myfile "inputds[, c(" _char(39) "`clx'" _char(39) ")] <- lapply(inputds[,c(" _char(39)  "`clx'" _char(39) "), drop=F], as.factor)" _n
}

file write myfile "x<-as.matrix(subset(inputds,select=c(" _char(39) "`wvx'" _char(39) ")))" _n



/*
%if &chkclass = 0 %then
  put %unquote(%str(%'inputds[, %combine(&class)] <- lapply(inputds[,%combine(&class), drop=F], as.factor)%'))  ;
*/

	file write myfile "dxtmp <- dx.wts(x, " _n
	file write myfile " data=inputds, " _n
	file write myfile " vars = `rhs' ," _n
	file write myfile " estimand = " _char(34) "`estimand'" _char(34) "," _n
	file write myfile " treat.var = " _char(34) "`treatvar'" _char(34) "," _n
	file write myfile " x.as.weights=T, " _n
	file write myfile " sampw=`sampw', " _n
	file write myfile " perm.test.iters=`permtestiters'" _n
	file write myfile ") " _n
	file write myfile  _n
	file write myfile "baltab<-bal.table(dxtmp)" _n
	file write myfile  _n
	file write myfile "bnames <- rownames(baltab\$unw) " _n
	file write myfile "bnames1 <- sapply(strsplit(bnames, ':'), function(x){return(x[[1]])})  " _n
	file write myfile "bnames1 <- vnames[match(bnames1, tolower(vnames))]                     " _n
	file write myfile "substr(bnames, 1, nchar(bnames1)) <- bnames1                           " _n
	file write myfile "baltab <- lapply(baltab, function(u){                                  " _n
  file write myfile "                 rownames(u) <- bnames                                 " _n
  file write myfile "                 return(u)})                                           " _n
	file write myfile  _n

	file write myfile "baltab <- data.frame(do.call(rbind, baltab), table.name=rep(names(baltab), each=nrow(baltab[[1]])))" _n
	file write myfile "baltab <- data.frame(row_name=row.names(baltab), baltab)" _n
	file write myfile "baltab[baltab==Inf] <- NA" _n
  file write myfile "baltab[baltab==(-Inf)] <- NA" _n 
	file write myfile "write.table(baltab,file=" _char(34) "`objpath'/dxwtsbaltab.csv"_char(34) ",row.names=FALSE,col.names=TRUE,sep=',',na='.')" _n
	file write myfile "write.table(dxtmp\$summary.tab,file=" _char(34) "`objpath'/dxsummary.csv"_char(34)  ",row.names=FALSE,col.names=TRUE,sep=',',na='.')" _n

file close myfile


di "Running R script, please wait..."
shell "`rcmd'" "`objpath'/dxwts.R"

* check for errors;
capture confirm file "`objpath'/dxwts.Rout"
if _rc >0 {
	display as error "Error: R did not complete successfully."
}

qui infix str v1 1-1000 using "`objpath'/dxwts.Rout", clear
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

qui infix str v1 1-1000 using "`objpath'/dxwts.Rout", clear
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

/*
clear
insheet using "`objpath'/dxsummary.csv", comma
display " -- dxwts Summary table --"
list, table

clear
insheet using "`objpath'/dxwtsbaltab.csv", comma
gen tempid=_n
replace tablename="_unw" if tablename=="unw"
sort tablename tempid
drop tempid
display " -- dxwts Balance tables --"
by tablename: list, table
*/


clear
qui insheet using "`objpath'/dxsummary.csv", comma
mkmat ntreat-iter, mat(summat) rownames(type)
ereturn matrix summary=summat


clear
qui insheet using "`objpath'/dxwtsbaltab.csv", comma
tempvar tempid
gen `tempid'=_n
sort tablename `tempid'

* get rid of unwanted labels in rownames
qui replace row_name = subinstr(row_name, "unw.", "", .) 

foreach vname of local weightvars{
	qui replace row_name = subinstr(row_name, "`vname'.", "", .)
	*qui replace row_name = subinstr(row_name, "_", "", .) 
}

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


mkmat txmn-kspval if tablename=="unw", mat(unw) rowname(row_name) 
foreach vname of local weightvars{
	capture mkmat txmn-kspval if regexm(tablename,"`vname'"), mat("`vname'") rowname(row_name) 
}

ereturn matrix unw=unw
foreach vname of local weightvars{
	capture ereturn matrix `vname'=`vname'
}


ereturn local cmd "dxwts"
ereturn local estimand `"`estimand'"'
ereturn local weightvars "`weightvars'"
ereturn scalar N = _N 

restore

balance

quietly cd `"`cwd'"'

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
