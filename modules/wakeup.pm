#------------------------------------------------------------------------
# "shut up" and "wake up" commands - control how much it rattles on
#------------------------------------------------------------------------

use strict;

package wakeup;

sub scan(&$$) {
    my ($callback, $message, $who) = @_;

    # Aldebaran++ !
    if (::getparam("shutup")) {
        if ($message =~ /^\s*wake\s*up\s*$/i ) {
            if ($::msgType =~ /public/) {
                if ($::addressed) {
                    if (rand() > 0.5) {
                        &::status("Changing to Optional mode");
                        # Oh shit. - Simon
                        $::chanopts{::channel()}->{'addressing'} = 'OPTIONAL';
                        &$callback("OK, ".$who.", I'll start talking.");
                    } else {
                        &$callback(":O");
                    }
                }
            } else {
                &$callback("OK, I'll start talking.");
                $::param{'addressing'} = 'OPTIONAL';
                &::status("Changing to Optional mode");
            }
            return 1;
        } elsif ($message =~ /^\s*shut\s*up\s*$/i ) {
            if ($::msgType =~ /public/) {
                if ($::addressed) {
                    if (rand() > 0.5) {
                        &$callback("Sorry, ".$who.", I'll keep my mouth shut. ");
                        $::chanopts{::channel()}->{'addressing'} = 'REQUIRE';
                        &::status("Changing to Require mode");
                    } else {
                        &$callback(":X");
                    }
                } 
            } else {
                &$callback("Sorry, I'll try to be quiet.");
                $::param{'addressing'} = 'REQUIRE';
                &::status("Changing to Require mode");
            }
            return 1;
        } 
    }
    return undef;
}

"wakeup";
