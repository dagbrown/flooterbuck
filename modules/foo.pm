#!/usr/bin/perl

#------------------------------------------------------------------------
# A VERY minimal example of how to write a New And Improved Infobot
# Module.  All it does is say "bar" when someone says "foo".
#------------------------------------------------------------------------

package foo;

sub scan(&$$) {
    my $callback=shift;
    my $message=shift;
    my $who=shift;

    if($message=~/^\s*foo\s*$/) {
        $callback->("bar");
        return 1;
    } else {
        return undef;
    }
}

"foo";
