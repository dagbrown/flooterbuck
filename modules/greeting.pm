#------------------------------------------------------------------------
# greeting.pm
#
# People saying "hi"--respond in kind (some of the time)
#------------------------------------------------------------------------

use strict;
package greeting;

sub scan(&$$){
    my ($callback,$message,$who)=@_;

    if ($message =~ /^\s*(h(ello|i(\s+there)?|owdy|ey|ola)|
                         salut|bonjour|niihau|que\s*tal)
                         (\s+$::param{nick})?\s*$/xi) {
        if (!$::addressed and rand() > 0.35) {
            # 65% chance of replying to a random greeting when not
            # addressed
            return 1;
        }

        my($r) = $::hello[int(rand(@::hello))];
        $callback->($r);
        return 1;
    }
    return undef;
}

"greeting";
