
/* hardcoded with index and base, in order to make it easier to read in myvarlist.do */
capture program drop CreateListI
program define CreateListI, rclass
version 13
syntax newvarname, [list(string) num(string)]

  CreateList `varlist' , addtxt("$index") list(`list') num(`num')
end
