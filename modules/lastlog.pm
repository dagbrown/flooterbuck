#------------------------------------------------------------------------
# Lastlog module
#
# See the POD documentation (right here!) for more info
#
# $Id: lastlog.pm,v 1.1 2006/10/02 23:56:44 rich_lafferty Exp $
#------------------------------------------------------------------------

use strict;

package lastlog;

sub scan(&$$) {
    my ($callback,$message,$who) = @_;

    if ($message =~ /^lastlog\W*$/i) {
    	my @lastlog;
    	my $reply;
    	my $counter = 0;
    	@lastlog = &::showtop("seen", 10, "top");
    	foreach (@lastlog)
    	{
			/(.*?) => (\d+)/;
			my ($nick, $epoch) = ($1, $2);
			my $elapsed = time() - $epoch;
			last if $elapsed > 86400;
			my $hours = int($elapsed / (60*60));
			my $minutes = int(($elapsed - ($hours*60*60)) / 60);
			
			$reply .= "$nick (" . 
			          ($hours ? "${hours} hrs, " : "") .
					  ($minutes ? "${minutes} min " : "") .
					  ($elapsed ? "ago" : "just now") . "), ";
			$counter++;
    	}
		$reply =~ s/, $//;
        $callback->($reply);
        return 1;
	}
    return undef;
}

"lastlog";
