*! version 1.3.0  04apr2017
program psplot
syntax , plotname(string) plots(string) [inputobj(string) rcmd(string) plotformat(string) color(string) pairwisemax(string) figurerows(integer 1) subset(string) objpath(string)]

* preserve data in memory 
preserve

* if rcmd is not specified, check what ps used
if "`rcmd'"=="" {
	local rcmd `e(rcmd)'
}
* if inputobj is not specified, check what ps saved
if "`inputobj'"=="" {
	local inputobj `e(Robject)'
}
* if objpath is not specified, check what ps saved
if "`objpath'"=="" {
	local objpath `e(objpath)'	
}


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

* get current working dir
local cwd `"`c(pwd)'"'

* validate parameters

* remove extraneous quotes from input params
local inputobj = subinstr("`inputobj'","'","",.)
local plotname = subinstr("`plotname'","'","",.)
local plotformat = subinstr("`plotformat'","'","",.)
local color = subinstr("`color'","'","",.)
local pairwisemax = subinstr("`pairwisemax'","'","",.)
local plots = subinstr("`plots'","'","",.)
local subset = subinstr("`subset'","'","",.)
local objpath = subinstr("`objpath'","'","",.)

* fix path name separators
local inputobj = subinstr("`inputobj'","\","/",.)
local plotname = subinstr("`plotname'","\","/",.)
local objpath = subinstr("`objpath'","\","/",.)
local cwd = subinstr("`cwd'","\","/",.)

* check existence of path names and files
confirm file "`inputobj'"


* assign defaults for optional parameters
if "`color'" == "" local color "TRUE"
if "`pairwisemax'" == "" local pairwisemax "TRUE"
if "`figurerows'" == "" local figurerows 1


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

* if no path name, use objpath if it exists
else if "`objpath'" != "" {
	local plotnamefinal = "`objpath'/`plotfile'"
}	
* otherwise use current working dir
else {
	local plotnamefinal = "`cwd'/`plotfile'"
}

* validate enumerated parameters;
* plots
capture {
	assert "`plots'"=="1" | "`plots'"=="2" |"`plots'"=="3" | "`plots'"=="4" | "`plots'"=="5" | "`plots'"=="6" | ///
	       "`plots'"=="optimize" | "`plots'"=="boxplot" |"`plots'"=="es" | "`plots'"=="t" | "`plots'"=="ks" | "`plots'"=="histogram"   
}
if _rc==9 {
	display as error "The term " _char(34) "`plots'" _char(34) " is not a valid value for the plots parameter."
  exit 111
}
if "`plots'"=="optimize" | "`plots'"=="boxplot" |"`plots'"=="es" | "`plots'"=="t" | "`plots'"=="ks" | "`plots'"=="histogram" {
	local plots= "'`plots''"
}

* color
capture {
	assert "`color'"=="TRUE" | "`color'"=="T" | "`color'"=="FALSE" | "`color'"=="F" 
}
if _rc==9 {
	display as error "The term " _char(34) "`color'" _char(34) " is not a valid value for the color parameter. Must be TRUE or FALSE."
  exit 111
}

* pairwisemax
capture {
	assert "`pairwisemax'"=="TRUE" | "`pairwisemax'"=="T" | "`pairwisemax'"=="FALSE" | "`pairwisemax'"=="F" 
}
if _rc==9 {
	display as error "The term " _char(34) "`pairwisemax'" _char(34) " is not a valid value for the pairwisemax parameter. Must be TRUE or FALSE."
  exit 111
}

* figurerows
capture {
	assert "`figurerows'"=="1" | "`figurerows'"=="2" | "`figurerows'"=="3" | "`figurerows'"=="4" 
}
if _rc==9 {
	display as error "The term " _char(34) "`figurerows'" _char(34) " is not a valid value for the figurerows parameter. Must be an integer between 1 and 4."
  exit 111
}

* determine plot format if it exists
if "`plotformat'" == "jpg" { 
	local fmt = "jpeg" 
}
else if "`plotformat'" == "png" { 
	local fmt = "png" 
}
else if "`plotformat'" == "pdf" { 
	local fmt = "pdf" 
}
else if "`plotformat'" == "wmf" { 
	local fmt = "win.metafile" 
}
else if "`plotformat'" == "postscript" { 
	local fmt = "postscript" 
}
else {
	local fmt = "pdf" 
}

* remove any leftover files from previous calls
capture rm "`plotnamefinal'"
capture rm "`objpath'/plot_stata.R"
capture rm "`objpath'/psplot.Rout"


qui file open myfile using "`objpath'/plot_stata.R", write replace

file write myfile "options(warn=1)" _n
file write myfile "msg <- file(" _char(34) "`objpath'/psplot.Rout" _char(34) ", open=" _char(34) "wt" _char(34) ")" _n
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

file write myfile "tmp <- load(" _char(34) "`inputobj'" _char(34) ")" _n
file write myfile "`fmt'(" _char(34) "`plotnamefinal'" _char(34) ")" _n
file write myfile "plot(get(tmp),plots=`plots', subset=`subset', color=`color', pairwiseMax=`pairwisemax', figureRows=`figurerows')" _n

file write myfile "garbage <- dev.off()" _n

file close myfile

di "Running R script, please wait..."
shell "`rcmd'" "`objpath'/plot_stata.R"



* check for errors;
capture confirm file "`objpath'/psplot.Rout"
if _rc >0 {
	display as error "Error: R did not complete successfully."
}

qui infix str v1 1-1000 using "`objpath'/psplot.Rout", clear
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

qui infix str v1 1-1000 using "`objpath'/psplot.Rout", clear
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

* restore original data
restore

display as text "Plot(s) written to `plotnamefinal'"

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


