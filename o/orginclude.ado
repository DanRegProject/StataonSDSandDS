
capture program drop orginclude
program define orginclude, rclass
version 13
syntax anything, [dir(string)]
tokenize `anything'
   if "`dir'"=="" loc dir .
  capture confirm file `dir'/`1'
  if _rc==0 {
      dis `"#+INCLUDE: "`1'" "'
  }
  else {
      dis "File `1' not found in default library where expected."
  }
end

