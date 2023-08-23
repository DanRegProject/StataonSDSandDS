{smcl}
{* *! version 0.5 January 17, 2014 @ 10:13:06}{...}
{cmd:help tvNRI}
{hline}

{title:Title}

{hi: tvNRI {hline 2} NRI statistics for cencored survival data


{title:Syntax}

{phang}

{p 8 17 2}
{opt tvNRI} {it: timevar deadvar scoreOld scoreNew} {cmd:,} {opt options}

{title:Options}

{pstd}
{cmd: saving} specifies output data set {it: outfilename}, if it already exists, be overwritten.

{pstd}
{cmd: plot} If true plot of survival curves and timeplot of NRI is generated, default false

{pstd}
{cmd: w} specifies weight between case group (NRID1) and non-case group (NRID0): NRIw = w*NRID1+(1-w)*NRID0, default 0.5

{pstd}
{cmd: bootstrap} calculate bootstrap confidence interval, specify number of bootstrap sample, default 0

{pstd}
{cmd: level} significance level, default 0.95

{title:Description}

{pstd}
{cmd: tvROC} calculate time-dependent NRI curves for censored survival data. Ref: Champless, Cummiskey, and CUI, several methods to assess improvement in risk prediction models. Extensions to survival analysis.  Statistics in Medicine (2011), vol 30 (1). p22-38.

{title:Examples}

{pstd} See the example file: ~/Code/Stata/1/CNRIIDIeksempel.do

{title:Author}

{p 4 4 2}
{browse "mailto:fls@rn.dk":Flemming Skjøth}, Aalborg University Hospital, Denmark{p_end}
