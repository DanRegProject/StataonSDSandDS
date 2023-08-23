{smcl}
{cmd:help stconc} {...}
{right:also see:   {help somersd}}
{hline}

{title:Title}

{p 4 18 2}
{hi: stconc} {hline 2} Concordance statistics  for survival data

{title:Syntax}

{p 8 25 2}
{cmd:stconc} {varlist} {ifin} {cmd:,}
[ {it: options} ]
{p_end}

{synoptset 19 tabbed}
{synopthdr}
{synoptline}

{synopt:{opt c:ompete(varname)}}variable indicating by the value 1 censoring times corresponding to competing events  {p_end}
{synopt:{it:{help somersd:options1}}}additional options for {cmd:somersd} (except {cmd: cenind()} and {cmd: transf()})
{p_end}

{synoptline}

{p 4 6 2}
You must {cmd:stset} your data before using {cmd:stconc}; see {help stset}.{p_end}


{title:Description}

{pstd} {cmd: stconc} calculates (Harrell's) concordance statistic
(C-statistic) for survival data in a competing risks setting. The
command is essentially just a specializedinterface for the {cmd: somersd} command (see
{help somersd}), with the added capability of being able to take into
account competing risks (using the approach suggested in [1]).


{title:Examples}

{pstd}Setup{p_end}

{phang2}{cmd:. webuse hypoxia}{p_end}

{pstd}Declare data to be survival-time data and declare the failure event of
    interest, that is, the event to be modeled{p_end}

{phang2}{cmd:. stset dftime, failure(failtype==1)}{p_end}

{pstd}Calculate concordance statistics with {cmd:failtype==2} as a competing event {p_end}

{phang2}{cmd:. generate c=(failtype==2) }{p_end}
{phang2}{cmd:. stconc hgb age, compete(c)}{p_end}

{pstd}Calculate difference in concordance statistics {p_end}

{phang2}{cmd:. lincom age-hgb }{p_end}

{title:Saved results}

{pstd}  {cmd:stidi} saves the same
information as {cmd:bootstrap} in {cmd:e()}, see {help bootstrap} for details.

{title:References}

{pstd}[1]. Wolbers M, Koller MT, Witteman JC, Steyerberg EW (2009). {it:Prognostic models with competing risks: methods and application to coronary risk prediction.} Epidemiology;{bf:20}(4):555-561.{p_end}


{title:Also see}

{psee}
Online:  {help lincom}; {help somersd};
{p_end}

{title:Author}

{p 4 4 2}
{browse "mailto:agorstras@gmail.com":Anders Gorst-Rasmussen}, Aalborg University Hospital, Aalborg University, Denmark{p_end}
