#------------------------------------------------------------------------
# greeting.pm
#
# People saying "hi"--respond in kind (some of the time)
#
# $Id: greeting.pm,v 1.10 2001/12/04 17:40:27 dagbrown Exp $
#------------------------------------------------------------------------

use strict;
package greeting;

# ways to say hello
my @hello = ('hello', 
             'hi',
             'hey',
             'niihau',
             'bonjour',
             'hola',
             'salut',
             'que tal',
             'privet',
             "what's up");

sub scan(&$$){
    my ($callback,$message,$who) = @_;

    if ($message =~ /^\s*(h(ello|i(\s+there)?|owdy|ey|ola)|
                         salut|bonjour|niihau|que\s*tal)
                         (\s+$::param{nick})?\s*$/xi) {
        if (!$::addressed and rand() > 0.35) {
            # 65% chance of replying to a random greeting when not
            # addressed
            return 1;
        }

        my($r) = $hello[int(rand(@hello))];
        $callback->("$r, $who.");
        return 1;
    }
    return undef;
}

"greeting";
