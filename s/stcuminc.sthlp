{smcl}
{cmd:help stcuminc} {...}
{right:also see:  {help stpcuminc}}
{hline}

{title:Title}

{p 4 18 2}
{hi: stcuminc} {hline 2} Cumulative incidence estimation under competing risks


{title:Syntax}

{p 8 25 2}
{cmd:stcuminc} {varname} {ifin} {cmd:,}
[ {it:options} ]
{p_end}

{synoptset 19 tabbed}
{marker pcaopts}{...}
{synopthdr}
{synoptline}
{synopt:{opt a:t(numlist)}}time points at which to estimate the cumulative incidence {p_end}
{synopt:{opt g:enerate(newvar)}}generate a new variable containing the cumulative incidence at the exit time of each subject
{p_end}
{synoptline}
{p 4 6 2}
You must {cmd:stset} your data before using {cmd:stcuminc}; see {help stset}.{p_end}

{pstd}  A variable {varname} must be specified; indicating by the value 1
the censoring times specified in the {cmd: stset} command which correspond to
competing events. {p_end}

{pstd} At least one of the options {cmd: at()} or {cmd: generate()} must be specified. {p_end}

{title:Description}

{pstd} {cmd: stcuminc} efficiently calculates point estimates of the cumulative incidence for survival
data under competing risks, utilizing the redistribute-to-the-right representation of the Aalen-Johansen estimator [1].

{pstd} Since {cmd: stcuminc} is an estimation command, standard errors and confidence intervals can be obtained by
bootstrapping; see {help bootstrap}. {p_end}

{title:Examples}

{pstd}Setup{p_end}

{phang2}{cmd:. webuse hypoxia}{p_end}

{pstd}Declare data to be survival-time data and declare the failure event of
    interest, that is, the event to be modeled{p_end}

{phang2}{cmd:. stset dftime, failure(failtype==1)}{p_end}

{pstd}Calculate cumulative incidences at time points 0.5 and 5 with {cmd:failtype==2} a competing event {p_end}

{phang2}{cmd:. generate c = (failtype==2)}{p_end}
{phang2}{cmd:. stcuminc c, at(0.5 5)}{p_end}

{pstd}Generate new variable {it:myvar} with cumulative incidences at exit times {p_end}

{phang2}{cmd:. stcuminc c, generate(myvar)}{p_end}


{title:Saved results}

{pstd} {cmd:stcuminc} saves the following in {cmd:e()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:e(N)}}number of observations{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Macros}{p_end}
{synopt:{cmd:e(cmd)}}{cmd:stcuminc}{p_end}
{synopt:{cmd:e(properties)}}{cmd:b}{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Matrices}{p_end}
{synopt:{cmd:e(time)}}vector of times provided in {cmd:at()}, if applicable {p_end}
{synopt:{cmd:e(b)}}coefficient vector of cumulative incidences at times provided in {cmd:at()}, if applicable{p_end}

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Functions}{p_end}
{synopt:{cmd:e(sample)}}marks estimation sample{p_end}

{title:References}

{pstd}[1]. Gooley TA, Leisenring W, Crowley J, Storer BE (1999). {it:Estimation of failure probabilities in the presence of competing risks: new representations of old estimators.} Stat Med.;{bf:18}(6):695-706.{p_end}

{title:Also see}

{psee}
Online:  {help stfpci}
{p_end}

{title:Author}

{p 4 4 2}
{browse "mailto:agorstras@gmail.com":Anders Gorst-Rasmussen}, Aalborg University Hospital, Aalborg University, Denmark{p_end}
