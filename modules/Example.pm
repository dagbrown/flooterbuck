#!/usr/bin/perl

#------------------------------------------------------------------------
# A VERY minimal example of how to write a New And Improved Infobot
# Module.  All it does is say "bar" when someone says "foo".
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
