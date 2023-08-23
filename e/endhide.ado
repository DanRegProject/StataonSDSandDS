cap program drop endhide
program define endhide
if "$CENSORREPORT"=="TRUE" {
    if "`1'" != "" loc `1' = upper("`1'")
    if "`1'" != "" dis "#+END_`1'"
    $endhide
    if "`1'" != "" dis "#+BEGIN_`1'"
}
else {
    dis _n " END OF POTENTIAL SMALL NUMBERED TABLES, BEWARE "
}
end
