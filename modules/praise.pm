#------------------------------------------------------------------------
# Random praise: "Good bot"
#------------------------------------------------------------------------

use strict;
package praise;

sub scan(&$$) {
    my ($callback,$message,$who) = @_;

# Gotta be gender-neutral here... we're sensitive to purl's needs. :-)
    if ($message =~ /(good(\s+fuckin[\'g]?)?\s+(bo(t|y)|g([ui]|r+)rl))|(bot(\s|\-)?snack)/i) {
        &::status("random praise [$::msgType,$::addressed]: $message");
        if (rand()  < .5)  {
            $callback->("thanks $who :)");
        } else {
            $callback->(":)");
        }
        return 'NOREPLY';
    }

    if ($::addressed) {
        if ($message =~ /you (rock|rocks|rewl|rule|are so+ co+l)/) {
            if (rand()  < .5)  {
                $callback->("thanks $who :)");
            } else {
                $callback->(":)");
            }
            return 'NOREPLY';
        }
        if ($message =~ /thank(s| you)/i) {
            if (rand()  < .5)  {
                $callback->($::welcomes[int(rand(@::welcomes))]." ".$who);
            }
            return 'NOREPLY';
        }
    }

    return undef;
}

"praise";