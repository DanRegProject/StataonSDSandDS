{smcl}
{cmd:help stnri} {...}
{right:also see:  {help stcuminc}   {help stpcuminc}}
{hline}

{title:Title}

{p 4 18 2}
{hi: stnri} {hline 2} Net reclassification improvement for survival data

{title:Syntax}

{p 8 25 2}
{cmd:stnri} {varname:1} {varname:2} {ifin} {cmd:,}
{opt a:t(real)}
[ {it: options} ]
{p_end}

{synoptset 19 tabbed}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt a:t(real)}}time point at which to calculate net reclassification statistics {p_end}
{synopt:{opt c:ompete(varname)}}variable indicating by the value 1 censoring times corresponding to competing events  {p_end}
{synopt:{opt cat:egorical}}calculate categorical (instead of continuous) net reclassification statistics; see the description for details
{p_end}
{synopt:{it:{help bootstrap:options1}}}options for bootstrap
{p_end}

{syntab:Reporting}
{synopt:{opt no:key}}do not display key for regression results {p_end}
{synoptline}
{p 4 6 2}
You must {cmd:stset} your data before using {cmd:stnri}; see {help stset}.{p_end}


{title:Description}

{pstd} {cmd: stnri} calculates net reclassification
statistics for risk scores in a survival outcome setting. Cumulative event probabilities (conditionally on score/reclassification status) are
estimated by regressing on cumulative incidence pseudovalues [1], taking into account competing
risks. Bootstrapping is used for variance estimation. {p_end}

{pstd}By default, {cmd: stnri} calculates the continuous net
reclassification improvement described [2]; in which case {it:varname1}
should correspond to the old risk score and {it:varname2} should
correspond to the new risk score.  {p_end}

{pstd}If the option {cmd: categorical} is specified, {cmd: stnri}
calculates the categorical net reclassification improvement; in which
case {it: varname1} should indicate (by the value 1) the
up-reclassified subjects, and {it: varname2} should indicate (by the value 1) the down-reclassified
subjects.  {p_end}

{title:Examples}

{pstd}Setup{p_end}

{phang2}{cmd:. webuse hypoxia}{p_end}

{pstd}Declare data to be survival-time data and declare the failure event of
    interest, that is, the event to be modeled{p_end}

{phang2}{cmd:. stset dftime, failure(failtype==1)}{p_end}

{pstd}Two simple risk scores {p_end}

{phang2}{cmd:. generate oldrisk=age}{p_end}
{phang2}{cmd:. generate newrisk=age+hgb}{p_end}

{pstd}Calculate net reclassification statistics at time 8 with {cmd:failtype==2} as a competing event {p_end}

{phang2}{cmd:. generate c=(failtype==2)}{p_end}
{phang2}{cmd:. stnri oldrisk newrisk, at(8) reps(250)}{p_end}

{title:Saved results}

{pstd}  {cmd:stnri} saves the same
information as {cmd:bootstrap} in {cmd:e()}; see {help bootstrap} for details.

{title:References}

{pstd}[1]. Klein JP, Andersen PK (2005). {it:Regression modeling of competing risks data based on pseudovalues of the cumulative incidence function.}. Biometrics;{bf:61}(1):223-229.{p_end}

{pstd}[2]. Pencina MJ, D'Agostino RB Sr, Steyerberg EW (2011). {it:Extensions of net reclassification improvement calculations to measure usefulness of new biomarkers.} Stat Med;{bf:30}(1):11-21.{p_end}

{title:Also see}

{psee}
Online:  {help stcuminc}; {help stpcuminc}; {help stidi}
{p_end}

{title:Author}

{p 4 4 2}
{browse "mailto:agorstras@gmail.com":Anders Gorst-Rasmussen}, Aalborg University Hospital, Aalborg University, Denmark{p_end}
