#------------------------------------------------------------------------
# Russian Roulette
#
# $Id: roulette.pm,v 1.3 2003/10/10 19:36:25 rharman Exp $
#
# Includes the BOFH roulette file grabbed from:
#       http://www.cs.wisc.edu/~ballard/bofh/roulettes
#------------------------------------------------------------------------

use strict;
package roulette;

my $no_roulette;

my $last_who;

sub scan(&$$) {
    my ($callback, $message, $who)=@_;

    unless($message =~ /^(?:rr|roulette)$/) {
        return undef;
    }

    # a wee little bit of anti-abuse.
    if ($who eq $last_who)
    {
      $callback->("Nyet, no can you take two turns!  Is not fair!");
      return 1
    } else {
      $last_who = $who;
    }

     my $channel = &::channel();
     my $who_dies_perc = int rand(100);
     my $percentage = 1/6 * 100;
     if( $who_dies_perc <= $percentage)
     {
       if ( $who_dies_perc <= 1/90 )
       {
         if (::getparam('roulette') eq "kill")
         {
           &::rawout("KILL $::param{nick} :*click* ... *click* ... *BANG* I'm dead");
           return 1;
         } else {
           &::rawout("KICK $channel $::param{nick} :*click* ... *click* ... *BANG* I'm dead");
           return 1;
         }
       }
       else
       {
         if (::getparam('roulette') eq "kill")
         {
           &::rawout("KILL $who :*click* *click* *boom*");
           return 1;
         } else {
           &::rawout("KICK $channel $who :*click* *click* *boom*");
           return 1;
         }
       }
       return;
     }
     $callback->( "$who spins the chamber, pulls the trigger, and lives to hand you the gun.");
    return 1;
}
"roulette";
