/* SVN header
$Date: 2022-07-11 11:57:13 +0200 (ma, 11 jul 2022) $
$Revision: 338 $
$Author: wnm6683 $
$Id: table1.ado 338 2022-07-11 09:57:13Z wnm6683 $
*/
/*
 ***********************************************************************************************;
   #+NAME          :  table1.ado;
   #+TYPE          :  stata file;
   #+DESCRIPTION   :  make a org friendly table 1, use $BVAR and optionally $BGRP
   #+OUTPUT        :  ;
   #+AUTHOR        :  Flemming Skjøth;
   #+CHANGELOG     :  Date       Initials Status;
                   :  25.01.16   FLS      Created;
                   :  13.07.16   FLS      Bug in categorical corrected
                   :  07.08.2017 FLS      Corrected not proper check for no by() option and added saving option
 ***********************************************************************************************;
*/
capture program drop table1
program define table1, nclass byable(recall)
version 13
syntax anything [if] [fweight pweight aweight iweight], [by(string) test(string) balance(string) sep(string) fewdata(integer 5) saving(string) append all msdmax varnames q(real 0.25) LANdscape size(string) missing]
loc n : word count `anything'
loc ntest = mod(`n',2)
if ("`ntest'"!="0"){
    dis as err "Variable list not correctly specified n=`ntest', remember alternating: 'variable' 'type' "
 exit 100
}
tempfile savemydata
qui save `savemydata', replace
loc outrow 0
if _by(){
	qui keep if `_byindex'==_byindex()
}

