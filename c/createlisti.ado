/* SVN header
$Date: 2018-04-04 14:11:28 +0200 (on, 04 apr 2018) $
$Revision: 90 $
$Author: fskJetNot $
$ID: $
*/
/* hardcoded with index and base, in order to make it easier to read in myvarlist.do */
capture program drop CreateListI
program define CreateListI, rclass
version 13
syntax newvarname, [list(string) num(string) ]
  CreateList `varlist', addtxt("$index") list(`list') num(`num')
end

