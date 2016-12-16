# Tcl package index file
# This file is NOT generated by the "pkg_mkIndex" command 

set _name    Device
set _version 1.2
set _files   {device drivers}

set _pcmd {}
foreach _f $_files { lappend _pcmd "source [file join $dir $_f.tcl]" }
lappend _pcmd "package provide $_name $_version"
package ifneeded $_name $_version [join $_pcmd \n]

