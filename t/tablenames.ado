/*
 ***********************************************************************************************;
   #+NAME          :  tablenames.ado;
   #+TYPE          :  stata file;
   #+DESCRIPTION   :  Changes variable names to names from datalists.
   #+OUTPUT        :  ;
   #+AUTHOR        :  Martin Jensen;
   #+CHANGELOG     :  Date       Initials Status;
                   :  06.04.2020   MJE      Created;
 ***********************************************************************************************;
*/
capture program drop tablenames
program define tablenames, nclass
version 13
syntax anything, outdir(string)

capture file close myfile
local rname = ""
foreach names in `anything'{
	local npos = .
	if strpos("`names'","base") > 0{
		local npos = strpos("`names'","base")-1
	}
	if strpos("`names'","$index") > 0{
		local npos = strpos("`names'","$index")-1
	}
	
	local nametest = substr("`names'",1,`npos') 
	
	local files : dir "`outdir'" files "*list.txt"
	*di "`files'"
	foreach file in `files'{
		*display "`file'"
		file open myfile using "`outdir'/`file'", read
		file read myfile line
		while r(eof) == 0 & "`rname'" == ""{
			
			local linepos1 = strpos("`line'","|")
			*di "`linepos1'"
			local line1 = substr("`line'",2,length("`line'"))
			*di "`line1'"
			local linepos2 = strpos("`line1'","|")
			*di "`linepos2'"
			
			local linetest = substr("`line'",`linepos1'+2,`linepos2'-`linepos1'-2)
			*di "linetest = `linetest'"
			*di "nametest = `nametest'"
			
			if strpos("`linetest'","`nametest'") > 0{
				
				local nline1 = substr("`line'",2,length("`line'"))
				
				local pos1 = strpos("`nline1'","|")+2
				
				local nline2 = substr("`nline1'",`pos1',length("`nline1'"))
				
				local pos2 = strpos("`nline2'","|")
				
				local rname = substr("`line'",`pos1',`pos2')
				*di "`rname'"
				if "`rname'" != ""{
					global truename `rname'
					*di "truename = $truename"
				}
				
				
			}
			
			file read myfile line
		}
		
		file close myfile
	}
}
end::***** tablenames.ado End 
