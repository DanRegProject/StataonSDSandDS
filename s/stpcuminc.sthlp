{smcl}
{cmd:help stpcuminc} {...}
{right:also see:  {help stcuminc}}
{hline}

{title:Title}

{p 4 18 2}
{hi: stpcuminc} {hline 2} Efficient pseudovalues for the cumulative incidence under competing risks

{title:Syntax}

{p 8 25 2}
{cmd:stpcuminc} {varname} {ifin} {cmd:,}
{opt a:t(numlist)}
[ {opt g:enerate(string)} ]
{p_end}

{synoptset 19 tabbed}
{marker pcaopts}{...}
{synopthdr}
{synoptline}
{synopt:{opt a:t(numlist)}}time points at which to calculate pseudo values {p_end}
{synopt:{opt g:enerate(string)}}specifies a variable name for the pseudovalues; the
        default is {cmd:generate(pseudo)}
{p_end}
{synoptline}
{p 4 6 2}
You must {cmd:stset} your data before using {cmd:stpcuminc}; see {help stset}.{p_end}

{pstd} A variable {it: varname} must be specified; indicating by the value 1
the censoring times specified in the {cmd: stset} command which correspond to
competing events. {p_end}

{title:Description}

{pstd} {cmd: stpcuminc} produces pseudovalues for the cumulative
incidence function in a competing risks setting [1], utilizing the
redistribute-to-the-right representation of the Aalen-Johansen
estimator [2]. {cmd:stpcuminc} is optimized for speed and should be fast
even for large data sets.{p_end}

{pstd} By default, pseudovalues are saved to the variable
{cmd:pseudo}; if several time points are specified,
pseudovalues are saved in {cmd:pseudo1}, {cmd:pseudo2}, etc. {p_end}


{title:Examples}

{pstd}Setup{p_end}

{phang2}{cmd:. webuse hypoxia}{p_end}

{pstd}Declare data to be survival-time data and declare the failure event of
    interest, that is, the event to be modeled{p_end}

{phang2}{cmd:. stset dftime, failure(failtype==1)}{p_end}

{pstd}Calculate cumulative incidence pseudovalues at time points 0.5 and 5 with {cmd:failtype==2} as a competing event {p_end}

{phang2}{cmd:. generate c = (failtype==2)}{p_end}
{phang2}{cmd:. stpcuminc c, at(0.5 5) generate(mypseudo)}{p_end}

{pstd}Empirical means and SEs estimate the cumulative incidence and associated SE at the specified time points:  {p_end}

{phang2}{cmd:. tabstat mypseudo*, statistics(mean semean)}{p_end}

{title:References}

{pstd}[1]. Klein JP, Andersen PK (2005). {it:Regression modeling of competing risks data based on pseudovalues of the cumulative incidence function.}. Biometrics;{bf:61}(1):223-229.{p_end}

{pstd}[2]. Gooley TA, Leisenring W, Crowley J, Storer BE (1999). {it:Estimation of failure probabilities in the presence of competing risks: new representations of old estimators.}. Statist Med.;{bf:18}(6):695-706.{p_end}

{title:Also see}

{psee}
Online:  {help stcuminc}
{p_end}

{title:Author}

{p 4 4 2}
{browse "mailto:agorstras@gmail.com":Anders Gorst-Rasmussen}, Aalborg University Hospital, Aalborg University, Denmark{p_end}
