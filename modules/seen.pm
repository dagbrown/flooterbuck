#------------------------------------------------------------------------
# "seen" bit--have you seen $PERSON recently?
#
# $Id: seen.pm,v 1.8 2004/04/25 22:10:03 dagbrown Exp $
#------------------------------------------------------------------------
# -- from Question
#
# 2002/02/05 - Added "close match" searches.  Drew Hamilton <awh@awh.org>

use strict;

package seen;


# ----------------------------------------------------------------------
# Returns the time difference between the current time and the passed
# time in both long and short string formats.  Long format is like
# "2 days and 4 hours".  Short format is like "2d, 4:37:02".
# ----------------------------------------------------------------------
sub get_timediff($) {
    my $when = shift;

    my $howlong = time() - $when;
    $when = localtime $when;


    my @tstring = (($howlong % 60). " second".(($howlong%60>1)&&"s"));
    my $shorttstring = sprintf("%02d", ($howlong % 60));
    $howlong = int($howlong / 60);

    $shorttstring = sprintf("%02d", ($howlong % 60)). ":$shorttstring";
    if ($howlong % 60 > 0) {
        unshift @tstring, ($howlong % 60). " minute".(($howlong%60>1)&&"s");
    }
    $howlong = int($howlong / 60);

    $shorttstring = ($howlong % 24). ":$shorttstring";
    if ($howlong % 24 > 0) {
        unshift @tstring, ($howlong % 24). " hour".(($howlong%24>1)&&"s");
    }
    $howlong = int($howlong / 24);

    if ($howlong % 365 > 0) {
        $shorttstring = ($howlong % 365). "d, $shorttstring";
        unshift @tstring, ($howlong % 365). " day".(($howlong%365>1)&&"s");
    }
    $howlong = int($howlong / 365);

    if ($howlong > 0) {
        unshift @tstring, "$howlong years";
        $shorttstring = $howlong."y, $shorttstring";
    }

    my $tstring;
    if(scalar(@tstring)==1) {
        $tstring=$tstring[0];
    } else {
        $tstring="$tstring[0] and $tstring[1]"
    }
    return ($tstring, $shorttstring);
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
            $callback->("$person was last seen on $where $tstring ago, ".
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
