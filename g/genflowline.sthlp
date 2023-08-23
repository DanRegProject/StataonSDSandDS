/* SVN header
$Date: 2018-08-03 11:33:06 +0200 (fr, 03 aug 2018) $
$Revision: 118 $
$Author: FCNI6683 $
$Id: genFlowline.sthlp 118 2018-08-03 09:33:06Z FCNI6683 $
*/
{smcl}
{* *! version 1.0  February 5, 2018 @ 15:31:57}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "genFlowline##syntax"}{...}
{viewerjumpto "Description" "genFlowline##description"}{...}
{viewerjumpto "Options" "genFlowline##options"}{...}
{viewerjumpto "Remarks" "genFlowline##remarks"}{...}
{viewerjumpto "Examples" "genFlowline##examples"}{...}
{title:Title}
{phang}
{bf:genFlowline} {hline 2} <insert title here>

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:genFlowline}
anything
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt text(string)}} .{p_end}
{synopt:{opt crit:erion(string)}} .{p_end}
{synopt:{opt new}} .{p_end}
{synopt:{opt same:line}} .{p_end}
{synoptline}
{anything} is {name} 
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}
{cmd:genFlowline} does  generate a variable named {name} which is with index and with the text provided.

{marker options}{...}
{title:Options}
{dlgtab:Main}
{phang}
{opt text(string)}  a string with the text to appear in the flowchart.

{phang}
{opt crit:erion(string)}   is the condition written in statacode.

{phang}
{opt new}  first row in list of flowchart entries.

{phang}
{opt same:line}   flowchart entry index is not changed, NB for this to work the text should be the same as previous entry.


{marker examples}{...}
{title:Examples}

{phang}
{cmd:. genFlowline flow, text(Unknown $index) crit($index<mdy(01,01,1970) | missing($index)) new}
{cmd:. genFlowline flow, text(Outside inclusion window) crit($index<$inclstart |  $index>$inclend) }
{cmd:. genFlowline flow, text(Invalid CPR or death before $index) crit(missing(birthdate))}
{cmd:. genFlowline flow, text(Invalid CPR or death before $index) crit(deathdate<$index) same}


{title:Author}
{p}
{p_end}
{pstd}
Flemming Skj¿th, Aalborg Thrombosis Research Unit. Aalborg University/Aalborg Universityhospital.

{pstd}
Email {browse "mailto:fls@rn.dk":fls@rn.dk}
