#------------------------------------------------------------------------
# Top Ten module
#
# See the POD documentation (right here!) for more info
#
# $Id: topten.pm,v 1.1 2002/08/13 17:27:51 awh Exp $
#------------------------------------------------------------------------


=head1 NAME

topten.pm - List the top 10 participants by karma or by number of
lines spoken

=head1 PREREQUISITES

An understanding of the numbers from 1 to 10

=head1 PARAMETERS

topten [karma]

=head1 SERVING SUGGESTION

floot, topten
floot, topten karma

=head1 DESCRIPTION

topten returns the most frequent channel participant, by lines spoken.
topten karma returns the 10 highest-karma participants.

=head1 AUTHOR

This module, and the corresponding changes to the Infobot core, were
written by Drew Hamilton <awh@awh.org>

=head1 NOTE

This module will not work properly if the infobot is not maintaining
a "topten" database.  

=cut

use strict;

package topten;

sub scan(&$$) {
    my ($callback,$message,$who) = @_;

    # Now with INTENSE CASE INSENSITIVITY!  SUNDAY SUNDAY SUNDAY!
    if ($message =~ /^topten/i) {
	my @showtop;
	my $reply;
	if ($message =~ /karma/i) {
        	@showtop = &::showtop("plusplus" ,10);
		$reply = "Top 10 karma is: ";
	} else {
		@showtop = &::showtop("topten", 10);
		$reply = "Top 10 are: ";
	}
	my $counter = 1;
	foreach (@showtop)
	{
		my ($nick, $lines) = split(/ => /);
		$reply .= "$counter. $nick ($lines), ";
		$counter++;
	}
	$reply =~ s/, $//;
        $callback->($reply);
        return 1;
    }
    return undef;
}

"topten";
