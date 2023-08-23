{smcl}
{* *! version 1.3.0  04apr2017}{...}
{vieweralsosee "mnps" "help mnps"}{...}
{vieweralsosee "balance" "help pnps postestimation"}{...}
{viewerjumpto "Syntax" "mnplot##syntax"}{...}
{viewerjumpto "Description" "mnplot##description"}{...}
{viewerjumpto "Options" "mnplot##options"}{...}
{viewerjumpto "Examples" "mnplot##examples"}{...}
{viewerjumpto "Online tutorial" "pmnplot##tutorial"}{...}
{viewerjumpto "References" "mnplot##references"}{...}
{title:Title}


{p2colset 5 20 22 2}{...}
{p2col :{browse "http://www.rand.org/statistics/twang/tutorials.html":mnplot} {hline 2} Balance diagnostic plots} {p_end}
{p2colreset}{...}


{marker syntax}{...}
{title:Syntax}

{p 8 16 2}
{cmd:mnplot} [{cmd:,} {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt :{opt plotname}}{it:{help filename:filename}} for the resulting plots {p_end}
{synopt :{opt plots}}indicator of which type of plot is desired {p_end}

{syntab:Required, but optional after mnps}
{synopt :{opt rcmd}}{it:{help filename:filename}} for the Rscript executable; defaults to the same {it:{help filename:filename}} used in {cmd:mnps} {p_end}
{synopt :{opt inputobj}}{it:{help filename:filename}}  for the R object produced by
          {cmd:mnps} with the propensity score model fitting
          results; defaults to the same {it:{help filename:filename}} used in {cmd:mnps} {p_end}
{synopt :{opt objpath}}folder name for a permanent file of the
          R object; defaults to the same folder used in {cmd:mnps}{p_end}
		  
{syntab:Optional}
{synopt : {opt plotformat}}file format for the resulting plots; default is {cmd:pdf} {p_end}
{synopt : {opt nocolor}}figures will be produced in grayscale{p_end}
{synopt : {opt subset}}subset of the stopping rules that were employed {p_end}
{synopt : {opt nopairwise:max}}plots for the underlying ps fits will be returned. Otherwise, pairwise maxima will be returned. {p_end}
{synopt : {opt treatments}}which treatment levels should be used to produce the figures{p_end}
{synopt : {opt figurerows}}number of rows of figures that should be used {p_end}
{synopt : {opt singleplot}}return only the corresponding plot {p_end}
{synopt : {opt multipage}}print each frame on a different page. {p_end}


{synoptline}

{marker description}{...}
{title:Description}

{phang}
{opt mnplot} generates diagnostic plots available in the twang package of R
     according to the users specifications.
	 
{phang} TWANG is a package of functions in the R Environment for
Statistical Computing and Graphics. The package contains functions
for estimating propensity scores and associated weights using
Generalized Boosting Model and functions for assessing the
covariate balance provided by the resulting weights. {cmd:mnps} implements the functions in the R
package by creating an R script file and running it in R batch mode
and then porting the results back to Stata. To use {cmd:mnps} a user must have R installed on his or her computer. 

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

{dlgtab:Required}


{phang}
{opth plotname(filename)} specifies the {it:{help filename:filename}}  for the resulting plots. The full path can be given. If not, the plot file is placed in the folder specified by {cmd:objpath}.

{phang}
{opt plots}({it:{help strings:string}}) specifies the type of plot is desired. 

{phang}
The options are:

{synoptset 17}{...}
{p2coldent :Name}Description{p_end}
{synoptline}
{synopt :optimize or 1 }Plot of the balance criteria as a function of the GBM iteration{p_end}
{synopt :boxplot or 2 }Boxplots of the propensity scores for the
              treatment and control cases {p_end}
{synopt :es or 3 }Plots of the standardized effect size of the
              covariates before and after weighing{p_end}
{synopt :t or 4 }Plots of the p-values from t-statistics comparing
              means of treated and control subjects for covariates,
              before and after weighting{p_end}
{synopt :ks or 5 }Plots of the p-values from Kolmogorov-Smirnov
              statistics comparing distributions of covariates
              of treated and control subjects, before and
              after weighting{p_end}
{synopt :histogram or 6 }Histogram of weights for treated and control
              subjects (Currently unavailable){p_end}
{synoptline}
{p2colreset}{...}

{dlgtab:Required, but optional after mnps}

{phang}
{opth rcmd(filename)} specifies the {it:{help filename:filename}} for the R executable. If unspecified, defaults to the same {it:{help filename:filename}} used in {cmd:mnps}. Otherwise, defaults to {cmd:Rscript} in Mac OSX and UNIX.

{phang}
{opth inputobj(filename)} specifies the {it:{help filename:filename}}  for the R object produced by
          {cmd:mnps} with the propensity score model fitting
          results. If unspecified, defaults to the same {it:{help filename:filename}} used in {cmd:mnps}

{phang}
{opt objpath}({it:{help strings:string}}) specifies the folder name for a permanent file of the R object.
		  If unspecified, defaults to the same folder name used in {cmd:mnps}  
		  
{dlgtab:Optional}

{phang}
{opt plotformat}({it:{help strings:string}}) specifies the file format for the resulting plots. Typically this
            will match the file extension given in {opt plotname}. If not
            specified by the user it will equal the file extension
            from the {it:{help filename:filename}}  given by {opt plotname}. Valid values
            are {opt jpg}, {opt pdf}, {opt png}, {opt wmf}, and {opt ps}. If an invalid value is specified, the plot will be
            saved as PDF.
            
{phang}
{opth subset(numlist)} restricts the plots to a subset of the stopping
          rules that were employed.  This argument expects a {it:{help numlist:numlist}} of
          the integers from 1 to k, if k {opt stopmethod}'s were used.
	
{phang}
{opt nocolor} specifies if figures will be produced in grayscale. 	

{phang}
{opt nopairwise:max} specifies that plots for the underlying ps fits will be returned. Otherwise, pairwise maxima will be returned.

{phang}
{opt treatments} is only applicable when with {opt nopairwisemax} and plots 3, 4, or 5. The default creates panels for all treatment pairs. 
If one level of the treatment variable is specified, plots comparing that treatment to all others are produced. 
If two levels are specified, a comparison for that single pair is produced.

{phang}
{opt figurerows} specifies the number of rows of figures that should be used

{phang}
{opt singleplot} specifies that only the corresponding plot be returned. For example, specifying {opt singlePlot(2)} will return the second plot.

{phang}
{opt multipage} indicates that each frame of a figure be printed on a different page.
 {p_end}	   

{marker examples}{...}
{title:Examples:}
{pstd}See {help mnps##examples:mnps examples} {p_end}


{marker tutorial}{...}
{title:Online tutorial}

{phang}
{browse "http://www.rand.org/statistics/twang/tutorials.html":Toolkit for Weighting and Analysis of Nonequivalent Groups}

{marker references}{...}
{title:References}

{phang}
McCaffrey, D., G. Ridgeway, and A. Morral. 2004. Propensity score estimation with boosted regression for evaluating causal effects in
observational studies. {it:Psychological Methods} 9(4):403Ð425.
{p_end}

{phang} 
Ridgeway, G., D. McCaffrey, A. Morral, L. Burgette, B. A. Griffin. 2013. Toolkit for Weighting and Analysis of Nonequivalent Groups: A Tutorial for the Twang Package. R package.
{p_end}
