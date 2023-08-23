cap  program drop forestplot
program forestplot, eclass sortpreserve
syntax varlist(numeric min=3 max=3) [if], ROWvar(varname string) [GROUPvar(varname string) COLUMNvar(varname string) valtab(string) outdata(string) plab(string)  hadj(string) xlim(string) ppos(string) sublabelside(integer 3) objpath(string)  rcmd(string) plotname(string) grouplabel(string) rowlabel(string) columnlabel(string)  columnsublabel(string) width(real 16.7) height(real 6.5) vref(real 1) cutx(real .1) gcex(real 1.5) rcex(real 1.2) mcex(real .8) sep(string) addcol(varname string) addcollabel(string) log(string) rpos(real 0.1) hlines(string) wpan(string) xseqn(string)]

* get current working dir
local cwd `"`c(pwd)'"'

* remove extraneous quotes from rcmd
* fix path name separators
local rcmd = subinstr("`rcmd'","'","",.)
local rcmd = subinstr("`rcmd'","\","/",.)

if c(os)=="Windows" {
        * rcmd is not optional on windows
        if "`rcmd'" == "" {
                local rcmd "$RPROGRAM"
        }
        local user : env USERPROFILE
        local user = subinstr("`user'","\","/",.)
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
        }
}

if "`valtab'" == "" loc valtab TRUE
if inlist(`"`valtab'"',"TRUE","FALSE")==0{
	di as error `"valtab should be either TRUE or FALSE"'
	exit 198
}
if "`log'" == "" loc log TRUE
if inlist(`"`log'"',"TRUE","FALSE")==0{
	di as error `"log should be either TRUE or FALSE"'
	exit 198
}
if inlist(`"`hlines'"',`""',"TRUE","FALSE")==0{
	di as error `"hlines should be either NULL or FALSE or a list of integers comma separated"'
*	exit 198
}

if inlist(`"`sublabelside'"',"1","3")==0{
	di as error `"sublabelside should be either 1 (below) or 3 (above)"'
	exit 198
}

* fix path name separators
local plotname = subinstr("`plotname'","\","/",.)
local objpath = subinstr("`objpath'","\","/",.)

* check existence of path names and files
if "`plotname'"=="" loc plotname forestplot
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

                local plotname = "`plotpath'`plotfile'"
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


* preserve data in memory
preserve
if "`if'" != "" keep `if'
qui{
tokenize `varlist'

  /* Generate nice text version of plotted values */
  tempvar val vall valu fval
  tostring `1', g(`val')  format(%4.2f) force
  tostring `2', g(`vall') format(%4.2f) force
  tostring `3', g(`valu') format(%4.2f) force
  gen `fval' = `val' + " (" + `vall' + "-" + `valu' + ")"
  drop `val' `vall' `valu'
  gen `val'=`1'
  gen `vall'=`2'
  gen `valu'=`3'
      * Step 6 Optional
  * Determine what to do with entries with missing values, often they are reference categories
  * If they are not to be included in the forestplot then drop these rows
  * If they are included, then the formattet string may be changed and the bullet need to be set in reference level
  *     obtained by setting all three values equal
  replace `fval'="Reference" if missing(`val')

  /* ensure plot of bullet for reference group */
  replace `vall'=1 if missing(`val')
  replace `valu'=1 if missing(`val')
  replace `val'=1 if missing(`val')

  cap gen Columns=""
  cap gen Groups=""

  if "`outdata'"=="" loc outdata forestplot

  if "`columnvar'"!=""  loc xcon & `columnvar'==`columnvar'[_n-1]
  if "`groupvar'"!="" replace `groupvar'="" if `groupvar'==`groupvar'[_n-1] `xcon'
  saveold `objpath'/`outdata'.dta, replace version(12)
}
  cap file close myfile

qui file open myfile using "`objpath'/makeForestplot.R", write replace

file write myfile "options(warn=1)" _n
*file write myfile "msg <- file(" _char(34) "`objpath'/makeForestplot.Rout" _char(34) ", open=" _char(34) "wt" _char(34) ")" _n
*file write myfile "sink(msg, type=" _char(34) "message" _char(34) ")" _n

file write myfile "library(doBy)" _n
file write myfile "library(foreign)" _n
file write myfile "source(" _char(34) "$LocalMacroDir/R/Forestplot.R" _char(34) ")" _n

file write myfile "data<-data.frame(read.dta(" _char(34) "`objpath'/`outdata'.dta" _char(34) ",convert.factors=TRUE))" _n _n
if "`columnvar'" != ""{
	file write myfile "plotdata<- list() " _n
	file write myfile "for (i in seq_along(unique(data[," _char(34) "`columnvar'" _char(34) "]))){ " _n
	file write myfile "  sub<- subset(data, `columnvar'==unique(data[," _char(34) "`columnvar'" _char(34) "])[i]) " _n
*	file write myfile "  sub<- sub[!is.na(sub[," _char(34) "`1'" _char(34) "]),] " _n
	file write myfile "  plotdata[[i]] <- sub " _n
	file write myfile "} " _n
}
if "`columnvar'" == ""{
	file write myfile "plotdata<-data " _n
	if "`Pmain'" == "" file write myfile "Pmain<-" _char(34) "`Pmain'" _char(34) "  " _n
}
if "`plab'" != ""{
    tokenize `plab', parse(`sep')
    if "`sep'" ==""{
		file write myfile "Plab1 <-c(" _char(34) "`1'" _char(34) "," _char(34) "`3'" _char(34) ")" _n
		file write myfile "Plab2 <-c(" _char(34) "`2'" _char(34) "," _char(34) "`4'" _char(34) ")" _n
                }
    if "`sep'" !=""{
		file write myfile "Plab1 <-c(" _char(34) "`1'" _char(34) "," _char(34) "`5'" _char(34) ")" _n
		file write myfile "Plab2 <-c(" _char(34) "`3'" _char(34) "," _char(34) "`7'" _char(34) ")" _n
                }
}

if "`xlim'" == ""{
	if "`columnvar'" != ""{
		file write myfile " Xlim <- list() " _n
		file write myfile " for(i in seq_along(unique(data[," _char(34) "`columnvar'" _char(34) "]))){ " _n
		file write myfile "   lores <- floor(min(plotdata[[i]][c(" _char(34) "X`vall'" _char(34) ")],na.rm=TRUE)*100)/100 " _n
		file write myfile "   hires <- ceiling(max(plotdata[[i]][c(" _char(34) "X`valu'" _char(34) ")],na.rm=TRUE)*100)/100 " _n
		file write myfile "   if (lores > 1){ " _n
		file write myfile "     lores <- .8 " _n
		file write myfile "   } " _n
		file write myfile "   if (hires < 1){ " _n
		file write myfile "     hires <- 1.2 " _n
		file write myfile "   } " _n
		file write myfile "   Xlim[[i]] <- c(lores,hires) " _n
		file write myfile " } " _n
	}
	if "`columnvar'" == ""{
		file write myfile "   lores <- floor(min(plotdata[c(" _char(34) "X`vall'" _char(34) ")],na.rm=TRUE)*100)/100 " _n
		file write myfile "   hires <- ceiling(max(plotdata[c(" _char(34) "X`valu'" _char(34) ")],na.rm=TRUE)*100)/100 " _n
		file write myfile "   if (lores > 1){ " _n
		file write myfile "     lores <- .8 " _n
		file write myfile "   } " _n
		file write myfile "   if (hires < 1){ " _n
		file write myfile "     hires <- 1.2 " _n
		file write myfile "   } " _n
		file write myfile "   Xlim <- c(lores,hires) " _n
		}
}
if "`xlim'" != ""{
	file write myfile " Xlim <- list() " _n
	tokenize `xlim', /*parse(`sep')*/
	loc i=1
	while `"`1'"' != ""{
		file write myfile "   Xlim[[`i']] <- c(`1',`2') " _n
		macro shift
		macro shift
		loc i `++i'
	}
	if "`columnvar'" == ""{
		file write myfile "   Xlim <- Xlim[[1]] " _n
	}
}

if "`hadj'" == ""{
	if "`columnvar'" != ""{
		file write myfile " Hadj <- list() " _n
		file write myfile " for(i in seq_along(unique(data[," _char(34) "`columnvar'" _char(34) "]))){ " _n
		file write myfile "   hr <- c(min(plotdata[[i]][," _char(34) "X`val'" _char(34) "], na.rm=TRUE), max(plotdata[[i]][," _char(34) "X`val'" _char(34) "], na.rm=TRUE)) " _n
		file write myfile "   if (hr[2]< 1){ " _n
		file write myfile "     hr <- c(hr[1]-1,0) " _n
		file write myfile "   } else{ " _n
		file write myfile "     if (hr[1] > 1){ " _n
		file write myfile "       hr <- c(0,hr[2]-1) " _n
		file write myfile "     } else{ " _n
		file write myfile "       hr <- c(hr[1]-1,hr[2]-1) " _n
		file write myfile "     } " _n
		file write myfile "   } " _n
		file write myfile "   adj <- mean(hr) " _n
		file write myfile "   Hadj[[i]] <- adj " _n
		file write myfile " } " _n
	}
	if "`columnvar'" == ""{
		file write myfile "   hr <- c(min(plotdata[," _char(34) "X`val'" _char(34) "], na.rm=TRUE), max(plotdata[," _char(34) "X`val'" _char(34) "], na.rm=TRUE)) " _n
		file write myfile "   if (hr[2]< 1){ " _n
		file write myfile "     hr <- c(hr[1]-1,0) " _n
		file write myfile "   } else{ " _n
		file write myfile "     if (hr[1] > 1){ " _n
		file write myfile "       hr <- c(0,hr[2]-1) " _n
		file write myfile "     } else{ " _n
		file write myfile "       hr <- c(hr[1]-1,hr[2]-1) " _n
		file write myfile "     } " _n
		file write myfile "   } " _n
		file write myfile "   adj <- mean(hr) " _n
		file write myfile "   Hadj <- adj " _n
	}
	}
if "`hadj'" != ""{
	file write myfile " Hadj <- list() " _n
	tokenize `hadj',/* parse(`sep')*/
	loc i=1
	while `"`1'"' != ""{
		/*if "`1'"!="`sep'"*/ file write myfile "   Hadj[[`i']] <- c(`1') " _n
		macro shift
		loc i `++i'
	}
	if "`columnvar'" == ""{
		file write myfile "   Hadj <- Hadj[[1]] " _n
	}
}

if "`ppos'" == ""{
	if "`columnvar'" != ""{
		file write myfile " Ppos <- list() " _n
		file write myfile " for(i in seq_along(unique(data[," _char(34) "`columnvar'" _char(34) "]))){ " _n
		file write myfile "   lores <- 3*abs(1-Xlim[[i]][1])/4 " _n
		file write myfile "   hires <- 3*abs(Xlim[[i]][2]-1)/4 " _n
		file write myfile "   if (min(plotdata[[i]][," _char(34) "X`val'" _char(34) "],na.rm=TRUE)>1){ " _n
		file write myfile "     lores <- .4 " _n
		file write myfile "   }  " _n
		file write myfile "   if (max(plotdata[[i]][," _char(34) "X`val'" _char(34) "]<1,na.rm=TRUE)){ " _n
		file write myfile "     hires <- 1/.4 " _n
		file write myfile "   }  " _n
		file write myfile "   Ppos[[i]] <- c(1/(max(c(lores,hires))),max(c(lores,hires))) " _n
		file write myfile " } " _n
	}
	if "`columnvar'" == ""{
		file write myfile "   lores <- 3*abs(1-Xlim[1])/4 " _n
		file write myfile "   hires <- 3*abs(Xlim[2]-1)/4 " _n
		file write myfile "   if (min(plotdata[," _char(34) "X`val'" _char(34) "],na.rm=TRUE)>1){ " _n
		file write myfile "     lores <- .4 " _n
		file write myfile "   }  " _n
		file write myfile "   if (max(plotdata[," _char(34) "X`val'" _char(34) "]<1,na.rm=TRUE)){ " _n
		file write myfile "     hires <- 1/.4 " _n
		file write myfile "   }  " _n
		file write myfile "   Ppos <- c(1/(max(c(lores,hires))),max(c(lores,hires))) " _n
	}
}
if "`ppos'" != ""{
	file write myfile " Ppos <- list() " _n
	tokenize `ppos', /*parse(`sep')*/
	loc i=1
	while `"`1'"' != ""{
		file write myfile "   Ppos[[`i']] <- c(`1',`2') " _n
		macro shift
		macro shift
		loc i `++i'
	}
	if "`columnvar'" == ""{
		file write myfile "   Ppos <- Ppos[[1]] " _n
	}
	}

file write myfile " pdf(file=" _char(34) "`plotname'.pdf" _char(34) ", width =`width', height=`height') " _n
file write myfile " print(Forestplot( " _n
if "`groupvar'"=="" file write myfile " NULL, " _n
if "`groupvar'"!="" file write myfile " " _char(34) "`groupvar'" _char(34) ", " _n
file write myfile " " _char(34) "`rowvar'" _char(34) ", " _n
file write myfile " c(" _char(34) "X`val'" _char(34) "," _char(34) "X`vall'" _char(34) "," _char(34) "X`valu'" _char(34) "), " _n
file write myfile " plotdata, " _n
file write myfile " fval=" _char(34) "X`fval'" _char(34) " " _n
if "`valtab'" != "" file write myfile ", fvaltab=`valtab' " _n
file write myfile " , glab=" _char(34) "`grouplabel'" _char(34) " " _n
file write myfile " , rlab=" _char(34) "`rowlabel'" _char(34) " " _n
if "`columnvar'" != "" file write myfile " , pmain=unique(data[," _char(34) "`columnvar'" _char(34) "]) " _n
if "`columnvar'" == "" & "`columnlabel'" != "" file write myfile " , pmain=" _char(34) "`columnlabel'" _char(34) _n
if "`columnsublabel'" != "" file write myfile " , mtext=" _char(34) "`columnsublabel'" _char(34) _n
file write myfile " , ppos=Ppos " _n
file write myfile " , xlim=Xlim " _n
file write myfile " , hadj=Hadj " _n
if "`xseqn'" != ""{
    local xseqn = subinstr("`xseqn'"," ",",",.)
    file write myfile ", seqn=c(`xseqn') " _n
    }
if "`sublabelside'" != "" file write myfile ", mside=`sublabelside' " _n
if "`vref'" != "" file write myfile ", vref=`vref' " _n
if "`cutx'" != "" file write myfile ", cutx=`cutx' " _n
if "`gcex'" != "" file write myfile ", gcex=`gcex' " _n
if "`rcex'" != "" file write myfile ", rcex=`rcex' " _n
if "`mcex'" != "" file write myfile ", mcex=`mcex' " _n
if "`wpan'" != "" file write myfile ", wpan=c(`wpan') " _n
file write myfile " , log=`log' " _n
file write myfile " , rpos=`rpos' " _n
if "`plab'" != "" file write myfile ", plab1=Plab1 " _n
if "`plab'" != "" file write myfile ", plab2=Plab2 " _n
if "`addcol'"!="" file write myfile ", " _char(34) "`addcol'" _char(34) " " _n
if "`addcollabel'"!="" file write myfile ", " _char(34) "`addcollabel'" _char(34) " " _n
if "`hlines'"=="" file write myfile ", hlines=NULL " _n
if "`hlines'"=="FALSE" file write myfile ", hlines=FALSE " _n
if "`hlines'"!="" & "`hlines'"!="FALSE" file write myfile " hlines=c(`hlines') " _n
file write myfile " )) " _n
file write myfile " dev.off() " _n

file close myfile


di ""
di as text "Running R script, please wait..."
shell "`rcmd'" CMD BATCH `objpath'/makeForestplot.R

*n shell "`rcmd'" CMD BATCH --vanilla `objpath'/mnps.R
*shell echo Starting R, please wait... & "`rcmd'" CMD BATCH --vanilla `objpath'/mnps.R

* check for errors
capture confirm file "`objpath'/makeForestplot.Rout"
if _rc >0 {
        display as error "Error: R did not complete successfully."
}

qui infix str v1 1-1000 using "`objpath'/makeForestplot.Rout", clear
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

qui infix str v1 1-1000 using "`objpath'/makeForestplot.Rout", clear
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


qui cd `"`cwd'"'

end




 /********************/
/** ashell command **/

*! version 1.0 05February2009
cap program drop ashell
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


