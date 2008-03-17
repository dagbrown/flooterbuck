#------------------------------------------------------------------------
# Hardlycrypt command
#
# Hardly crypts a block of text.
# Haldry cprtys a boclk of txet.
#------------------------------------------------------------------------
 
use strict;
package hardlycrypt;
use List::Util qw/shuffle/;

sub scan(&$$) {
    my ($callback,$message,$who) = @_;
    if ($message =~ /^hardlycrypt\s+(.*)/i) {
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
            my $front = $word[0];
            my $end = $word[$#word];
            my $mid = join '', shuffle(@word[1 .. ($#word-1)]);
            $reply = $reply . $front . $mid . $end ;
        }
    }
    return $reply;
}

"hardlycrypt";
