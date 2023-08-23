/* SVN header
$Date: 2018-04-04 14:11:28 +0200 (on, 04 apr 2018) $
$Revision: 90 $
$Author: fskJetNot $
$ID: $
*/

capture program drop CreateListB
program define CreateListB, rclass
version 13
syntax newvarname, [list(string) num(string) ]
  CreateList `varlist', addtxt("$base") list(`list') num(`num')
end
