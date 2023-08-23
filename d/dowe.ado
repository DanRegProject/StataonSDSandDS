cap pr drop dowe
pr de dowe, sclass
syntax anything using/ , [ REPLACE APPEND]
loc outfile `"`using'"'
loc infile=subinstr(`"`anything'"',`""""',"",.)
if "`replace'"!="" & "`append'"!="" {
	di as err "cannot both replace and append"
	exit 100
}
if "`replace'"=="" & "`append'"=="" {
	confirm new file `"`using'"'
}
if(`c(noisily)'==0) {
	di as err "dowe cannot run quietly"
	exit 100
}
if "`append'"!="" {
    if "`s(dowerc)'"!="0" {
	di as err "Last call do dowe failed"
	exit
    }
}
tempfile dobuf /* do file */
tempfile logbuf1 /* raw log file */
tempfile logbuf2 /* clean log file */
             cap noi mata:dowe()/* capture errors */
loc rc = _rc
if(_rc != 0) {
    cap mata:cleanup()/* close files if errors*/
            dis as err "Something in org-file `infile' caused an error"
}
sret local doweout = "`outfile'"/* remember output file name */
sret local dowerc = "`rc'"
end
