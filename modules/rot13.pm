#------------------------------------------------------------------------
# Rot13 command
#
# ROT13s a random bit of text.
#
# $Id: rot13.pm,v 1.6 2001/12/04 17:40:27 dagbrown Exp $
#------------------------------------------------------------------------

use strict;
package rot13;

sub scan(&$$) {
    my ($callback,$message,$who) = @_;

    if ($message =~ /^rot13\s+(.*)/i) {
        # rot13 it
        my $reply = $1;
        $reply =~ y/A-Za-z/N-ZA-Mn-za-m/;
        $callback->($reply);
    }
    undef;
}

"rot13";
