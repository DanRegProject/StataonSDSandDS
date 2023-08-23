cap program drop beginhide
program define beginhide
if "$CENSORREPORT"=="TRUE" {
    if "`1'" != "" loc `1' = upper("`1'")
    if "`1'" != "" dis "#+END_`1'"
    dis _n " CENSORED PART REMOVED "
    $beginhide
    if "`1'" != "" dis "#+BEGIN_`1'"
}
else {
    dis _n " START OF POTENTIAL SMALL NUMBERED TABLES, BEWARE "
}
end