if "`if'" != "" qui keep `if'
if "`sep'"=="" loc sep char(124)
if "`test'"=="" loc test FALSE
if "`balance'"=="" loc balance FALSE
if "`by'"=="" {
    loc test FALSE
    loc balance FALSE
    loc all all
}
loc test = strupper("`test'")
loc balance = strupper("`balance'")
if (("`test'" != "TRUE" & "`test'" != "FALSE") | ("`balance'" != "TRUE" & "`balance'" != "FALSE")){
    dis as err "Only TRUE or FALSE valid for test and balance options"
 exit 100
}
if "`missing'"=="nomissing" loc missing
if (`q'<0 | `q'>1) {
    dis as err "Quantile specification out of limit [0,1] : q=`q'"
    exit 100
}
loc qu=100*(1-`q')
loc ql=100*`q'
loc n= `n'/2
loc BVARloc
loc BVARMloc
foreach i of numlist 1/`n'{
  loc nn = (`i'*2)-1
  loc b : word `nn' of `anything'
  loc nn = `i'*2
  loc b2 : word `nn' of `anything'
  loc BVARloc = "`BVARloc'"  + " `b'"
  loc BVARMloc = "`BVARMloc'" + " `b2'"
}
if "`by'"!=""{
    tempvar catby
    cap encode `by', gen(`catby')
    if _rc==0 {
        drop `by'
        rename `catby' `by'
    }
    qui levelsof `by', local(grp)
    loc ngrp : word count `grp'
}
if "`if'" != "" dis `"Table generated with population restriction: ~`if'.~"'
if "`weight'`exp'" != "" dis `"Table generated with weight instruction: ~`weight'`exp'.~"'
if "`landscape'"=="landscape" dis "#+LATEX: \begin{landscape}"
if "`size'"!="" dis "#+LATEX: {\\`size' "
loc i=-1
foreach x in head N `BVARloc'{
    loc fewdataflag=0
    loc first=1
    loc last=0
    if(`i'>0){
        loc thisVarM= `: word `i' of `BVARMloc''
        if (`thisVarM'==1){
            tempvar catx
            cap encode `x', gen(`catx')
            if _rc==0 {
                drop `x'
                rename `catx' `x'
            }
            qui levelsof `x', local(levels)
            loc nlevels : word count `levels'
        }
    }
    if "`by'" != ""{
        loc gi 0
        foreach g of local grp{
            preserve
            loc gi=`gi'+1
            loc nl _continue
            loc head : label (`by') `g'
            if(`i'<=0){
                cap keep if `by'=="`g'"
                cap keep if `by'==`g'
            }
            else{
                if (`thisVarM'!=1){
                    cap keep if `by'=="`g'"
                    cap keep if `by'==`g'
                }
            }
          /* Header */
              if(`i'==-1){
                  if(`first'==1){
                      loc row `sep' "`by'" `sep' `sep'
                      loc seprow `sep' "-----" `sep' "----" `sep'
                  }
                  loc row `row' "`head'" `sep'
                  loc seprow `seprow' "----" `sep'
              }
          /* N line */
              if(`i'==0){
                  if (`first'==1){
                      loc row `sep' "N" `sep' `sep'
                      loc erow `sep' "N" `sep' `sep'
                      loc srow  N `sep' `sep'
                      loc esrow  N `sep' `sep'
                  }
                  qui count
                  loc n = r(N)
                  if 0<`n' & `n'<`fewdata' loc fewdataflag 1
                  if 0<`n' & `n'<`fewdata' loc row `row' "- (<`fewdata')" `sep'
                  if 0==`n' | `n'>=`fewdata' loc row `row' %4.0f `=`n'' `sep'
                  loc erow `erow' "- (<`fewdata')" `sep'
                  loc srow `srow' `sep' `=`n'' `sep' `sep' `sep' `sep'
                  loc esrow `esrow' `sep' "." `sep' `sep' `sep' `sep'
              }
          if(`i'>0){
              loc nm ="`x'"
			  global truename `nm'
			  if "`varnames'" == "varnames"{
				tablesnames `nm', outdir($LocalOutDir)
			  }
              if `i'==1{
                  loc _mu`gi'
                  loc _sd`gi'
              }
              /*Boolean*/
                  if(`thisVarM'==0){
                      qui levelsof `x'
                                            /* summarize does not allow pweight thus change to iweight */
                      loc suw `weight'
                      if "`weight'"=="pweight" loc suw iweight
                      qui su `x' [`suw'`exp']
                      loc n = r(sum)
                      loc N = r(sum_w)
                      loc m = r(mean)
                      if (`N'==0){
                          loc N 1
                          loc n 0
                          loc m 0
                      }
                      if 0<`n' & `n'<`fewdata' loc fewdataflag 1
                      if ("`balance'"=="TRUE"){
                          loc _mu`gi'=`m'
                          loc _sd`gi'=sqrt(`_mu`gi''*(1-`_mu`gi''))
                      }
                      if (`first'==1){
                          loc row `sep' "$truename %(N)" `sep' "" `sep'
                          loc erow `row'
                          loc srow $truename `sep' `sep'
                          loc esrow `srow'
                      }
                      if 0<`n' & `n'<`fewdata' loc row `row' "- (<`fewdata')" `sep'
                      if 0==`n' | `n'>=`fewdata' loc row `row' %3.1f `=`m' *100' " (" %1.0f `=`n'' ")" `sep'
                      loc erow `erow' "- (<`fewdata')" `sep'
                      loc srow `srow' `=`m' *100' `sep' `=`n'' `sep' `sep' `sep' `sep'
                      loc esrow `esrow' " . " `sep' " . " `sep' `sep' `sep' `sep'
                  }
              /*Categorical*/
                  if(`thisVarM'==1){
                      loc rc=0
                                            /* tabulate does not allow pweight thus change to iweight */
                      loc taw `weight'
                      if "`weight'"=="pweight" loc taw iweight
                      loc ifmis
                      if "`missing'"=="" loc ifmis if `x'<.
                      qui ta `x' `by' [`taw'`exp'] `ifmis', matcell(mattab) `missing'
                      cap drop _`x'
                      svmat mattab, name(_`x')
                      qui su _`x'`gi' if _`x'`gi'>0
                      loc N = r(sum)
                      loc Nmin = r(min)
                      foreach y of local levels{
                          loc levlab : label (`x') `y'
                          loc rc=`rc'+1
                          loc n=_`x'`gi'[`rc']
                          if("`n'"=="") loc n 0
                          if (`N'==0){
                              loc N 1
                              loc n 0
                          }
                          if  0<`n' & `n'<`fewdata' loc fewdataflag 1
                          if ("`balance'"=="TRUE"){
                              loc _mu`gi'`rc'=.
                              loc _sd`gi'`rc'=.
                              loc _mu`gi'`rc'=`n'/`N'
                              loc _sd`gi'`rc'=sqrt(`_mu`gi'`rc''*(1-`_mu`gi'`rc''))
                          }
                          if (`first'==1){
                              loc row`rc' `sep' "$truename" `sep' "`y' `levlab'" `sep'
                              loc erow`rc' `row`rc''
                              loc srow`rc' $truename `sep' `y' `levlab' `sep'
                              loc esrow`rc' `srow`rc''
                          }
                          if `Nmin'<`fewdata' loc row`rc' `row`rc'' "- (<`fewdata')" `sep'
                          if `Nmin'>=`fewdata' loc row`rc' `row`rc'' %3.1f `=`n'/`N'*100' " (" %1.0f `=`n'' ")" `sep'
                          loc erow`rc' `erow`rc'' "- (<`fewdata')" `sep'
                          loc srow`rc' `srow`rc'' `=`n'/`N'*100' `sep' `=`n''  `sep' `sep' `sep' `sep'
                          loc esrow`rc' `esrow`rc'' " . " `sep' " . " `sep' `sep' `sep' `sep'
                      }
                  }
              /* Continous : mean(sd) */
                  if(`thisVarM'==2){
                      /* summarize does not allow pweight thus change to iweight */
                      loc suw `weight'
                      if "`weight'"=="pweight" loc suw iweight
                      qui su `x'  [`suw'`exp']
                      if ("`balance'"=="TRUE"){
                          loc _mu`gi'=r(mean)
                          loc _sd`gi'=r(sd)
                      }
                      if  0<r(N) & r(N)<`fewdata' loc fewdataflag 1
                      if (`first'==1){
                          loc row `sep' "$truename mean(sd)" `sep' `sep'
                          loc erow `row'
                          loc srow  ${truename}mean `sep' `sep'
                          loc esrow `srow'
                      }
                      if  0<r(N) & r(N)<`fewdata' loc row `row' "<`fewdata' (-)" `sep'
                      if  0==r(N) | r(N)>=`fewdata' loc row `row' %2.1f `=r(mean)' " (" %2.1f `=r(sd)' ")" `sep'
                      loc erow `erow' "<`fewdata' (-)" `sep'
                      loc srow `srow' `=r(mean)' `sep' `sep' `=r(sd)' `sep' `sep' `sep'
                      loc esrow `esrow' " . " `sep' `sep' " . " `sep' `sep' `sep'
                  }
              /* Continous : median(1st-3rd) */
                  if(`thisVarM'==3){
                      /* summarize does not allow pweights thus change to iweights */
                      loc suw `weight'
                      if "`weight'"=="pweight" loc suw iweight
                      qui su `x'  [`suw'`exp'],
                      if ("`balance'"=="TRUE"){
                          loc _mu`gi'=r(mean)
                          loc _sd`gi'=r(sd)
                      }
                      qui su `x'  , detail
                      if 0<r(N) & r(N)<`fewdata' loc fewdataflag 1
                      if (`first'==1){
                          loc row `sep' "$truename median(IQR)" `sep' `sep'
                          loc erow `row'
                          loc srow ${truename}IQR `sep' `sep'
                          loc esrow `srow'
                      }
                      if 0<r(N) & r(N)<`fewdata' loc row `row' "< `fewdata' (- - -)" `sep'
                      if 0==r(N) | r(N)>=`fewdata' loc row `row' %2.1f `=r(p50)' " (" %2.1f `=r(p`ql')' "-" %2.1f `=r(p`qu')' ")" `sep'
                      loc erow `erow' "<`fewdata' (- - -)" `sep'
                      loc srow `srow' `=r(p50)' `sep' `sep' `sep' `=r(p`ql')'  `sep'  `=r(p`qu')'  `sep'
                      loc esrow `esrow' " . " `sep' `sep' `sep' " . "  `sep' " . " `sep'
                  }
          }
          restore
          loc first=0
      }
  }
  loc nl
  loc last=1
  if "`all'" != "" loc head "All"
/* Header */
if(`i'==-1){
  if(`first'==1){
   loc row `sep' "`by'" `sep' `sep'
   loc seprow `sep' "-----" `sep' "----" `sep'
  }
  if "`all'" != "" {
      loc row `row' "`head'" `sep'
      loc seprow `seprow' "----" `sep'
  }
  if `last'==1 & "`test'"=="TRUE"{
    loc row `row' "P-value" `sep'
    loc seprow `seprow' "----" `sep'
  }
            if `last'==1 & "`balance'"=="TRUE"{
    loc row `row' "StdDif" `sep'
    loc seprow `seprow' "----" `sep'
  }
  di `row'
            if "`saving'"!=""{
                loc headoutrow `row'
            }
  di `seprow'
}
/* N line */
if(`i'==0){
  if (`first'==1){
      loc row `sep' "N" `sep' `sep'
      loc srow N `sep' `sep'
  }
  qui count
  loc n = r(N)
  if 0<`n' & `n'<`fewdata' loc fewdataflag 1
  if "`all'" != ""{
      loc row `row' %4.0f `=`n'' `sep'
      loc srow `srow' `sep' `=`n''
  }
  if "`test'"=="TRUE"{
    loc row `row' `sep'
    loc srow `srow' `sep'
  }
  if ("`balance'"=="TRUE"){
      loc row `row' `sep'
      loc srow `srow' `sep'
  }
  di `row'
  if "`saving'"!=""{
      loc outrow = `outrow'+1
      loc out`outrow' `srow'
  }
}
if(`i'>0){
  loc nm ="`x'"
  /*Boolean*/
  if(`thisVarM'==0){
      /* summarize does not allow pweight thus change to iweight */
                      loc suw `weight'
      if "`weight'"=="pweigth" loc suw iweight
      cap su `x'  [`suw'`exp']
      loc n = r(sum)
      loc N = r(sum_w)
      loc m = r(mean)
      if (`N'==0){
          loc N 1
          loc n 0
          loc m 0
      }
      if 0<`n' & `n'<`fewdata' loc fewdataflag 1
      if (`first'==1){
          loc row `sep' "`nm' %(N)" `sep' "" `sep'
          loc erow `row'
          loc srow `nm' `sep' `sep'
          loc esrow `srow'
      }
      if "`all'" != "" {
          loc row `row' %3.1f `=`m' *100' " (" %1.0f `=`n'' ")" `sep'
          loc erow `erow' "-  (<`fewdata')" `sep'
          loc srow `srow' `=`m' *100' `sep' `=`n'' `sep' `sep' `sep' `sep'
          loc esrow `esrow' " . " `sep' " . " `sep' `sep' `sep' `sep'
      }
      if("`test'"=="TRUE"){
          cap qui tab2 `x' `by', exact
          if _rc==0{
              loc row `row' %5.4f `=r(p_exact)' `sep'
              loc srow `srow' `=r(p_exact)' `sep'
          }
          else{
              qui tab2 `x' `by', chi2
              loc row `row' %5.4f `=r(p)' `sep'
              loc srow `srow' `=r(p)' `sep'
          }
      }
      if("`balance'"=="TRUE"){
          loc mdif=abs((`_mu1'-`_mu2'))/sqrt((`_sd1'*`_sd1'+`_sd2'*`_sd2')/2)
          if (`ngrp'>2){
              loc ngrpm1 =`ngrp'-1
              foreach i1 of numlist 1/`ngrpm1'{
                  loc ip1 =`i1'+1
                  foreach i2 of numlist `ip1'/`ngrp'{
                      loc mdif=max(`mdif',abs((`_mu`i1''-`_mu`i2''))/sqrt((`_sd`i1''*`_sd`i1''+`_sd`i2''*`_sd`i2'')/2))
                  }
              }
          }
          loc row `row' %5.4f `=`mdif'' `sep'
          loc srow `srow' `=`mdif'' `sep'
      }
      if(`fewdataflag' & "`all'" != ""){
          loc row `erow'
          loc srow `esrow'
      }
      di `row'
      if "`saving'"!=""{
          loc outrow = `outrow'+1
          loc out`outrow' `srow'
      }
  }
  /*Categorical*/
  if(`thisVarM'==1){
    loc rc=0
                          /* tabulate does not allow pweight thus change to iweight */
                      loc taw `weight'
    if "`weight'"=="pweight" loc taw iweight
    loc ifmis
    if "`missing'"=="" loc ifmis if `x'<.
    qui ta `x'  [`taw'`exp'] `ifmis', matcell(mattab) `missing'
    cap drop _`x'
    svmat mattab, name(_`x')
    qui su _`x'
    loc N = r(sum)
    foreach y of local levels{
      loc levlab : label (`x') `y'
      loc rc=`rc'+1
      loc n=_`x'[`rc']
      if("`n'"=="") loc n 0
      if (`N'==0){
          loc N 1
          loc n 0
      }
      if 0<`n' & `n'<`fewdata' loc fewdataflag 1
      if(`first'==1){
              loc row`rc' `sep' "`nm'" `sep' "`y' `levlab'" `sep'
              loc erow`rc' `row`rc''
              loc srow`rc' `nm' `sep' `y' `levlab' `sep'
              loc esrow`rc' `srow`rc''
          }
      if "`all'" != "" {
          loc row`rc' `row`rc'' %3.1f `=`n'/`N'*100' " (" %1.0f `=`n'' ")" `sep'
          loc erow`rc' `erow`rc'' " - (<`fewdata') " `sep'
          loc srow`rc' `srow`rc'' `=`n'/`N'*100' `sep' `=`n'' `sep'
          loc esrow`rc' `esrow`rc'' " . " `sep' " . " `sep'
      }
      if("`test'"=="TRUE"){
          if `rc'==1  {
              qui tab2 `x' `by', chi2
              loc row1 `row1' %5.4f `=r(p)' `sep'
              loc srow1 `srow1' `=r(p)' `sep'
          }
          if `rc'>1  {
              loc row`rc' `row`rc'' `sep'
              loc srow`rc' `srow`rc'' `sep'
          }
      }
      if("`balance'"=="TRUE"){
          loc mdif`rc'=abs((`_mu1`rc''-`_mu2`rc''))/sqrt((`_sd1`rc''*`_sd1`rc''+`_sd2`rc''*`_sd2`rc'')/2)
		  if "`mdif`rc''"=="." loc mdif`rc' 0
          if (`ngrp'>2){
              loc ngrpm1 =`ngrp'-1
              foreach i1 of numlist 1/`ngrpm1'{
                  loc ip1 =`i1'+1
                  foreach i2 of numlist `ip1'/`ngrp'{
                      loc mdif`rc'=max(`mdif`rc'',abs((`_mu`i1'`rc''-`_mu`i2'`rc''))/sqrt((`_sd`i1'`rc''*`_sd`i1'`rc''+`_sd`i2'`rc''*`_sd`i2'`rc'')/2))
                  }
              }
          }
          if `rc' == `nlevels'{
              if "`msdmax'" != ""{
                  foreach rcx of numlist 1/`rc'{
                      loc mdif1 = max(`mdif1', `mdif`rcx'')
                      if `rcx'!=1 loc mdif`rcx' .
                  }
              }
              foreach rcx of numlist 1/`rc'{
                  loc row`rcx' `row`rcx'' %5.4f `=`mdif`rcx''' `sep'
                  loc srow`rcx' `srow`rcx'' `=`mdif`rcx''' `sep'
              }
          }
      }

    }
    foreach y of numlist 1/`rc'{
        if(`fewdataflag' & "`all'" != ""){
            loc row`y' `erow`y''
            loc srow`y' `esrow`y''
        }
        di `row`y''
        if "`saving'"!=""{
            loc outrow = `outrow'+1
            loc out`outrow' `srow`y''
        }
    }
}
  /* Continous : mean(sd) */
  if(`thisVarM'==2){
   /* summarize does not allow pweights thus change to iweights */
        loc suw `weight'
   if "`weight'"=="pweight" loc suw iweight
   qui su `x'  [`suw'`exp']
   if 0<r(N) & r(N)<`fewdata' loc fewdataflag 1
   if(`first'==1){
       loc row `sep' "`nm' mean(sd)" `sep' `sep'
       loc erow `row'
       loc srow `nm'mean `sep'
       loc esrow `srow'
   }
   if "`all'" != "" {
       loc row `row' %2.1f `=r(mean)' " (" %2.1f `=r(sd)' ")" `sep'
       loc erow `erow' "<`fewdata' (-)" `sep'
       loc srow `srow' `=r(mean)' `sep' `sep' `=r(sd)' `sep' `sep' `sep'
       loc esrow `esrow' " . " `sep' `sep' " . " `sep' `sep' `sep'
   }
    if("`test'"=="TRUE"){
        qui reg `x' i.`by'  [`weight'`exp']
        loc row `row' %5.4f `=Ftail(e(df_m),e(df_r),e(F))' `sep'
        loc erow `erow' " - " `sep'
        loc srow `srow' `=Ftail(e(df_m),e(df_r),e(F))' `sep'
        loc esrow `esrow' " . " `sep'
    }
    if("`balance'"=="TRUE"){
        loc mdif=abs((`_mu1'-`_mu2'))/sqrt((`_sd1'*`_sd1'+`_sd2'*`_sd2')/2)
        if (`ngrp'>2){
            loc ngrpm1 =`ngrp'-1
            foreach i1 of numlist 1/`ngrpm1'{
                loc i1p1 =`i1'+1
                foreach i2 of numlist `i1p1'/`ngrp'{
                    loc mdif=max(`mdif',abs((`_mu`i1''-`_mu`i2''))/sqrt((`_sd`i1''*`_sd`i1''+`_sd`i2''*`_sd`i2'')/2))
                }
            }
        }
        loc row `row' %5.4f `=`mdif'' `sep'
        loc erow `erow' " - " `sep'
        loc srow `srow' `=`mdif'' `sep'
        loc esrow `esrow' " . " `sep'
    }
    if(`fewdataflag' & "`all'" != ""){
        loc row `erow'
        loc srow `esrow'
    }
    di `row'
    if "`saving'"!=""{
            loc outrow = `outrow'+1
            loc out`outrow' `srow'
        }
  }
  /* Continous : median(1st-3rd) */
      if(`thisVarM'==3){
          qui su `x', detail
          if 0<r(N) & r(N)<`fewdata' loc fewdataflag 1
          if(`first'==1){
              loc row `sep' "`nm' median(IQR)" `sep' `sep'
              loc erow `row'
              loc srow `nm'IQR `sep' `sep'
              loc esrow `srow'
          }
          if "`all'" != "" {
              loc row `row' %2.1f `=r(p50)' " (" %2.1f `=r(p`ql')' "-" %2.1f `=r(p`qu')' ")" `sep'
              loc erow `erow' "<`fewdata' (- - -)" `sep'
              loc srow `srow' `=r(p50)' `sep' `sep' `sep' `=r(p`ql')' `sep' `=r(p`qu')' `sep'
              loc esrow `esrow' " . " `sep' `sep' `sep' " . " `sep' " . " `sep'
          }
          if("`test'"=="TRUE"){
              qui kwallis `x'  , by(`by')
              loc row `row' %5.4f `=chi2tail(r(df),r(chi2))' `sep'
              loc erow `erow' " - " `sep'
              loc srow `srow'  `=chi2tail(r(df),r(chi2))' `sep'
              loc esrow `esrow' " . " `sep'
          }
          if("`balance'"=="TRUE"){
              loc mdif=abs((`_mu1'-`_mu2'))/sqrt((`_sd1'*`_sd1'+`_sd2'*`_sd2')/2)
              if (`ngrp'>2){
                  loc ngrpm1 =`ngrp'-1
                  foreach i1 of numlist 1/`ngrpm1'{
                      loc i1p1 =`i1'+1
                      foreach i2 of numlist `i1p1'/`ngrp'{
                          loc mdif=max(`mdif',abs((`_mu`i1''-`_mu`i2''))/sqrt((`_sd`i1''*`_sd`i1''+`_sd`i2''*`_sd`i2'')/2))
                      }
                  }
              }
              loc row `row' %5.4f `=`mdif'' `sep'
              loc erow `erow' " - " `sep'
              loc srow `srow' `=`mdif'' `sep'
              loc esrow `esrow' " . " `sep'
          }
          if(`fewdataflag' & "`all'" == "all"){
              loc row `erow'
              loc srow `esrow'
          }
          di `row'
          if "`saving'"!=""{
              loc outrow = `outrow'+1
              loc out`outrow' `srow'
          }
      }
}
    loc i=`i' +1
}
if "`size'"!="" dis "#+LATEX: }"
if "`landscape'"=="landscape" dis "#+LATEX: \end{landscape}"
di _n(2)
if "`saving'"!=""{
    dis "Table content stored in : ~`saving'~."
    qui{
        drop _all
        set obs `outrow'
        gen string=""
        foreach i of numlist 1/`outrow'{
            replace string = `"`out`i''"' if _n==`i'
        }
        split string, parse(`sep') destring gen(V)
		qui describe
		local no_vars = `r(k)'-1
		destring V3 - V`no_vars', replace force
        drop string
        cap tostring V2, replace
		if "`append'" == ""{
			save `saving', replace
		}
		else{
			tempfile mytable1
			save `mytable1', replace
			use  `saving', clear
			append using `mytable1'

			/*remove duplicate observations*/
			duplicates drop

			save `saving', replace
		}

    }
}
use `savemydata', replace
end
