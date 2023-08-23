/*
 ***********************************************************************************************;
   #+NAME          :  copyout.ado;
   #+TYPE          :  stata file;
   #+DESCRIPTION   :  moves over file with extension movetype to copypath from inpath
   #+OUTPUT        :  ;
   #+AUTHOR        :  Martin Jensen;
   #+CHANGELOG     :  Date       Initials Status;
                   :  25.01.16   MJE      Created;
 ***********************************************************************************************;
*/
capture program drop copyout

program define copyout, nclass
version 16
syntax ,copypath(string) inpath(string) [movetype(string) replace erase]
quietly{

	cap mkdir "`copypath'"

	if "`movetype'" == ""{
		local extension : dir "`inpath'" files "*.*"
		local all_ext

		foreach e in `extension'{
*			di "`e'"
			local dotpos = 0
			local dotpos = strpos("`e'",".")
*			di `dotpos'
			local ext = substr("`e'",`dotpos'+1,.)
*			di "ext = `ext'"
			local all_ext `all_ext' `ext'
		}
		local unique : list uniq all_ext
		local movetype `unique'
	}
noi dis "Copy all files of type `movetype' from `inpath' to `copypath'."
	local files : dir "`inpath'" files "*.*"
	foreach file in `files'{
		local dotpos = strpos("`file'",".")
		local ext = substr("`file'",`dotpos'+1,.)
		foreach j in `movetype'{
			if "`j'" == "`ext'"{
				local infile = "`inpath'/`file'"
				local outfile =  "`copypath'/`file'"
				copy "`infile'" "`outfile'", `replace'
                                if "`erase'"=="erase" erase "`infile'"
			}
		}
	}
}

end
