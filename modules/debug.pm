#!/usr/bin/perl

package debug;

sub scan(&$$) {
    my $callback=shift;
    my $message=shift;
    my $who=shift;
    my $channel = &::channel();
    my $is_o = &::IsFlag("o");
    &::status("message = '$message', who = '$who', channel = '$channel' is_o = '$is_o' addressed = '$::addressed'");
    return ''
}

"debug";
