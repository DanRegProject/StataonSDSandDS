/*
***************************************************************;
	#+NAME			:	copyout.ado;
	#+TYPE			:	stata file;
	#+DESCRIPTION	:	moves over files with extension movetype to copypath from inpath;
	#+OUTPUT		:	;
	#+AUTHOR		:	Martin Jensen;
	#+CHANGELOG		:	Date		Initials	Status;
						29.06.2020	MJE			moved from DS to SDS;
						
***************************************************************;
*/

capture program drop copyout
program define copyout, nclass
version 16
syntax , copypath(string) inpath(string) [file(string) movetype(string) replace]
quietly{
	nois !mkdir "`copypath'"
	
	if "`movetype'" == "" & "`file'" == ""{
		local extension : dir "`inpath'" files "*.*"
		local all_ext
		
		foreach e in `extension'{
			*di "`e'"
			local dotpos = 0
			local dotpos = strpos("`e'",".")
			*di `dotpos'
			local ext = substr("`e'",`dotpos'+1,.)
			*di "`ext'"
			local all_ext `all_ext' `ext'
		}
		
		local unique : list uniq all_ext
		local movetype `unique'
	}
	
	if "`file'" == ""{
		noi dis "Copy all files of type `movetype' from `inpath' to `copypath'."
		local files : dir "`inpath'" files "*.*"
	}
	if "`file'" != ""{
		noi dis "Copy `file' from `inpath' to `copypath'."
		local files `file'
		local dotpos = strpos("`file'",".")
		local movetype = substr("`file'",`dotpos'+1,.)		
	}
	foreach file in `files'{
		local dotpos = strpos("`file'",".")
		local ext = substr("`file'",`dotpos'+1,.)
		foreach j in `movetype'{
			if "`j'" == "`ext'"{
				local infile = "`inpath'/`file'"
				local outfile = "`copypath'/`file'"
				copy `infile' `outfile', `replace'
			}
		}
	}
}

end::***** copyout.ado End 
