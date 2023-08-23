
capture program drop checklog
program define checklog, nclass
version 16
syntax , inpath(string) [filetype(string)]
if "`inpath'"=="" loc inpath .
if "`filetype'"=="" loc filetype log
local pwd: pwd
preserve
clear
loc myfiles: dir "`inpath'" files "*.`filetype'"
cd `inpath'
loc findstr1  r(111);
di "----`inpath'----"
foreach f of local myfiles{
	qui set obs 1
	gen strL S = fileread("`f'")
	gen long pos = strpos(S,"`findstr1'")
	di "----File = `f'----"
	if (pos[1]>0 ){
		di "    <`findstr1'> found at pos = " pos[1]
	}
	else {
		di "    No errors found" 
	}
	di ""
	clear
}
restore
cd `pwd'
end
