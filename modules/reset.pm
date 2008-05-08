#------------------------------------------------------------------------
# "reset!" module
#
# Allows on-the-fly rescanning of the modules directory
#
# $Id: reset.pm,v 1.7 2002/02/04 17:43:19 dagbrown Exp $
#------------------------------------------------------------------------

package reset;

sub scan(&$$) {

    my ( $callback, $message, $who ) = @_;

    if ( $message =~ /^\s*reset!\s*$/ ) {
        if ( &::IsFlag("o") ) {
            &Extras::loadmodules;
            $callback->("$who: Okay.");
            return 1;
        } else {
            $callback->("$who: You can't do that, you're no deity.");
            return 'NOREPLY';
        }
    } else {
        return undef;
    }
}

"reset";
