{smcl}
{* *! version 0.5 oktober 22, 2013 @ 16:14:56}{...}
{cmd:help dowe}
{hline}

{title:Title}

{phang}
{hi: dowex} {hline 2} Export utility for dowe documents


{title:Syntax}

{phang}
Export dowe-generated .org documents from within Stata (requires a recent emacs to be installed).

{p 8 17 2}
{opt dowex} {cmd:,} [{opt f:ile(filename)} {opt t:ype(string)} {opt e:macs(path)}]


{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt f:ile(filename)}}name of input file. If unspecified, {cmd: dowex} will attempt to use the output file produced by the most recent run of {cmd: dowe}.{p_end}
{synopt:{opt t:ype(string)}}document type; default is {cmd: type(html)}. Document type should so that {it:org-export-as-}{bf:type} is a valid export function in your version of org-mode.
{p_end}
{synopt:{opt e:macs}}path to your Org-enabled emacs executable. The argument is optional only if you have specified a global variable EMACSDOWE containing the path to your emacs executable. {p_end}
{synoptline}
{p2colreset}{...}

{title:Description}

{pstd} {cmd: dowex} is a convenience utility which allows you to
interface (via {cmd: shell})with the emacs Org mode export function from within Stata. This further simplifies the process of generating
nicely-formatted statistical reports: having written {cmd: dowe} documents
using org markup, you simply call {cmd: dowe}, then {cmd:dowex} to obtain the final report. {cmd: dowex} has been tested with org-mode version 7.9.3f under emacs 24.3. 

{pstd}
For examples of how to use {cmd: dowe} with Org, refer to the online manual:

{p 8 8 2}{browse "http://www.gorst.dk/software/dowe/manual.htm"}{p_end}

{title: Examples }

{pstd}HTML export:

{phang}{cmd:. dowex, file("file.org") emacs("/path/emacs.exe")}

{pstd}PDF export (requires that org-mode can access LaTeX):

{phang}{cmd:. dowex, file("file.org") type(pdf) emacs("/path/emacs.exe")}

{pstd}Set a global variable and avoid having to provide the emacs path:

{phang}{cmd:. global EMACSDOWE /pathtomyemacs/emacs.exe}

{phang}{cmd:. dowex, file("file.org")}

{pstd}Get file name directly from {cmd: dowe}:

{phang}{cmd:. dowe "input.dowe" output("output.org")}

{phang}{cmd:. dowex}


{title:Also see}

{psee}
Online: {help dowe}

{title:Author}

{p 4 4 2}
{browse "mailto:agorstras@gmail.com":Anders Gorst-Rasmussen}, Aalborg University Hospital, Denmark{p_end}
