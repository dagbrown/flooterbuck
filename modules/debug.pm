# $Id: debug.pm,v 1.3 2001/12/04 15:33:58 rharman Exp $

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
