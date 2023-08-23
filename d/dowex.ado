// From 'esttab.ado' (version 2.0.5 09mar2009 Ben Jann)
cap pr drop _getfilesuffix
pr _getfilesuffix, rclass // based on official _getfilename.ado
version 8
gettoken filename rest : 0
if `"`rest'"' != "" {
    exit 198
}
loc hassuffix 0
gettoken word rest : filename, parse(".")
while `"`rest'"' != "" {
    loc hassuffix 1
    gettoken word rest : rest, parse(".")
}
if `"`word'"'=="." {
    di as err `"incomplete filename; ends in ."'
    exit 198
}
if index(`"`word'"',"/") | index(`"`word'"',"\") local hassuffix 0
if `hassuffix' return local suffix `".`word'"'
else return local suffix ""
end
/* Export org output (requires emacs w/org-mode) */
    /* Can use S-return to get 'file'; otherwise specify */
    /* 'type' should be pdf, html (defaults to html) */
cap pr drop dowex
pr de dowex
syntax [, Emacs(string) File(string) Type(string) force]
if("`s(dowerc)'"!="0" & "`force'"!="force") {
	di as err "Last call to dowe failed"
	exit 100
    }
if("`file'"=="") {
    if("`s(doweout)'"!="") {
        loc file `s(doweout)'
    }
    else {
	di as err "input file not specified"
            exit 100
        }
}
if("`emacs'"=="") {
    if("$EMACSDOWE"==""){
        di as err "emacs path not specified"
        exit 100
    }
    else {
        loc emacs = "$EMACSDOWE"
    }
}
if("`type'"=="") {
    loc type "pdf"
}

di "`file'"
_getfilesuffix "`file'"

if(r(suffix)!=".org") {
    di as err "file `file' is not an .org-file"
    exit 100
}
if "`type'" == "pdf" loc funcall org-latex-export-to-`type'
if "`type'" == "html" loc funcall org-html-export-to-html

tempfile mylog
di as txt "Exporting ..." _n
shell "`emacs'" --batch --visit="`file'" --funcall `funcall' 2> "`mylog'"
file open fh using "`mylog'", read
file read fh line
while r(eof)==0 {
    display " `line'"
    file read fh line
}
file close fh
end
