#------------------------------------------------------------------------
# Russian Roulette
#
# $Id: roulette.pm,v 1.1 2003/03/11 22:22:38 rharman Exp $
#
# Includes the BOFH roulette file grabbed from:
#       http://www.cs.wisc.edu/~ballard/bofh/roulettes
#------------------------------------------------------------------------

use strict;
package roulette;

my $no_roulette;


sub scan(&$$) {
    my ($callback, $message, $who)=@_;

    unless($message =~ /(?:rr|roulette)/) {
        return undef;
    }

     my $who_dies_perc = int rand(100);
     my $channel = &::channel();

     if( $who_dies_perc <= 33)
     {
       if (::getparam('roulette') eq "kill")
       {
         &::rawout(" KILL $who :*click* *click* *boom*");
       } else {
         &::rawout(" KICK $channel $who :*click* *click* *boom*");
       }
       return;
     }
     $callback->( "$who spins the chamber, pulls the trigger, and lives to hand you the gun.");
    return 1;
}
"roulette";
