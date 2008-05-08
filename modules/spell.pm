#
# spell.pm -- spellchecker based on ispell
#
# This is a straight port of doce's Speller.pl for infobot to
# flooterbuck.

package spell;

my $no_ispell;

BEGIN {

    # remember, system()'s logic is backwards.
    $no_ispell++ unless system("echo a | ispell -a -S") == 0;
}

sub spell {
    my $in = shift;

    return "$in looks funny" unless $in =~ /^\w+$/;

    #derr@rostrum# ispell -a
    #@(#) International Ispell Version 3.1.20 10/10/95
    #peice
    #& peice 4 0: peace, pence, piece, price

    my @tr = `echo $in | ispell -a -S`;

    if ( grep /^\*/, @tr ) {
        return "'$in' may be spelled correctly";
    } else {
        @tr = grep /^\s*&/, @tr;
        chomp $tr[0];
        ( $junk, $word, $junk, $junk, @rest ) =
          split( /\ |\,\ /, $tr[0] );
        my $result = "Possible spellings for $in: @rest";
        if ( scalar(@rest) == 0 ) {
            $result = "I can't find alternate spellings for '$in'";
        }
        return $result;
    }
    return '';
}

sub scan(&$$) {
    my ( $callback, $message, $who ) = @_;

    if ( $message =~ /^\s*spell\s+(\S+)\D*$/ ) {

        my $word = $1;

        if ($no_ispell) {
            &main::status(
                "Sorry, spell requires ispell(1) and can't find it");
            return undef;
        }

        my $response = spell($word);

        $callback->($response);
        return 1;
    } else {
        return undef;
    }

}

"spell";

