{smcl}
{* *! version 1.0  5 Feb 2018}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "reportHR##syntax"}{...}
{viewerjumpto "Description" "reportHR##description"}{...}
{viewerjumpto "Options" "reportHR##options"}{...}
{viewerjumpto "Remarks" "reportHR##remarks"}{...}
{viewerjumpto "Examples" "reportHR##examples"}{...}
{title:Title}
{phang}
{bf:reportHR} {hline 2} <insert title here>

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:reportHR}
[if]
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt using(string)}} .{p_end}
{synopt:{opt by(string)}} .{p_end}
{synopt:{opt evalue}} .{p_end}
{synopt:{opt notrare}} .{p_end}
{synopt:{opt format(string)}} .{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}
{cmd:reportHR} does ... <insert description>

{marker options}{...}
{title:Options}
{dlgtab:Main}
{phang}
{opt using(string)}  

{phang}
{opt by(string)}  

{phang}
{opt evalue}  

{phang}
{opt notrare}  

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
