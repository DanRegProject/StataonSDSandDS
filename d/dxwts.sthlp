{smcl}
{* *! version 1.3.0  04apr2017}{...}
{vieweralsosee "ps" "help ps"}{...}
{vieweralsosee "psplot" "help psplot"}{...}
{vieweralsosee "balance" "help balance"}{...}
{vieweralsosee "dxwts postestimation" "help balance"}{...}
{viewerjumpto "Syntax" "dxwts##syntax"}{...}
{viewerjumpto "Description" "dxwts##description"}{...}
{viewerjumpto "Options" "dxwts##options"}{...}
{viewerjumpto "Examples" "dxwts##examples"}{...}
{viewerjumpto "Online tutorial" "dxwts##tutorial"}{...}
{viewerjumpto "Stored results" "dxwts##results"}{...}
{viewerjumpto "References" "dxwts##references"}{...}
{title:Title}


{p2colset 5 20 22 2}{...}
{p2col :{browse "http://www.rand.org/statistics/twang/tutorials.html":dxwts} {hline 2}}Weight and balance evaluation{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:dxwts} {it:{help varname:treatvar}} {indepvars} [{cmd:,} {it:options}]



{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Estimation}
{synopt :{opt weightvars}}{varlist} of weights to evaluate {p_end}  
{synopt :{opt estimand}}causal effect of interest ({cmd:ATE} or {cmd:ATT}); default is {cmd:ATE} {p_end}    
{synopt :{opt sampw}}{varname} for optional sampling weights {p_end}
{synopt :{opt permtestiters}}non-negative integer giving the number of iterations of the permutation test for the KS statistic; default is {cmd:0} {p_end}
{synopt :{opt rcmd}}file name for the Rscript executable {p_end}

{syntab:Reporting}
{synopt :{opt objpath}} folder name for a permanent file of the
          R object with the log of the R session and files
          created by the macro	{p_end}

{synoptline}
INCLUDE help fvvarlist

{marker description}{...}
{title:Description}

{phang}
{opt dxwts} evaluates balance achieved between two groups by weighting
     using one or more sets of weights provided by the user, for each
     covariate specified by the user. It implements the dxwts function in the twang package of R.

	 
{phang} TWANG is a package of functions in the R Environment for
Statistical Computing and Graphics. The package contains functions
for estimating propensity scores and associated weights using
Generalized Boosting Model and functions for assessing the
covariate balance provided by the resulting weights. {cmd:ps} implements the functions in the R
package by creating an R script file and running it in R batch mode
and then porting the results back to Stata. To use {cmd:ps} a user must have R installed on his or her computer. 

{phang} R is standalone freeware that users can download and install from
The Comprehensive R Archive Network (http://cran.us.r-project.org/).
The software can be installed by clicking on the link for the users
computer platform (e.g., Windows users would click on "Download R
for Windows" and then click on the "base" link to download the
standard R software). Windows users will need to note the directory where the R software is
installed and the name of the executable file. For Windows users
the directory information for the standard installment is "C:\Program Files\R\R-3.0.2\bin\x64"
where 3.0.2 is replaced by the current version of R at the time of
installation. The executable is Rscript.exe for batch implementation.

{marker options}{...}
{title:Options}

{dlgtab:Estimation}

{phang}
{opth sampw(varname)} specifies the optional sampling weights.

{phang}
{opt permtestiters(#)} specifies the number of
          iterations of the permutation test for the KS statistic; a non-negative integer.
          {cmd:permtestiters(0)} specifies that {cmd:ps} returns an
          analytic approximation to the p-value. 
          {cmd:permtestiters(200)} yields precision to within {cmd:3%} if
          the true p-value is {cmd:0.05}. Use {cmd:permtestiters(500)} to be
          within {cmd:2%}. The default is {cmd:0}.

{phang}
{opth rcmd(filename)} specifies the file name for the R executable. Defaults to {cmd:Rscript} in Mac OSX and UNIX.

{phang}
{opth estimand(strings)} specifies the causal effect of interest. Options are {cmd:ATE} (average
          treatment effect), which attempts to estimate the change in
          the outcome if the treatment were applied to the entire
          population versus if the control were applied to the entire
          population, or {cmd:ATT} (average treatment effect on the
          treated), which attempts to estimate the analogous effect,
          averaging only over the treated population. The default
          is {cmd:ATE}.


{dlgtab:Reporting}

{phang}
{opth objpath(strings)} specifies the folder name for a permanent file of the
          R object with the log of the R session and files
          created by the macro.	

{marker examples}{...}
{title:Examples:  estimating propensity scores using logistic regression}

{pstd}Setup{p_end}
{phang2}{cmd:. sysuse auto, clear}{p_end}

{pstd}Fit a logistic regresion model for the propensity of being foreign{p_end}
{phang2}{cmd:. logit foreign weight mpg}{p_end}

{pstd}Estimate the propensity of being foreign{p_end}
{phang2}{cmd:. predict xb, xb}{p_end}
{phang2}{cmd:. replace xb = exp(xb)/(1+exp(xb))}{p_end}

{pstd}Estimate IPTW{p_end}
{phang2}{cmd:. gen iptw = 1/xb}{p_end}
{phang2}{cmd:. replace iptw = 1/(1-xb) if foreign==0}{p_end}

{pstd}Weight and balance evaluation in Mac OSX and UNIX{p_end}
{phang2}{cmd:. dxwts foreign weight mpg, weightvars(iptw) rcmd("Rscript") objpath(~/Documents/temp)}{p_end}

{pstd}Weight and balance evaluation in Windows{p_end}
{phang2}{cmd:. dxwts foreign weight mpg, weightvars(iptw) cmd("C:/Program Files/R/R-3.0.1/bin/x64/Rscript.exe") objpath(C:/temp)}{p_end}

{pstd}Summarize weights and balance{p_end}
{phang2}{cmd:. balance, summary}{p_end}

{pstd}Summarize balance of covariates before weighting{p_end}
{phang2}{cmd:. balance, unweighted}{p_end}

{pstd}Summarize balance of covariates after weighting{p_end}
{phang2}{cmd:. balance, weighted}{p_end}


{marker tutorial}{...}
{title:Online tutorial}

{phang}
{browse "http://www.rand.org/statistics/twang/tutorials.html":Toolkit for Weighting and Analysis of Nonequivalent Groups}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:dxwts} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:dxwts}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(weightname)}}contain the data on the balance of the covariates
                after weighting for each {it:weighname} specified in {cmd:weightvars} {p_end}
{synopt:{cmd:e(unw)}}contains the data on the balance of the covariates
               before weighting. probably need to add another section describing this matrix {p_end}
{synopt:{cmd:e(summary)}}contains the data summarizing the weights and
               the covariate balance.  The matrix contains
               one row for unweighted data and row for
               the weights corresponding to each of the
               stopping rules the user specified. {p_end}

{p2colreset}{...}


{marker references}{...}
{title:References}

{phang}
McCaffrey, D., G. Ridgeway, and A. Morral. 2004. Propensity score estimation with boosted regression for evaluating causal effects in
observational studies. {it:Psychological Methods} 9(4):403Ð425.
{p_end}

{phang} 
Ridgeway, G., D. McCaffrey, A. Morral, L. Burgette, B. A. Griffin. 2013. Toolkit for Weighting and Analysis of Nonequivalent Groups: A Tutorial for the Twang Package. R package.
{p_end}
