#------------------------------------------------------------------------
# A VERY minimal example of how to write a New And Improved Infobot
# Module.  All it does is say "bar" when someone says "foo".
#
# $Id: example.pm,v 1.1 2004/09/12 21:44:06 dagbrown Exp $
#------------------------------------------------------------------------

package example;

sub scan(&$$) {
    my ($callback,$message,$who) = @_;

    if($message=~/^\s*foo\s*$/) {
        $callback->("bar");
        return 1;
    } else {
        return undef;
    }
}

"example";
