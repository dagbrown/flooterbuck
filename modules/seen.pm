# $Id $

#------------------------------------------------------------------------
# "seen" bit--have you seen $PERSON recently?
#------------------------------------------------------------------------
# -- from Question

use strict;

package seen;

sub scan(&$$) {
    my ($callback,$message,$who) = @_;

    # Now with INTENSE CASE INSENSITIVITY!  SUNDAY SUNDAY SUNDAY!
    if ($message =~ /^seen (\S+)/i) {
        my $person = $1;
        $person =~ s/\?*\s*$//;
        my $seen = &::get(seen => lc $person);
        if ($seen) {
            my ($when,$where,$what) = split /$;/, $seen;
            my $howlong = time() - $when;
            $when = localtime $when;

            my $tstring = ($howlong % 60). " seconds ago";
            $howlong = int($howlong / 60);

            if ($howlong % 60) {
                $tstring = ($howlong % 60). " minutes and $tstring";
            }
            $howlong = int($howlong / 60);

            if ($howlong % 24) {
                $tstring = ($howlong % 24). " hours, $tstring";
            }
            $howlong = int($howlong / 24);

            if ($howlong % 365) {
                $tstring = ($howlong % 365). " days, $tstring";
            }
            $howlong = int($howlong / 365);
            if ($howlong > 0) {
                $tstring = "$howlong years, $tstring";
            }

            $callback->("$person was last seen on $where $tstring, ".
                        "saying: $what [$when]");
            return 1;
        }

        $callback->("I haven't seen '$person', $who");
        return 1;
    }
    return undef;
}

"seen";
