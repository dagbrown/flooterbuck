# $Id: forget.pm,v 1.5 2001/12/04 15:33:58 rharman Exp $

#------------------------------------------------------------------------
# forget.pm
#
# A module to let people tell infobot to forget factoids.
#------------------------------------------------------------------------

use strict;
package forget;

sub scan(&$$)
{
    my ($callback,$message,$who) = @_;

    if ($message =~ s/^forget\s+((a|an|the)\s+)?//i) {
        # cut off final punctuation
        $message =~ s/[.!?]+$//;
        my $k = &::normquery($message);
        $k = lc($k);
        my $found = 0;

        foreach my  $d ("is", "are") {
            if (my $r = &::get($d, $k)) {
                if (&::IsFlag("r") ne "r") { 
                    $callback->("you have no access to remove factoids"); 
                    return 'NOREPLY'; 
                }
                $found = 1 ;
                &::status("forget: <$who> $k =$d=> $r");
                &::clear($d, $k);
                $::factoidCount--;
            }
        }

        if ($found == 1) {
            $callback->("$who: I forgot $k"); 
            my $l = $who; $l =~ s/^=//;
            $::updateCount++;
            return 'NOREPLY';
        } else { 
            $callback->("$who, I didn't have anything matching $k"); 
            return 'NOREPLY'; 
        }
    }                           # end forget
    return undef;
}

"forget";
