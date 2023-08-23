{smcl}
{cmd:help one2nmatch} {...}
{hline}

{title:Title}

{p 4 18 2}
{hi: one2nmatch} {hline 2} One to many match selection with/without replacement

{title:Syntax}

{p 8 25 2}
{cmd:one2nmatch} {varname:1} {varname:2} {ifin} {cmd:,}
{opt a:t(real)}
[ {it: options} ]
{p_end}

{synoptset 19 tabbed}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt nrep(int)}}number of controls (#1) assigned to each case (#2) {p_end}
{synopt:{opt replace}}use control selection with replacement, default is without replacement.{p_end}


{title:Description}

{pstd} {cmd: one2nmatch} assumes that #1 identifies the case subject linked by fx SEM matching to a number of possible controls with id in variable #2. By looping through the population {it:nrep} controls are selected at random for each case. Unless replacement is selected no control can be selected more than once.

If the control population is limited the user must observe that it may not be possible to assign {it:nrep} controls pr case.{p_end}


{title:Examples}


{phang2}{cmd:. one2nmatch sakpnr pnr , nrep(5)}{p_end}

{title:Author}

{p 4 4 2}
{browse "mailto:fls@rn.dk":Flemming Skjøth}, Aalborg University Hospital, Aalborg University, Denmark{p_end}
