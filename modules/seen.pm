#------------------------------------------------------------------------
# "seen" bit--have you seen $PERSON recently?
#
# $Id: seen.pm,v 1.6 2002/02/06 03:27:46 awh Exp $
#------------------------------------------------------------------------
# -- from Question
#
# 2002/02/05 - Added "close match" searches.  Drew Hamilton <awh@awh.org>

use strict;

package seen;


# ----------------------------------------------------------------------
# Returns the time difference between the current time and the passed
# time in both long and short string formats.  Long format is like
# "2 days, 4 hours, 37 minutes, and 2 seconds".  Short format is like
# "2d, 4:37:02".
# ----------------------------------------------------------------------
sub get_timediff($) {
    my $when = shift;

    my $howlong = time() - $when;
    $when = localtime $when;

    my $tstring = ($howlong % 60). " seconds ago";
    my $shorttstring = sprintf("%02d", ($howlong % 60));
    $howlong = int($howlong / 60);

    $shorttstring = sprintf("%02d", ($howlong % 60)). ":$shorttstring";
    if ($howlong % 60) {
        $tstring = ($howlong % 60). " minutes and $tstring";
    }
    $howlong = int($howlong / 60);

    $shorttstring = ($howlong % 24). ":$shorttstring";
    if ($howlong % 24) {
        $tstring = ($howlong % 24). " hours, $tstring";
    }
    $howlong = int($howlong / 24);

    if ($howlong % 365) {
        $tstring = ($howlong % 365). " days, $tstring";
        $shorttstring = ($howlong % 365). "d, $shorttstring";
    }
    $howlong = int($howlong / 365);

    if ($howlong > 0) {
        $tstring = "$howlong years, $tstring";
        $shorttstring = $howlong."y, $shorttstring";
    }

    ($tstring, $shorttstring);
}


sub scan(&$$) {
    my ($callback,$message,$who) = @_;

    # Now with INTENSE CASE INSENSITIVITY!  SUNDAY SUNDAY SUNDAY!
    if ($message =~ /^seen (\S+)/i) {
        my $person = $1;
        $person =~ s/\?*\s*$//;
        my $seen = &::get(seen => lc $person);
        if ($seen) {
            my ($when,$where,$what) = split /$;/, $seen;
            my ($tstring, $shorttstring) = &get_timediff($when);
            $callback->("$person was last seen on $where $tstring, ".
                        "saying: $what [$when]");
            return 1;
        }


        # try for a regexp search if we didn't find a direct
        # match. (direct match would already have returned)
        my @seen = &::showdb(seen => lc $person);
        my $closematches = "Close matches are: ";
        my $showmatches = 0;
        foreach (@seen) {
            my ($nick,$junk) = split / => /, $_;
            if ($nick =~ /$person/i) { # do another regexp match here, because
                                       # the match may have come back in the 
                                       # "what was said" section instead of the
                                       # "who said it" section.
                my $seen = &::get(seen => lc $nick);
                my ($when,$where,$what) = split /$;/, $seen;
                my ($tstring, $shorttstring) = &get_timediff($when);
                $closematches .= "$nick [$shorttstring], ";
                $showmatches++;
            }
        }

        $closematches =~ s/, $//;

        if ($showmatches > 10) {
            $callback->("I haven't seen '$person', $who.  There are too many close matches to list.");
        } elsif ($showmatches) {
            $callback->("I haven't seen '$person', $who.  $closematches");
        } else {
            $callback->("I haven't seen '$person', $who");
        }
        return 1;
    }
    return undef;
}

"seen";
