# $Id $

#------------------------------------------------------------------------
# "reset!" module
#
# Allows on-the-fly rescanning of the modules directory
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
