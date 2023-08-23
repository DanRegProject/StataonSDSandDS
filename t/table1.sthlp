{smcl}
{* *! version 1.0  5 Feb 2018}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "table1##syntax"}{...}
{viewerjumpto "Description" "table1##description"}{...}
{viewerjumpto "Options" "table1##options"}{...}
{viewerjumpto "Remarks" "table1##remarks"}{...}
{viewerjumpto "Examples" "table1##examples"}{...}
{title:Title}
{phang}
{bf:table1} {hline 2} <insert title here>

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:table1}
anything
[if]
[fweight
pweight
aweight
iweight]
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt by(string)}} .{p_end}
{synopt:{opt test(string)}} .{p_end}
{synopt:{opt balance(string)}} .{p_end}
{synopt:{opt sep(string)}} .{p_end}
{synopt:{opt fewdata(#)}} Default value is 4.{p_end}
{synopt:{opt saving(string)}} .{p_end}
{synopt:{opt append}} .{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}
{cmd:table1} does ... <insert description>

{marker options}{...}
{title:Options}
{dlgtab:Main}
{phang}
{opt by(string)}  

{phang}
{opt test(string)}  

{phang}
{opt balance(string)}  

{phang}
{opt sep(string)}  

{phang}
{opt fewdata(#)}  Default value is 4

{phang}
{opt saving(string)}  

{phang}
{opt append}  


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
