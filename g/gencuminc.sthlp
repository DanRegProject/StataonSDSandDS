{smcl}
{* *! version 1.0  February 5, 2018 @ 14:33:22}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "genCuminc##syntax"}{...}
{viewerjumpto "Description" "genCuminc##description"}{...}
{viewerjumpto "Options" "genCuminc##options"}{...}
{viewerjumpto "Remarks" "genCuminc##remarks"}{...}
{viewerjumpto "Examples" "genCuminc##examples"}{...}
{title:Title}
{phang}
{bf:genCuminc} {hline 2} Calculate cumulative incidence

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:genCuminc}
anything
[iweight
aweight
pweight
fweight]
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt endp:oints(string)}} .{p_end}
{synopt:{opt o:rigin(string)}} .{p_end}
{synopt:{opt e:nter(string)}} .{p_end}
{synopt:{opt s:cale(string)}} .{p_end}
{synopt:{opt by(string)}} .{p_end}
{synopt:{opt type(string)}} .{p_end}
{synopt:{opt compete(string)}} .{p_end}
{synopt:{opt id(string)}} .{p_end}
{synoptline}
Use {anything} to specify stub of generated variables.

{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}
{cmd:genCuminc}) does generate variable(s) named {Cumincstub}{endpoint} with cumulative incidence or survival estimates dependent on selected type.

{marker options}{...}
{title:Options}
{dlgtab:Main}
{phang}
{opt endp:oints(string)}  Endpoint list formatted as the stub provided to {genEndpoints}.

{phang}
{opt o:rigin(string)}  see {stset}

{phang}
{opt e:nter(string)}  see {stset}

{phang}
{opt s:cale(string)}  see {stset}

{phang}
{opt by(string)}  

{phang}
{opt type(string)}  either 'KM' to calculate Kaplan-Meier survival probabilities using sts gen, or 'stcompet' to calculate cumulative incidence under competing risk (thus use option compete()) using stcompet.

{phang}
{opt compete(string)}  endpoints acting as competing risk, use stub from genEndpoints.

{phang}
{opt id(string)}  id for multiline records, see {stset}


{marker examples}{...}
{title:Examples}

{phang} {cmd:. genCuminc CI`wtxt' $weight, endpoint($ENDPd) origin($index) enter($index) scale(365.25) by($BGRP) type(KM)}
{cmd:. genCuminc CI`wtxt' $weight, endpoint($ENDP) origin($index) enter($index) scale(365.25) by($BGRP) compete($ENDPd) type(stcompet)}

{title:Author}
{p}

<insert name>, <insert institution>.

Email {browse "mailto:firstname.givenname@domain":firstname.givenname@domain}

{title:See Also}

NOTE: this part of the help file is old style! delete if you don't like

Related commands:

{help command1} (if installed)
{help command2} (if installed)   {stata ssc install command2} (to install this command)
