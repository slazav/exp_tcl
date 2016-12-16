## Connection drivers for the Device library.
## Here we do not want to know device commands,
## but only know how to open/close connection and read/write commands

package require Itcl

namespace eval conn_drivers {

####################################################################
## read a line until \n character or timeout
## dev should be configured with -blocking 0
proc read_line_nb {dev timeout} {
  while {$timeout>0} {
    gets $dev res
    if { [string length $res] } {
      return $res
    }
    after 10
    set timeout [expr {$timeout-10}]
  }
}

###########################################################
# GPIB device connected through Prologix gpib2eth converter
# parameters:
#  -hostname -- converter hostname or ip-address
#  -addr     -- device GPIB address
#  -read_timeout -- read timeout, ms
itcl::class gpib_prologix {
  variable dev
  variable addr
  variable read_timeout

  # open device
  constructor {pars} {
    set pp [split $pars ":"]
    set host      [lindex $pp 0]
    set gpib_addr [lindex $pp 1]
    set dev [::socket $host 1234]
    set read_timeout 1000
    fconfigure $dev -blocking false -buffering line
  }
  # close device
  destructor {
    ::close $dev
  }
  # set address before any operation
  method set_addr {} {
    puts $dev "++addr"
    flush $dev
    set a [read_line_nb $dev $read_timeout]
    if { $a != $addr } {
      puts $dev "++addr $addr"
      flush $dev
    }
  }
  # write to device without reading answer
  method write {msg} {
    set_addr()
    puts $dev $msg
    flush $dev
  }
  # read from device
  method read {} {
    set_addr
    return [read_line_nb $dev $read_timeout]
  }
  # write and then read
  method cmd {msg} {
    set_addr
    write $msg
    return [read_line_nb $dev $read_timeout]
  }
}

###########################################################
# LXI device connected via ethernet. SCPI raw connection via port 5025
# parameters:
#  -hostname -- device hostname or ip-address
#  -read_timeout -- read timeout, ms
itcl::class lxi_scpi_raw {
  variable dev
  variable read_timeout

  # open device
  constructor {pars} {
    set host $pars
    set dev [::socket $host 5025]
    fconfigure $dev -blocking false -buffering line
  }
  # close device
  destructor {
    ::close $dev
  }
  # write to device without reading answer
  method write {msg} {
    puts $dev $msg
    flush $dev
  }
  # read from device
  method read {} {
    return [read_line_nb $dev $read_timeout]
  }
  # write and then read
  method cmd {msg} {
    write $msg
    return [read_line_nb $dev $read_timeout]
  }
}

###########################################################
# Connection with GpibLib
# parameters same is in the GpibLib
itcl::class gpib {
  variable dev
  constructor {pars} {
    package require GpibLib
    set dev [gpib_device gpib::$name {*}$pars]
  }
  destructor { gpib_device delete $dev }
  method write {msg} { $dev write $msg }
  method read {} { return [$dev read ] }
  method cmd {msg} { return [$dev cmd_read $msg ] }
}

###########################################################
# Graphene database. Parameter string is a command name for
# running graphene interface:
#   graphene -d . interactive
#   ssh somehost graphene -d . interactive
# TODO! - do not use graphene package
itcl::class graphene {
  variable dev
  constructor {pars} {
    package require Graphene
    set dev [::graphene::open {*}$pars]
  }
  destructor { ::graphene::close $dev }
  method cmd {msg} { return [::graphene::cmd $dev $msg] }
}

###########################################################
# pico_rec program. Parameter ptring is a command name
itcl::class pico_rec {
  variable dev
  variable open_timeout 3000
  variable read_timeout 1000

  constructor {pars} {
    set dev [::open "| pico_rec -d $pars" RDWR]
    read_line_nb $dev $open_timeout
  }
  destructor {::close $dev}
  method write {msg} {
    puts $dev $msg
    flush $dev
  }
  method read {} {
    return [read_line_nb $dev $read_timeout]
  }
  method cmd {msg} {
    puts $dev $c
    flush $dev
    return [read_line_nb $dev $read_timeout]
  }
}

###########################################################
# Tenma power supply. It is a serial port connection,
# but with specific delays and without newline characters.
itcl::class tenma_ps {
  variable dev
  variable del;     # read/write delay
  variable bufsize; # read buffer size

  # open device
  constructor {pars} {
    set dev [::open $pars RDWR]
    set del 50
    set bufsize 1024
    fconfigure $dev -blocking false -buffering line
  }
  # close device
  destructor {
    ::close $dev
  }
  # write to device without reading answer
  method write {msg} {
    puts -nonewline $dev $msg; # no newline!
    after $del
    flush $dev
  }
  # read from device
  method read {} {
    after $del
    return [read $dev $bufsize]
  }
  # write and then read
  method cmd {msg} {
    puts -nonewline $dev $msg
    flush $dev
    after $del
    return [read $dev $bufsize]
  }
}
###########################################################

}; #namespace