#------------------------------------------------------------------------
# "reset!" module
#
# Allows on-the-fly rescanning of the modules directory
#
# $Id: reset.pm,v 1.6 2001/12/04 17:40:27 dagbrown Exp $
#------------------------------------------------------------------------

package reset;

sub scan(&$$) {

    my ($callback,$message,$who) = @_;

    if($message=~/^\s*reset!\s*$/) {
      if (&::IsFlag("o"))
      {
        &Extras::loadmodules;
        $callback->("$who: Okay.");
        return 1;
      } else {
        $callback->("You can't do that, you're no deity.");
        return 'NOREPLY';
      }
    } else {
        return undef;
    }
}

"reset";
