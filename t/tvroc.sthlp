{smcl}
{* *! version 0.5 January 16, 2014 @ 14:13:06}{...}
{cmd:help tvROC}
{hline}

{title:Title}

{hi: tvROC} {hline 2} ROC curve information and AUC for survival data


{title:Syntax}

{phang}

{p 8 17 2}
{opt tvROC} {it: timevar deadvar score} {cmd:,} {opt options}

{title:Options}

{pstd}
{cmd: saving} specifies output data set {it: outfilename}, if it already exists, be overwritten.

{pstd}
{cmd: mshift} specifies shift in score to define a new group, default 1

{pstd}
{cmd: tshift} specifies shift in timevar at which confidence intervals are calculated (if bootstrap option), default 7

{pstd}
{cmd: bootstrap} calculate bootstrap confidence interval, specify number of bootstrap sample, default 0

{pstd}
{cmd: level} significance level, default 0.95

{title:Description}

{pstd}
{cmd: tvROC} calculate time-dependent ROC curves for censored survival data. The code is based in Heagarty, Lumley, and Pepe (2000), Biometrics 56, 337-344.
The c-statistic based on sensitivity and specificity as AUC is reported for each time step.

{title:Examples}

{pstd} See the example file: ~/Code/Stata/1/CNRIIDIeksempel.do

{title:Author}

{p 4 4 2}
{browse "mailto:fls@rn.dk":Flemming Skjøth}, Aalborg University Hospital, Denmark{p_end}
