#------------------------------------------------------------------------
# Lastlog module - anyone around?
#
# $Id: lastlog.pm,v 1.3 2006/10/03 02:05:37 rich_lafferty Exp $
#------------------------------------------------------------------------

use strict;

package lastlog;

sub scan(&$$) {
    my ( $callback, $message, $who ) = @_;

    if ( $message =~ /^lastlog\W*$/i ) {
        my @lastlog;
        my $reply;
        my $counter = 0;
        @lastlog = &::showtop( "seen", 10, "top" );
        foreach (@lastlog) {
            /(.*?) => (\d+)/;
            my ( $nick, $epoch ) = ( $1, $2 );
            my $elapsed = time() - $epoch;
            last if $elapsed > 86400;
            my $hours = int( $elapsed / ( 60 * 60 ) );
            my $minutes =
              int( ( $elapsed - ( $hours * 60 * 60 ) ) / 60 );

            $reply .=
                "$nick ("
              . ( $hours   ? "${hours} hrs, "  : "" )
              . ( $minutes ? "${minutes} min " : "" )
              . ( $elapsed > 60 ? "ago" : "just now" ) . "), ";
            $counter++;
        }
        $reply =~ s/, $//;
        $callback->($reply);
        return 1;
    }
    return undef;
}

"lastlog";
