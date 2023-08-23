
capture program drop CreateListB
program define CreateListB, rclass
version 13
syntax newvarname, [list(string) num(string)]

  CreateList `varlist' , addtxt("$base") list(`list') num(`num')
end
