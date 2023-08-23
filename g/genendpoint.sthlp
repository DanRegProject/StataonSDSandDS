{smcl}
{* *! version 1.0  February 5, 2018 @ 14:57:31}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "genEndpoint##syntax"}{...}
{viewerjumpto "Description" "genEndpoint##description"}{...}
{viewerjumpto "Options" "genEndpoint##options"}{...}
{viewerjumpto "Remarks" "genEndpoint##remarks"}{...}
{viewerjumpto "Examples" "genEndpoint##examples"}{...}
{title:Title}
{phang}
{bf:genEndpoint} {hline 2} Create standard endpoint variables for survival data

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:genEndpoint}
anything
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt :deadDate(string)}} .{p_end}
{synopt:{opt :deadCode(string)}} .{p_end}
{synopt:{opt :studyEndDate(string)}} .{p_end}
{synopt:{opt combined}} .{p_end}
{synoptline}
{anything} is {stub} and {varlist}, where {stub} is name for endpoint, and {varlist} are dates for endpoints (optional).
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}
{cmd:genEndpoint} does generated endpoint variables: {name}Status and {name}Enddate. With {name}Status equal 1 if one of the dates in {varlist} are before {opt deadDate} and {opt StudyEndDate}. {name}Enddate is the date of the event or the first of {opt deadDate} or {opt StudyEndDate}.

{marker options}{...}
{title:Options}
{dlgtab:Main}
{phang}
{opt :deadDate(string)}  is variable with date of or days to death.

{phang}
{opt :deadCode(string)}   is indicator of death (TRUE).

{phang}
{opt :studyEndDate(string)}  is variable with date of or days to study end.

{phang}
{opt combined}  indicating if endpoint is combined with death, death need not be included in {varlist}


{marker examples}{...}
{title:Examples}

{phang} {cmd:. genEndpoint stroke istroke se, deadDate(deathdate) deadCode(death==1) studyEndDate(mdy(12,23,2016))}

{title:Author}
{p}

Flemming Skjøth, Aalborg University Hospital, Aalborg University, Denmark.

Email {browse "mailto:fls@rn.dk":fls@rn.dk}

