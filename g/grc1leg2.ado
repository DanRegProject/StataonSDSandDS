program grc1leg2
version 12
syntax [anything] [, LEGendfrom(string) ///
                   POSition(string) RING(integer -1) SPAN ///
                   NAME(passthru) SAVing(string asis) ///
                   XTOB1title XTItlefrom(string) LSize(string) * ]

gr_setscheme, refscheme

tempname clockpos
if ("`position'" == "") local position 6
                   .`clockpos' = .clockdir.new , style(`position')
                   local location `.`clockpos'.relative_position'

                   if `ring' > -1 {
                       if(`ring'==0){
                           loc location "on"
                           loc ring ""
                       }
                       else loc ring "ring(`ring')"
                   }
                   else loc ring ""

                   if "`span'" != "" {
                       if "`location'" == "above" | "`location'" == "below"{
                           loc span spancols(all)
                       }
                       else loc span spanrows(all)
                   }
                   if "`legendfrom'" != "" {
                       loc lfrom : list posof "`legendfrom'" in anything
                       if `lfrom' == 0{
                           di as error `"`legendfrom' not found in graph name list"'
                           exit 198
                       }
                   }
                   else loc lfrom 1

                   graph combine `anything', `options' `name' nodraw

                   if "`name'" != "" {
                       loc 0 `", `name'"'
                       syntax [, name(string)]
                       loc 0 `"`name'"'
                       syntax [anything(name=name)] [, replace]
                   }
                   else local name Graph

                   forvalues i = 1/`:list sizeof anything'{
                       _gm_edit .`name'.graphs[`i'].legend.draw_view.set_false
                       _gm_edit .`name'.graphs[`i'].legend.fill_if_undrawn.set_false

                       if "`xtob1title'"~=""{
                           _gm_edit .`name'.graphs[`i'].xaxis1.title.draw_view.set_false
                       }
                   }

                   .`name'.insert (legend = .`name'.graphs[`lfrom'].legend) ///
                   `location' plotregion1 , `ring' `span'

                   _gm_log .`name'.insert (legend = .graphs[`lfrom'].legend) ///
                   `location' plotregion1 , `ring' `span'

                   _gm_edit .`name'.legend.style.box_alignment.setstyle , ///
                   style(`.`clockpos'.compass2style')

                   if "`xtob1title'"=="" & "`xtitlefrom'"~="" {
                       loc xtob1title xtob1title
                   }
                   if "`xtob1title'"~="" {

                       if "`xtitlefrom'" != "" {
                           loc xfrom : list posof "`xtitlefrom'" in anything
                           if `xfrom' == 0{
                               di as error `"`xtitlefrom' not found in graph name list"'
                               exit 198
                           }
                       }
                       else loc xfrom 1

                       .`name'.b1title = .`name'.graphs[`xfrom'].xaxis1.title
                       _gm_log .`name'.b1title = .graphs[`xfrom'].xaxis1.title
                       _gm_edit .`name'.b1title.draw_view.set_true

                   }

                   if "`lsize'"~=""{
                       .`name'.legend.style.labelstyle.size.style.editstyle, ///
                           style(`lsize') editcopy

                       _gm_log .`name'.legend.style.labelstyle.style.editstyle, ///
                           style(`lsize') editcopy

                       _gm_edit .`name'.legend.style.labelstyle.style.editstyle, ///
                           style(`lsize') editcopy
                   }

                   _gm_edit .`name'.legend.draw_view.set_true

                   forvalues i = 1/`.`name'.legend.keys.arrnels' {
                       if "`.`name'.legend.keys[`i'].view.serset.isa'" != ""{
                           _gm_edit .`name'.legend.keys[`i'].view.serset.ref_n + 99

                           .`name'.legend.keys[`i'].view.serset.ref = ///
                               .`name'.graphs[`lfrom'].legend.keys[`i'].view.serset.ref

                           _gm_log .`name'.legend.keys[`i'].view.setset.ref = ///
                               .graphs[`lfrom'].legend.keys[`i'].view.serset.ref
                       }

                       if "`.`name'.legend.plotregion.keys[`i'].view.serset.isa'" != ""{
                           _gm_edit .`name'.plotregion.keys[`i'].view.serset.ref_n + 99

                           .`name'.legend.plotregion1.key[`i'].view.serset.ref = ///
                               .`name'.graphs[`lfrom'].legend.keys[`i'].view.serset.ref
                           _gm_log .`name'.legend.plotregion1.key[`i'].view.setset.ref = ///
                               .graphs[`lfrom'].legend.keys[`i'].view.serset.ref
                       }

                       if "`lsize'" ~= ""{
                           .`name'.legend.plotregion1.label[`i'].style.editstyle ///
                               size(`lsize') editcopy
                           _gm_log .`name'.legend.plotregion1.label[`i'].style.editstyle ///
                               size(`lsize') editcopy
                           _gm_edit .`name'.legend.plotregion1.label[`i'].style.editstyle ///
                               size(`lsize') editcopy
                       }
                   }

                   gr draw `name'

                   if `"`saving'"' != `""'{
                       gr_save `"`name'"' `saving'
                            }
               end

program GetPos
                   gettoken pmac 0 : 0
                   gettoken colon 0 : 0

                   local 0 `0'
                   if `"`0'"' == `""'{
                       c_local `pmac' below
                       exit
                   }

                   local 0 ", `0'"
                   syntax [ , Above Below Leftof Rightof ]

                   c_local `pmac' `above' `below' `leftof' `rightof'

                   end

