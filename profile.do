set more off, perm
sysdir set PERSONAL "..\..\macros\Stata"
adopath ++ PERSONAL


/* select program versions  */
global EMACS_VERSION = "GNU Emacs 25.1"
global R_VERSION     = "R-3.3.3"

global EMACSDOWE "C:\Program Files (x86)\\$EMACS_VERSION\bin\emacs.exe"
global RPROGRAM "C:\Program Files\R\\$R_VERSION\bin\x64\R.exe"
global Rcmd "C:\Program Files\R\\$R_VERSION\bin\x64\Rscript.exe"

gl beginhide dis "#+BEGIN_COMMENT"
gl endhide dis "#+END_COMMENT"

