#------------------------------------------------------------------------
# A VERY minimal example of how to write a New And Improved Infobot
# Module.  All it does is say "bar" when someone says "foo".
#
# $Id: Example.pm,v 1.6 2001/12/04 17:40:27 dagbrown Exp $
#------------------------------------------------------------------------

package Example;

sub scan(&$$) {
    my ($callback,$message,$who) = @_;

    if($message=~/^\s*foo\s*$/) {
        $callback->("bar");
        return 1;
    } else {
        return undef;
    }
}

"Example";
