/* SVN header
$Date: 2018-04-04 14:12:01 +0200 (on, 04 apr 2018) $
$Revision: 76 $
$Author: fskJetNot $
$ID: $
*/
{smcl}
{* *! version 1.0  5 Feb 2018}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "reportCuminc##syntax"}{...}
{viewerjumpto "Description" "reportCuminc##description"}{...}
{viewerjumpto "Options" "reportCuminc##options"}{...}
{viewerjumpto "Remarks" "reportCuminc##remarks"}{...}
{viewerjumpto "Examples" "reportCuminc##examples"}{...}
{title:Title}
{phang}
{bf:reportCuminc} {hline 2} <insert title here>

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:reportCuminc}
anything
[if]
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt end:points(string)}} .{p_end}
{synopt:{opt by(string)}} .{p_end}
{synopt:{opt t:ime(numlist)}} .{p_end}
{synopt:{opt survival}} .{p_end}
{synopt:{opt format(string)}} .{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}
{cmd:reportCuminc} does ... <insert description>

{marker options}{...}
{title:Options}
{dlgtab:Main}
{phang}
{opt end:points(string)}  

{phang}
{opt by(string)}  

{phang}
{opt t:ime(numlist)}  

{phang}
{opt survival}  

{phang}
{opt format(string)}  


{marker examples}{...}
{title:Examples}

{phang} <insert example command>

{title:Author}
{p}
{p_end}
{pstd}
Flemming Skj¿th, Aalborg Thrombosis Research Unit. Aalborg University/Aalborg Universityhospital.

{pstd}
Email {browse "mailto:fls@rn.dk":fls@rn.dk}
