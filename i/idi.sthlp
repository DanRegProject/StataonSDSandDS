{smcl}
{* *! version 1.0.0 2009-04-03}{...}
{cmd:help idi}
{hline}

{title:Title}

{p2colset 5 12 14 2}{...}
{p2col:{hi:idi} {hline 2}} calculates IDI measure{p_end}
{p2colreset}{...}


{title:Syntax}

{p 4 17 2 90}
{cmdab:idi}
{it:{depvar} {help varlist:varlist1}}
[{cmd:,} {it:options}]


{synoptset 23 tabbed}{...}
{synopthdr}
{synoptline}
{syntab: Main}

{synopt:{opth pr:vars(varlist:varlist2)}} variable list of new predictor variables
{p_end}

{synoptline}
{p2colreset}{...}

{p 4 6 2 90}
{opt prvars()} is not optional; see below.
{p_end}


{title:Description}

{p 4 4 2 90}
{cmd:idi} calculates the integrated discrimination improvement, which is, {...}
as is {help nri}, a measure that compares the discrimination ability between two {...}
logistic regression prediction models. The command assumes a binary numerical {...}
{depvar} and two sets of numerical and/or categorical covariates for the two {...}
models. The {help xi} function is not yet available and dummy variables {...}
for categorical covariates with more than two categories need to be specified by the user.{break}
Output are estimated IDI with standard error and p value for test of the null hypothesis that IDI in the population is zero.
{break}
Also see: {help nri}.
{p_end}


{title:Options}
{dlgtab:Main}

{p 4 8 2 90}
{opth "prvars(varlist:varlist2)"} identifies the second set of covariates that are added to the second model{break}
{break}
This option must be specified and is {it:not} optional.
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
{varlist:2} should include the covariates that are added to varlist1, together forming covariates in the second prediction model.
{p_end}


{title:Examples IDI}

{p 4 8 2 90}{cmd:.sysuse CANCER}{p_end}
{p 4 8 2 90}{cmd:.idi died age, prvars(drug)}{p_end}

{p 4 8 2 90}{cmd:.sysuse CANCER}{p_end}
{p 4 8 2 90}
{cmd:.idi died age, prvars(drug studytime)}{p_end}


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
Help file (if installed): {help nri} {p_end}

{p 4 4 2 90}
Internet: find macros/program files for calculating IDI and NRI using SAS and R at {break} 
http:www.ucr.uu.se/downloads {p_end}

{p 4 4 2 90}
Internet: find macros/program files for calculating IDI and NRI using Stata, SAS, and R at http://www.ucr.uu.se/downloads
or by typing {break}
{cmd:.net from http://www.ucr.uu.se/downloads/stata}{p_end}

