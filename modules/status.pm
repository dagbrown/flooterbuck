#------------------------------------------------------------------------
# status
#
# Gives a quick summary of the bot's status.
#
# $Id: status.pm,v 1.6 2002/01/03 23:40:16 rharman Exp $
#------------------------------------------------------------------------

package status;
use strict;

sub scan(&$$) {
    my ( $callback, $message, $who ) = @_;

    if ( $message =~ /^statu?s/ ) {
        my $upString = &::timeToString( time() - $::startTime );
        my $eTime = &::get( "is", "the qEpochDate" );
        $callback->(
                "Since $::setup_time, there have been $::updateCount "
              . "modifications and $::questionCount questions.  "
              . "I have been awake for $upString this session, "
              . "and currently reference $::factoidCount factoids. "
              . "Addressing is in "
              . lc( ::getparam('addressing') )
              . " mode." );
        return 1;
    } else {
        return undef;
    }
}

"status";
