{smcl}
{* *! version 1.3.0  04apr2017}{...}
{vieweralsosee "balance" "help balance"}{...}
{vieweralsosee "mnplot" "help mnplot"}{...}
{vieweralsosee "ps" "help ps"}{...}
{vieweralsosee "mnps postestimation" "help balance"}{...}
{viewerjumpto "Syntax" "mnps##syntax"}{...}
{viewerjumpto "Description" "mnps##description"}{...}
{viewerjumpto "Options" "mnps##options"}{...}
{viewerjumpto "Examples" "mnps##examples"}{...}
{viewerjumpto "Online tutorial" "mnps##tutorial"}{...}
{viewerjumpto "Stored results" "mnps##results"}{...}
{viewerjumpto "References" "mnps##references"}{...}
{title:Title}


{p2colset 5 20 22 2}{...}
{p2col :{browse "http://www.rand.org/statistics/twang/tutorials.html":mnps} {hline 2}}Estimate propensity scores and associated weights for multinomial treatment using a Generalized Boosted Model{p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{opt mnps} {it:{help varname:treatvar}} {indepvars} [{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt :{opt sampw}}{varname} for optional sampling weights {p_end}

{syntab:Estimation}
{synopt :{opt ntrees}}number of GBM iterations; default is {cmd:10000} {p_end}
{synopt :{opt intdepth}}maximum depth of variable interactions; default is {cmd:3} {p_end}
{synopt :{opt shrinkage}}shrinkage parameter applied to each tree in the expansion; default is {cmd:0.01} {p_end}
{synopt :{opt permtestiters}}non-negative integer giving the number of iterations of the permutation test for the KS statistic; default is {cmd:0} {p_end}
{synopt :{opt rcmd}}file name for the Rscript executable {p_end}
{synopt :{opt stopmethod}}method or set of methods for measuring and
          summarizing balance across covariates {p_end}
{synopt :{opt estimand}}causal effect of interest ({cmd:ATE} or {cmd:ATT}); default is {cmd:ATE} {p_end}
{synopt :{opt treatatt}}the "treatment" group used in ATT; required with {cmd:estimand(ATT)} {p_end}

{syntab:Reporting}
{synopt :{opt objpath}}folder name for a permanent file of the
          R object with the resulting GBM model fit, a log of
          the R session, and files created by the macro to run
          the estimation{p_end}
{synopt :{opt plotname}}file name for an optional output file of the default
          diagnostic plots {p_end}
{synoptline}
INCLUDE help fvvarlist

{marker description}{...}
{title:Description}

{phang}
{cmd:mnps} estimates propensity scores for multinomial treatments using Generalized Boosted
     Models and evaluates their quality using covariate balance.
     It implements the mnps function in the TWANG package of R.
	 Categorical variables among the {indepvars} need to be
     specified as factor variables; see {help fvvarlist}. 
	 R, and in particular, the TWANG package in R, can be
     slow and require large amounts of memory to process large datasets.
	 For Windows users, unless R has been added to the path environmental variable,
     the full path must be specified in the {cmd:rcmd} option. For example for the
     default setup of R Version 3.2 on Windows 7, the specification
     is {cmd:rcmd(C:/Program Files/R/R-3.2/bin/x64/Rscript.exe)}. The value 3.2 in the example would be replaced by the current
     version number at the time R was installed. For Mac and Unix users, {cmd:rcmd} is optional. Some Mac users may be need to specify
	 {cmd:rcmd(/Library/Frameworks/R.framework/Versions/3.2/Resources/bin/Rscript)}, where again, the value 3.2 would be replaced by the 
	 correct version number at the time of installation. 

{phang} User must place all package files in a location that will be recognized by Stata. This can be acheived
by placing the files in the PERSONAL ado-path directory, which can be identified using {help adopath}. Alternately, the user
can place the files in any directory, and add the directory to ado-path using the command {help adopath} {cmd:+} {it:path_or_directory}.
	 
{phang} WARNING: {cmd:mnps} can take a considerable amount of time to run and no information is provided on its progress.
The standard break button in Stata will not kill the R process, and therefore, will not stop {cmd:mnps}. To stop {cmd:mnps}, 
Windows users simply need to close the terminal window that pops up during execution. Mac users need to kill the R process 
through the Activity Monitor. The Activity Monitor can be found in "/Applications/Utilities".  
	 
{phang} TWANG is a package of functions in the R Environment for
Statistical Computing and Graphics. The package contains functions
for estimating propensity scores and associated weights using
Generalized Boosting Model and functions for assessing the
covariate balance provided by the resulting weights. {cmd:mnps} implements the functions in the R
package by creating an R script file and running it in R batch mode
and then porting the results back to Stata. To use {cmd:mnps} a user must have R installed on his or her computer. 

{phang} R is standalone freeware that users can download and install from
The Comprehensive R Archive Network ({browse "http://cran.us.r-project.org/"}).
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

{dlgtab:Model}

{phang}
{opth sampw(varname)} specifies the optional sampling weights.

{dlgtab:Estimation}

{phang}
{opt ntrees(#)} specifies the number of gbm iterations passed on to 'gbm' in R; a positive integer. Default is {cmd:10000}.

{phang}		  
{opt intdepth(#)} specifies the maximum depth of variable interactions; a positive integer. {cmd:1} implies an additive model, {cmd:2} implies a model with up to 2-way interactions, etc. The default is {cmd:3}.

{phang}
{opt shrinkage(#)} specifies a shrinkage parameter applied to each tree in the gbm expansion. Also known as the learning rate or step-size reduction. The default is {cmd:0.01}.

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
{opth stopmethod(strings)} specifies a method or set of methods for measuring and
          summarizing balance across covariates. Current options are
          {cmd:ks.mean}, {cmd:ks.max}, {cmd:es.mean}, and {cmd:es.max}. {cmd:ks} refers
          to the Kolmogorov-Smirnov statistic and {cmd:es} refers to
          standardized effect size (also called standardized bias or
          standardized differences). These are summarized across
          covariates by either the maximum ({cmd:.max}) or the mean
          ({cmd:.mean}). Multiple stopping rules can be requested. List
          the option name for all methods of interest separated by a space.

{phang}
{opth estimand(strings)} specifies the causal effect of interest. Options are {cmd:ATE} (average
          treatment effect), which attempts to estimate the change in
          the outcome if the treatment were applied to the entire
          population versus if the control were applied to the entire
          population, or {cmd:ATT} (average treatment effect on the
          treated), which attempts to estimate the analogous effect,
          averaging only over the treated population. The default
          is {cmd:ATE}.
		  
{phang}
{opth treatatt(strings)} specifies which level of the {cmd:treatvar}
			will be used as the "treatment" group in ATT. Must be one 
			of the levels of {cmd:treatvar}. Required with {cmd:estimand(ATT)}.


{dlgtab:Reporting}

{phang}
{opth objpath(strings)} specifies the folder name for a file of the
          R object with the resulting GBM model fit, a log of
          the R session, and files created by {cmd:ps} to run
          the estimation. {cmd:ps} also writes an R script file "ps.r" to
     the folder specified by {cmd:objpath}. It then runs the R script which produces temporary
     files: wgt.csv, baltab.csv, and summary.csv in the {cmd:objpath} folder.
     These are read into Stata and used to produce the final output. The
     macro also creates a temporary file ps.Rout which is log of the R
     run.

{phang}
{opth plotname(filename)} specifies the file name for an optional output file of the default
          diagnostic plots. The full path can be given. If not, the plot file is placed in the folder specified by {cmd:objpath}.

{marker examples}{...}
{title:Examples:  estimating propensity scores using GBM}

{pstd}Setup{p_end}
{phang2}{cmd:. sysuse census, clear}{p_end}

{pstd}Fit a GBM model for the propensity of being in a region on a Mac running OS-X{p_end}
{phang2}{cmd:. mnps region divorce marriage medage, stopmethod(es.mean ks.max) objpath(~/Documents/temp)}{p_end}

{pstd}Fit a GBM model for the propensity of being in a region in Windows {p_end}
{phang2}{cmd:. mnps region divorce marriage medage, stopmethod(es.mean ks.max) rcmd("C:/Program Files/R/R-3.0.1/bin/x64/Rscript.exe") objpath(C:/temp)}{p_end}

{pstd}Summarize weights and balance{p_end}
{phang2}{cmd:. balance, summary}{p_end}

{pstd}Summarize balance of covariates before and after weighting{p_end}
{phang2}{cmd:. balance, unweighted weighted}{p_end}

{pstd}Summarize balance of covariates before and after weighting collapsing to covariate{p_end}
{phang2}{cmd:. balance, unweighted weighted collapseto(covariate)}{p_end}

{pstd}Summarize balance of covariates before and after weighting collapsing to stop method{p_end}
{phang2}{cmd:. balance, unweighted weighted collapseto(stop.method)}{p_end}

{pstd}Plot the balance criteria as a function of the GBM iteration (difficult to read){p_end}
{phang2}{cmd:. mnplot, plotname("mnplot1.pdf") plots(1)}{p_end}

{pstd}Same as previous plot, but each figure plotted on separate page {p_end}
{phang2}{cmd:. mnplot, plotname("mnplot1.pdf") plots(1) multipage}{p_end}

{pstd}Generate boxplot (in black and white) of the propensity scores by treatment group {p_end}
{phang2}{cmd:. mnplot, plotname("mnplot2_nocolor.pdf") plots(2) nocolor multipage}{p_end}

{marker tutorial}{...}
{title:Online tutorial}

{phang}
{browse "http://www.rand.org/statistics/twang/tutorials.html":Toolkit for Weighting and Analysis of Nonequivalent Groups}


{marker results}{...}
{title:Stored results}

{pstd}
{cmd:mnps} generates a new variable containing the weights corresponding to each stopping rule specified by the user. The {help varname} of these variables is determined by 
appending the {cmd: estimand} to the end of each {cmd: stopmethod}. For example, specifying {cmd:estimand(ATE)} and {cmd:stopmethod(es.mean es.max)}
will create the weight variables named {cmd:esmeanate} and {cmd:esmaxate}. These can then be used to perform a weighted analysis.

{pstd}
{cmd:mnps} stores the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:mnps}{p_end}
{synopt:{cmd:e(objpath)}}contains the {cmd:objpath} specified in {cmd:mnps}{p_end}
{synopt:{cmd:e(rcmd)}}contains the {cmd:rcmd} specified in {cmd:mnps}{p_end}
{synopt:{cmd:e(Robject)}}contains the location of the R objected generated by {cmd:mnps}{p_end}
{synopt:{cmd:e(estimand)}}ATE or ATT{p_end}


{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(baltable)}}contains the data on the balance of the covariates
                before and after weighting {p_end}
{synopt:{cmd:e(summary1)}}contains the data summarizing the
               the covariate balance before and after weighting.  The matrix contains
               one row for unweighted data and a row for
               the weights corresponding to each of the
               stopping rules the user specified. {p_end}
{synopt:{cmd:e(summary2)}}contains the data summarizing total sample size and effective sample size.  
				The matrix contains one row for each treatment level. {p_end}
			   
			   
{p2colreset}{...}


{marker references}{...}
{title:References}

{phang}
McCaffrey, D., G. Ridgeway, and A. Morral. 2004. Propensity score estimation with boosted regression for evaluating causal effects in
observational studies. {it:Psychological Methods} 9(4):403–425.
{p_end}

{phang} 
Ridgeway, G., D. McCaffrey, A. Morral, L. Burgette, B. A. Griffin. 2013. Toolkit for Weighting and Analysis of Nonequivalent Groups: A Tutorial for the Twang Package. R package.
{p_end}


