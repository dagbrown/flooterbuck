#------------------------------------------------------------------------
# "joinleave" module
#
# Lets you tell the bot to leave or join channels
#
# $Id: joinleave.pm,v 1.8 2004/09/03 00:24:38 dagbrown Exp $
#------------------------------------------------------------------------

use strict;
package joinleave;

sub scan(&$$) {
    my ($callback,$message,$who) = @_;

    if ($message =~ /^join ([\&\#]\S+)(?:\s+(\S+))?$/i 
            and $::msgType !~ /public/) {

        my($which, $key) = ($1, $2);
        $key = defined ($key) ? " $key" : "";

        my ($chan,$ok_to_join);

        foreach $chan (split(/\s+/, $::param{'allowed_channels'})) {
            if (lc($which) eq lc($chan)) { 
                $ok_to_join = $which . $key; 
                last; 
            }
        }

        # if user is +o, do it anyway
        if (&::IsFlag("o")) { 
            $ok_to_join = $which.$key; 
        }

        if ($ok_to_join) {

            if (&::IsFlag("c") ne "c") { 
                &msg($who, "You don't have the channel flag"); 
                return 'NOREPLY'; 
            }

            &::joinChan($ok_to_join);
            &::status("JOIN $ok_to_join <$who>");
            $callback->("joining $ok_to_join") 
                unless ($::channel eq &::channel());

            sleep(1); # FIXME why is this here? 
            return 'NOREPLY'; # handled

        } else {
            $callback->($who,"I am not allowed to join that channel.");
            return 'NOREPLY';
        }

    } elsif ($message =~ /^(leave|part) ([\&\#]\S+)(?:\s+(\S+))?$/i) {

        if (&::IsFlag("o") || $::addressed) {
            if (&::IsFlag("c") ne "c") { 
                $callback->("you don't have the channel flag"); 
                return 'NOREPLY'; 
            }
        }
        &::channel($2);
        $callback->("goodbye, $who.");
        &::part($2);
        return 'NOREPLY';
    } else {
        return undef; # unhandled
    }
}

"joinleave";
