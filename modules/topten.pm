#------------------------------------------------------------------------
# Top Ten module
#
# See the POD documentation (right here!) for more info
#
# $Id: topten.pm,v 1.7 2005/05/19 20:06:36 rich_lafferty Exp $
#------------------------------------------------------------------------

=head1 NAME

topten.pm - List the top 10 participants by karma or by number of
lines spoken, or the bottom 10 participants by karma.

=head1 PREREQUISITES

An understanding of the numbers from 1 to 10

=head1 PARAMETERS

topten [karma]
bottomten karma

=head1 SERVING SUGGESTION

floot, topten
floot, topten karma
floot, bottomten karma

=head1 DESCRIPTION

topten returns the most frequent channel participant, by lines spoken.
topten karma returns the 10 highest-karma participants.  bottomten karma
returns the 10 lowest-karma participants

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
    my ( $callback, $message, $who ) = @_;

    # Now with INTENSE CASE INSENSITIVITY!  SUNDAY SUNDAY SUNDAY!
    if ( $message =~ /^(?:topten|bottomten)(?:\s+karma)?\s*[?!.]?$/i ) {
        my @showtop;
        my $reply;
        if ( $message =~ /karma/i ) {
            if ( $message =~ /bottomten/i ) {
                @showtop = &::showtop( "plusplus", 10, "bottom" );
                $reply = "Bottom 10 karma is: ";
            } else {
                @showtop = &::showtop( "plusplus", 10, "top" );
                $reply = "Top 10 karma is: ";
            }
        } else {
            if ( $message =~ /topten/i ) {
                @showtop = &::showtop( "topten", 10, "top" );
                $reply = "Top 10 are: ";
            } else {
                @showtop = &::showtop( "topten", 10, "bottom" );
                $reply = "Bottom 10 are: ";
            }
        }
        my $counter = 1;
        foreach (@showtop) {
            my ( $nick, $lines ) = split(/ => /);
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
