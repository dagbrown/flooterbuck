# $Id: karma.pm,v 1.3 2001/12/04 15:33:58 rharman Exp $

#------------------------------------------------------------------------
# Karma stuff
#------------------------------------------------------------------------

use strict;
package karma;

sub scan(&$$) {
    my ($callback,$message,$who) = @_;

    if (::getparam('plusplus')) {
        my $message2 = $message;

        # Fixes the "soandso? has neutral karma" bug. - Masque, 12Apr2k
        if ($message2 =~ s/^(?:karma|score)\s+(?:for\s+)?(.*?)\??$/$1/) {

            # Some people prefer to have a factoid for their karma.
            # This was the default behavior, pre-0.43.
            my $answer = &::doQuestion($::msgType, $message, $::msgFilter);
            if($answer) {
                $callback->($answer);
                return 1;
            }

            $message2 = lc($message2);
            $message2 =~ s/\s+/ /g;
            ::status("Karma string is currently \'$message2\'");
            $message2 ||= "blank karma";
            if ($message2 eq "me") {
                $message2 = lc($who);
            }
            my $karma = &::get(plusplus => $message2);
            if ($karma) {
                $callback->("$message2 has karma of $karma");
                return 1;
            } else {
                $callback->("$message2 has neutral karma");
                return 1;
            }
        }
    }
    return undef;
}

"karma";
