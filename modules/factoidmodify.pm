# $Id: factoidmodify.pm,v 1.6 2001/12/04 15:33:58 rharman Exp $

#------------------------------------------------------------------------
# Modify a factoid
# substitution: X =~ s/A/B/
#------------------------------------------------------------------------

package factoids;
use strict;

sub scan(&$$) {
    my ($callback,$message,$who)=@_;
    if ($::addressed and $message =~ m|
            ^\s*        # eat whitespace
            (.*?)       # leaving the LHS of a factoid
            \s+         # throw away whitespace
            =~          # literal "=~"
            \s+         # throw away whitespace again
            s\/         # Literal "s", and then a slash (and nought but!)
            (.+?)       # String to replace
            \/          # /
            (.*?)       # String to replace it with
            \/          # closing slash
            ([a-z]*)    # flags
            ;?          # semicolon for those who are fanatic
            \s*         # and whitespace (and NOTHING ELSE)
            $           # ...to the end of the line.
            |x) {

        my ($X, $oldpiece, $newpiece, $flags) = ($1, $2, $3, $4);
        my $matched = 0;
        my $subst = 0;
        my $op = quotemeta($oldpiece);
        my $np = $newpiece;
        $X = lc($X);

        foreach my $d ("is","are") {
            if (my $r = &::get($d, $X)) { 
                my $old = $r;
                $matched++;
                if ($r =~ s/$op/$np/i) {
                    if (length($r) > &::getparam('maxDataSize')) {
                        $callback->("That's too long, $who");
                        return 'NOREPLY';
                    }
                    &::set($d, $X, $r);
                    &::status("update: '$X =$d=> $r'; was '$old'");
                    $subst++;
                }
            }
        }

        if ($matched) {
            if ($subst) {
                $callback->("OK, $who");
                return 'NOREPLY';
            } else {
                $callback->("That doesn't contain '$oldpiece'");
            }
        } else {
            $callback->("I didn't have anything matching '$X', $who");
        }
        return 'NOREPLY';
    }				# end substitution
}

"factoids";
