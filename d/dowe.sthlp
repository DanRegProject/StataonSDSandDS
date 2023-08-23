{smcl}
{* *! version 0.5 oktober 24, 2013 @ 15:13:06}{...}
{cmd:help dowe}
{hline}

{title:Title}

{hi: dowe} {hline 2} Literate programming with Stata


{title:Syntax}

{phang}
Process dowe document.

{p 8 17 2}
{opt dowe} {it: infilename} {cmd: using} {it:outfilename} {cmd:,} {opt replace append}

{title:Description}

{pstd}
{cmd: dowe} is a document processor for weaving .do files with plain
text. Blocks of Stata code into any plain text document via a simple
markup language; {cmd: dowe} is then used to process the document,
substituting code blocks with results. This makes it straightforward
to generate complete statistical reports in a dynamic fashion,
enabling you to reproduce every single step, from the raw data to the
final conclusions.

{pstd}
In addition to its weaving features, {cmd: dowe}
supports several other literate programming features, including code
inlining, tangling (export), and reuse of previously defined code.

{pstd} 
To learn more about syntax and options in {cmd: dowe}, refer to the the online manual:

{p 8 8 2}{browse "http://www.gorst.dk/software/dowe/manual.htm"}{p_end}

{title:Options}

{pstd}
{cmd: replace} specifies that {it: outfilename}, if it already exists, be overwritten. 
{cmd: append} specifies that results are appended to {it: outfilename}. 



{title:Examples}

{pstd} With the file {it: myinput.do} as specified below, the following call produces {it: myoutput.txt}.

{phang}{cmd:. dowe "myinput.do" using "myoutput.txt", replace}


{space 4}{it:myinput.do}
{space 4}{hline 45}
{space 4}{bf:A simple regression analysis.}

{space 4}{bf:#+do}
{space 6}{bf:quietly sysuse auto}
{space 6}{bf:summarize mpg}
{space 4}{bf:#+od}

{space 4}{bf:The mean of mpg is =[display %3.2f r(mean)]=.}
{space 4}{hline 45}

{space 4}{it:myoutput.txt}
{space 4}{hline 70}
{space 4}{bf:A simple regression analysis.}

{space 4}{bf:    Variable |      Obs       Mean    Std. Dev.       Min        Max }
{space 4}{bf:-------------+--------------------------------------------------------}
{space 4}{bf:         mpg |       74    21.2973     5.785503        12         41 }

{space 4}{bf:The mean of mpg is 21.30.}
{space 4}{hline 70}


{title:Also see}

{psee}
Online: {help dowex}

{title:Author}

{p 4 4 2}
{browse "mailto:agorstras@gmail.com":Anders Gorst-Rasmussen}, Aalborg University Hospital, Denmark{p_end}
