/* SVN header
$Date: 2018-08-03 11:33:06 +0200 (fr, 03 aug 2018) $
$Revision: 118 $
$Author: FCNI6683 $
$Id: stsplitPeriods.sthlp 118 2018-08-03 09:33:06Z FCNI6683 $
*/
{smcl}
{* *! version 1.0  February 7, 2018 @ 09:00:17}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "stsplitPeriods##syntax"}{...}
{viewerjumpto "Description" "stsplitPeriods##description"}{...}
{viewerjumpto "Options" "stsplitPeriods##options"}{...}
{viewerjumpto "Remarks" "stsplitPeriods##remarks"}{...}
{viewerjumpto "Examples" "stsplitPeriods##examples"}{...}
{title:Title}
{phang}
{bf:stsplitPeriods} {hline 2} does Split survival data into risk periods

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:stsplitPeriods}
anything
[if]
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt using(string)}} .{p_end}
{synopt:{opt split(string)}} .{p_end}
{synopt:{opt splitstart(string)}} .{p_end}
{synopt:{opt splitend(string)}} .{p_end}
{synopt:{opt datestub(string)}} .{p_end}
{synopt:{opt statusstub(string)}} .{p_end}
{synopt:{opt saving(string [replace])}} .{p_end}
{synoptline}
{anything} is 2 variables in the current dataset: id and a date variable holding start of follow-up. Thereafter a list of endpoint prefixes. It is recommended that
endpoints are generated using {cmd: genEndpoints}.
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}
{cmd: stsplitPeriods} splits the current dataset into risk periods. Several subsequent calls to {cmd: stsplitPeriods} can be done.

It is recommended that you {cmd:stset} your data before and after using {cmd:stsplitPeriods} to ensure that number of events and time in risk is not affected by splitting the dataset; see {help stset}.
{marker options}{...}
{title:Options}
{dlgtab:Main}
{phang}
{opt using(string)}  dataset with period dates for splitting the dataset in memory  

{phang}
{opt split(string)}   variable name to hold the indicator for active period 

{phang}
{opt splitstart(string)}  variable in using() with period start 

{phang}
{opt splitend(string)}  variable in using() with period end

{phang}
{opt datestub(string)}  string used for postfix in endpoint date variables

{phang}
{opt statusstub(string)}  string used for postfix in endpoint status variables

{phang}
{opt saving(string asis)}  save resulting dataset otherwise replace existing


{marker examples}{...}
{title:Examples}

{phang}{cmd:. stsplitPeriods pnr indexdate MI Stroke Death, using(mysplits) split(FUtreat) splitstart(FUtreatstart) splitend(FUtreatend) datestub(Enddate) statusstub(Status)}

{title:Author}
{p}
{p_end}
{pstd}
Flemming Skjøth, Aalborg Thrombosis Research Unit. Aalborg University/Aalborg Universityhospital.

{pstd}
Email {browse "mailto:fls@rn.dk":fls@rn.dk}
