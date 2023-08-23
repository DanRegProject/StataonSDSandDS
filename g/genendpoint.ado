/* SVN header
$Date: 2018-08-03 11:33:06 +0200 (fr, 03 aug 2018) $
$Revision: 118 $
$Author: FCNI6683 $
$Id: genEndpoint.ado 118 2018-08-03 09:33:06Z FCNI6683 $
*/
/*
 ***********************************************************************************************;
   #+NAME          :  genEndpoint.ado;
   #+TYPE          :  stata file;
   #+DESCRIPTION   :  Generate endpoint variables for subsequent survival analysis
   #+OUTPUT        :  ;
   #+AUTHOR        :  Flemming Skjøth;
   #+CHANGELOG     :  Date       Initials Status;
                   :  13.10.15   FLS      Created;
                   :  ;
 ***********************************************************************************************;
*/
capture program drop genEndpoint
program define genEndpoint, rclass
version 13
syntax anything, deadDate(string) deadCode(string) [combined] studyEndDate(string)
tokenize `anything'
local name `1'
macro shift 1
local endpoints `*'
egen `name'EndDate = rowmin(`endpoints' `deadDate' `studyEndDate')
format `name'EndDate %d
la var `name'EndDate "Date of end of period at risk for endpoint `name'"
gen `name'Status = 0
if("`endpoints'"=="") replace `name'Status=1 if (`deadCode' & `deadDate'==`name'EndDate)
if("`endpoints'"!=""){
	foreach i of varlist `endpoints'{
	    replace `name'Status=1 if (`i'==`name'EndDate)
	}
}
if("`combined'"=="combined") replace `name'Status=1 if (`deadCode' & `deadDate'==`name'EndDate)
la var `name'Status "Status for endpoint `name'"
display "Endpoint `name' is generated, date: `name'EndDate, status: `name'Status"
display "with the following distribution:"
tab `name'Status
display "Bye from genEndpoint.ado"
end
