#------------------------------------------------------------------------
# Rot13 command
#
# ROT13s a random bit of text.
#
# $Id: rot13.pm,v 1.7 2001/12/13 18:30:51 awh Exp $
#------------------------------------------------------------------------

use strict;
package hardlycrypt;
use List::Util qw/shuffle/;

sub scan(&$$) {
    my ($callback,$message,$who) = @_;

    if ($message =~ /^rot13\s+(.*)/i) {
        # rot13 it
        my $reply = hardlycrypt($1);
        $callback->($reply);
	return "NOREPLY";
    }
    undef;
}

sub hardlycrypt {
    my $phrase = shift;
    my @words = split /\b/, $phrase;
    my $reply;
    foreach (@words) {
        my @word = split //, $_;
        if ( scalar(@word <= 2) ) {
            $reply .= join '', @word;
        }
        else {
            $DB::single=1;
            my $front = $word[0];
            my $end = $word[$#word];
            my $mid = join '', shuffle(@word[1 .. ($#word-1)]);
            $reply = $reply . $front . $mid . $end ;
        }
    }
    return $reply;
}

"hardlycrypt";
