{smcl}
{* *! version 1.1.0 2011-09-27}{...}
{cmd:help nri}
{hline}

{title:Title}

{p2colset 5 12 14 2}{...}
{p2col:{hi:nri} {hline 2}} calculates NRI measure{p_end}
{p2colreset}{...}


{title:Syntax}

{p 8 17 2 90}
{cmd:nri1} {depvar} {varlist:1}, prvars({varlist:2}) cut(#)

{p 8 17 2 90}
{cmd:nri2} {depvar} {varlist:1}, prvars({varlist:2}) cut(# #)

{p 8 17 2 90}
{cmd:nri3} {depvar} {varlist:1}, prvars({varlist:2}) cut(# # #)


{synoptset 23 tabbed}{...}
{synopthdr}
{synoptline}
{syntab: Main}

{synopt:{opth pr:vars(varlist:varlist2)}} variable list of new predictor variables
{p_end}
{synopt:{opth cut(#)}} cutoff probabilities (in %) separating risk categories 
{p_end}

{synoptline}
{p2colreset}{...}

{p 4 6 2 90}
{opt prvars()} and {opt cut(#)} are not optional; see below.
{p_end}


{title:Description}

{p 4 4 2 90}
{cmd:nri} calculates the net reclassification improvement, which is, {...}
as is {help idi}, a measure that compares the discrimination ability between two {...}
logistic regression prediction models. For calculation of NRI {...}
the cutoff probabilities separating risk categories are input parameters. {...}
The command assumes a binary numerical {depvar} and two sets of {...}
numerical and/or categorical covariates for the two {...}
models. The {help xi} function is not yet available and dummy variables {...}
for categorical covariates with more than two categories need to be specified by the user.{break}
Output are estimated NRI with standard error and p value for test of the null hypothesis that NRI in the population is zero, and the reclassification table.
{break}
Also see: {help idi}.
{p_end}


{title:Options}
{dlgtab:Main}

{p 4 8 2 90}
{opth "prvars(varlist:varlist2)"} identifies the second set of covariates that are added to the second model{p_end}

{p 4 8 2 90}
{opth "cut(#)"} identifies the the cutoff probability or probabilities separating risk categories and should be given in %. The number of cutoffs = (number of risk categories - 1). 
{break}
For {cmd:nri1}, one cut limit is specified; for {cmd:nri2} two cut limits are specified; for {cmd:nri3} three cut limits are specified.
{break}
These option must be specified and are {it:not} optional.
{p_end}

{p 4 4 2 90}
Specify at least one covariate in {varlist:2}
{p_end}



{title:Remark}

{p 4 4 2 90}
{depvar} should be numerical and binary, coded as 1=outcome, 0=no outcome. {p_end}

{p 4 4 2 90}
{varlist:1} should include covariates for the first prediction model.{p_end}

{p 4 4 2 90}
{varlist:2} should include the covariates that are added to varlist1, together forming covariates in the second prediction model.{p_end}

{p 4 4 2 90}
If cut limits are not chosen carefully or do not represent clinically relevant categories, matrices may end up empty and you will receive an error message.
{p_end}




{title:Examples NRI}

{p 4 8 2 90}{cmd:.sysuse cancer}{p_end}
{p 4 8 2 90}{cmd:.nri1 died age, prvars(drug studytime) cut(50)}  {p_end}

{p 4 8 2 90}{cmd:.sysuse cancer}{p_end}
{p 4 8 2 90}
{cmd:.nri2 died age studytime, prvars(drug) cut(50 70)}{p_end}

{p 4 8 2 90}{cmd:.webuse hospid2.dta} // from http://www.stata-press.com/data/r11 {p_end}
{p 4 8 2 90}
{cmd:.xi: nri3 low age i.race smoke, prvars(ptl ht ui ftv) cut(20 45 60)}{p_end}


{title:Author}

{p 4 4 2 60}
This command was written by Liisa Byberg, Department of Surgical Sciences, Orthopedics unit, and Uppsala Clinical Research Center, Uppsala University, Sweden.{p_end}


{title:Reference}

{p 4 4 2 90}
Pencina MJ, D' Agostino RB Sr, D' Agostino RB Jr, Vasan RS. {break}
Evaluating the added predictive ability of a new marker: {break}
From area under the ROC curve to reclassification and beyond. {break}
Stat Med. 2008 Jan 30 27(2):157-72 discussion 207-12.
{p_end}


{title:Also see}

{p 4 4 2 90}
Help file (if installed): {help idi} {p_end}

{p 4 4 2 90}
Internet: find macros/program files for calculating IDI and NRI using Stata, SAS, and R at http://www.ucr.uu.se/en/index.php/epistat/program-code
{p_end}



