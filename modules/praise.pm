#------------------------------------------------------------------------
# Random praise: "Good bot"
#
# $Id: praise.pm,v 1.6 2002/02/06 02:48:34 rharman Exp $
#------------------------------------------------------------------------

use strict;

package praise;

my @welcomes = (
    'no problem',
    'my pleasure',
    'sure thing',
    'no worries',
    'de nada',
    'de rien',
    'bitte',
    'pas de quoi'
);

sub scan(&$$) {
    my ( $callback, $message, $who ) = @_;

  # Gotta be gender-neutral here... we're sensitive to purl's needs. :-)
    if (
        $message =~ /(good(\s+fuckin[\'g]?)?\s+(bo(t|y)|
                     g([ui]|r+)rl))|
                     (bot(\s|\-)?snack)/ix
      )
    {
        &::status("random praise [$::msgType,$::addressed]: $message");
        if ( rand() < .5 ) {
            $callback->("thanks $who :)");
        } else {
            $callback->(":)");
        }
        return 'NOREPLY';
    }

    if ($::addressed) {
        if ( $message =~
            /you (rock|rocks|rewl|rule|are so+ co+l|rock my socks)/ )
        {
            if ( rand() < .5 ) {
                $callback->("thanks $who :)");
            } else {
                $callback->(":)");
            }
            return 'NOREPLY';
        }
        if ( $message =~ /thank(s| you)/i ) {
            if ( rand() < .5 ) {
                $callback->(
                    $welcomes[ int( rand(@welcomes) ) ] . " " . $who );
            }
            return 'NOREPLY';
        }
    }

    return undef;
}

"praise";
