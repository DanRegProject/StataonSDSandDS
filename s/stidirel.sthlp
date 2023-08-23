{smcl}
{cmd:help stidi} {...}
{right:also see:   {help stcuminc}   {help stpcuminc}}
{hline}

{title:Title}

{p 4 18 2}
{hi: stidi} {hline 2} Relative integrated discrimination improvement for survival data

{title:Syntax}

{p 8 25 2}
{cmd:stidi} {varname:1} {varname:2} {ifin} {cmd:,}
{opt a:t(real)}
[ {it: options} ]
{p_end}

{synoptset 19 tabbed}
{synopthdr}
{synoptline}
{synopt:{opt a:t(real)}}time point at which to calculate integrated discrimination improvement. {p_end}
{synopt:{opt c:ompete(varname)}}variable indicating by the value 1 censoring times corresponding to competing events  {p_end}
{synopt:{it:{help bootstrap:options1}}}options for the bootstrap
{p_end}
{synoptline}
{p 4 6 2}
You must {cmd:stset} your data before using {cmd:stidi}; see {help stset}.{p_end}


{title:Description}

{pstd} {cmd: stidi} calculates the relative integrated discrimination
 improvement (IDI) of a new versus an old risk score for survival data
 in a competing risks setting. This is defined as the obtained IDI divided 
 by the slope of the old model [1]. Pseudovalues of the cumulative
 incidence function [2] are used in conjunction with the formulas of
 [3]. Specifically, IDI corresponds to the difference in R-squared
 values between the two linear regression models regressing cumulative
 incidence pseudovalues on the new and old risk score,
 respectively. {p_end}

{pstd}
Bootstrapping is used for variance estimation. {p_end}


{title:Examples}

{pstd}Setup{p_end}

{phang2}{cmd:. webuse hypoxia}{p_end}

{pstd}Declare data to be survival-time data and declare the failure event of
    interest, that is, the event to be modeled{p_end}

{phang2}{cmd:. stset dftime, failure(failtype==1)}{p_end}

{pstd}Two simple risk scores {p_end}

{phang2}{cmd:. generate oldrisk=age}{p_end}
{phang2}{cmd:. generate newrisk=age+hgb}{p_end}

{pstd}Calculate IDI at time 1 with {cmd:failtype==2} as a competing event {p_end}

{phang2}{cmd:. generate c=(failtype==2) }{p_end}
{phang2}{cmd:. stidi oldrisk newrisk, at(1) compet(c) reps(250)}{p_end}

{title:Saved results}

{pstd}  {cmd:stidi} saves the same
information as {cmd:bootstrap} in {cmd:e()}, see {help bootstrap} for details.

{title:References}

{pstd}[1]. Pencina et al. (2010). {it:Statistical methods for assessment of added usefulness of new biomarkers.}. Biometrics;{bf:61}(1):223-229.{p_end}

{pstd}[2]. Klein JP, Andersen PK (2005). {it:Regression modeling of competing risks data based on pseudovalues of the cumulative incidence function.}. Biometrics;{bf:61}(1):223-229.{p_end}

{pstd}[3]. Chambless LE, Cummiskey CP, Cui G (2011). {it:Several methods to assess improvement in risk prediction models: extension to survival analysis.} Stat Med;{bf:30}(1):22-38.{p_end}

{title:Also see}

{psee}
Online:  {help stcuminc}; {help stpcuminc}; {help stnri}
{p_end}

{title:Author}

{p 4 4 2}
{browse "mailto:agorstras@gmail.com":Anders Gorst-Rasmussen}, Aalborg University Hospital, Aalborg University, Denmark{p_end}
