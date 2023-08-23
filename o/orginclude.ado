capture program drop orginclude

program define orginclude, nclass
version 13
syntax anything(name=file) ,[path(string)] 

if "`path'"=="" local path .
 capture confirm file `path'/`file' 
 if _rc==0 dis "#+INCLUDE: `file'"
 else dis "File `file' not found."
end
