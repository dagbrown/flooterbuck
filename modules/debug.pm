#------------------------------------------------------------------------
# debug.pm
#
# Very verbosely sends status out to the logfile whenever anyone
# says anything ever.  Not recommended for actual running
# infobots, but for broken infobots, it's awesome.
#
# $Id: debug.pm,v 1.4 2001/12/04 17:40:27 dagbrown Exp $
#------------------------------------------------------------------------

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
