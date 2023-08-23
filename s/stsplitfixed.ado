capture program drop stsplitFixed
program define stsplitFixed, rclass
version 13.0
noi qui:{
    syntax anything [if], splittime(numlist) [gentime(string) datestub(string) statusstub(string) saving(string asis)]
    tokenize  `anything'
    loc id `1'
    loc startdate `2'
    macro shift 2
    loc endpoints `*'
    tempfile startdata dat0 dat1
    tempvar time etime
    if ("`datestub'"=="") loc datestub EndDate
    if ("`statusstub'"=="") loc statusstub Status
    save `startdata', replace
    if "`if'" != "" keep `if'
    if "`gentime'"=="" loc gentime splittime
    loc vars
    if "`endpoints'" != ""{
        foreach v in `endpoints'{
            loc vars `vars' `v'`datestub' `v'`statusstub'
        }
    }
    keep `id' `startdate' `vars'

    loc tn 0
    foreach t in `splittime'{
        loc tn = `tn' + 1
        loc t`tn' = `t'
    }
    loc tn = `tn' - 1
    foreach tc of numlist 1/`tn'{
        gen `time'`tc' = `startdate' + `t`tc''
        loc tp1 = `tc' + 1
        gen `etime'`tc' = `startdate' + `t`tp1''
        if "`endpoints'" != ""{
            foreach v in `endpoints'{
                gen `v'`statusstub'_`tc' = 0 if `v'`datestub' < . & `etime'`tc' < `v'`datestub'
                replace `v'`statusstub'_`tc' = `v'`statusstub' if `time'`tc' < `v'`datestub' & `v'`datestub' <= `etime'`tc'
                gen `v'`datestub'_`tc' = `etime'`tc' if `v'`datestub' < . & `time'`tc' < `v'`datestub'
                replace `v'`datestub'_`tc' = `v'`datestub' if `time'`tc' < `v'`datestub' & `v'`datestub' <= `etime'`tc'
            }
        }
    }

    cap drop `vars'

    loc vars
    if "`endpoints'" != ""{
        foreach v in `endpoints'{
            loc vars `vars' `v'`datestub'_ `v'`statusstub'_
        }
    }
    reshape long `time' `etime' `vars' , i(`id' `startdate') j(`gentime')

    replace `startdate' = `time'
    drop `time' `etime'
    if "`endpoints'" != ""{
        foreach v in `endpoints'{
            rename `v'`datestub'_ `v'`datestub'
            format `v'`datestub' %d
            rename `v'`statusstub'_ `v'`statusstub'
        }
    }
    if "`saving'"!=""{
        save `saving'
        use `startdata', clear
    }

}
end
