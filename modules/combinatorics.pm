#------------------------------------------------------------------------
# Combinatorics Module
#
# See the POD documentation (right here!) for more info
#
# $Id: combinatorics.pm,v 1.2 2003/03/10 15:38:22 awh Exp $
#------------------------------------------------------------------------


=head1 NAME

combinatorics.pm - Returns some combinatorics functions -- permutation,
combination, and factorial

=head1 PREREQUISITES

The knowledge of what permutation, combination, and factorial mean.

=head1 SERVING SUGGESTION

 floot, 47 choose 7
 floot, 47 combine 7
 floot, 47 combination 7
 floot, 47 c 7

 floot, 10 permute 3
 floot, 10 permutation 3
 floot, 10 p 3

 floot, 8 factorial
 floot, 8!

=head1 DESCRIPTION

 x choose y - The number of different ways of drawing y things from a
field of x, without replacement, where order does not matter.  For
example, in 10 choose 3, (1 8 7) is considered an equivalent result to
(7 8 1), and the two will only be counted as one result.  The most
well-known application is calculating lottery odds.

 x permute y - The number of different ways of drawing y things from a
field of x, wihout replacement, where order does matter.  Unlike x
choose y, (1 8 7) is a different result from (7 8 1).  An example of
an application would be to county the number of 4-letter passwords can
be generated using a selection of 10 letters, without repeating any
letters.

 x factorial - The number of different ways of arranging x items.

=head1 AUTHOR

Drew Hamilton <awh@awh.org>

=cut

use strict;
package combinatorics;

sub scan(&$$) {
    my ($callback,$message,$who) = @_;

    if ($message =~ /^\s*(\d*)\s*(\s+factorial|\!)\s*$/i) {
	if ($1 > 200) {
		$callback->("I don't like big numbers like that.");
		return "NOREPLY";
	}
        my $reply = &fact($1);
        $callback->($reply);
	return "NOREPLY";
    }
   
# x C y == x! / y! * (x-y)! 
    if ($message =~ /^\s*(\d*)\s+(?:choose|combin(?:e|ation)|c)\s+(\d*)\s*$/i) {
	if (($1 > 200) || ($2 > 200)) {
		$callback->("I don't like big numbers like that.");
		return "NOREPLY";
	}
        my $reply = &fact($1)/(&fact($2)*&fact($1-$2));
        $callback->($reply);
	return "NOREPLY";
    }
   
# x P y == x! / (x-y)! 
    if ($message =~ /^\s*(\d*)\s+(?:permut(?:e|ation)|p)\s+(\d*)\s*$/i) {
	if (($1 > 200) || ($2 > 200)) {
		$callback->("I don't like big numbers like that.");
		return "NOREPLY";
	}
        my $reply = &fact($1)/&fact($1-$2);
        $callback->($reply);
	return "NOREPLY";
    }


	
    undef;
}

# calculates factorials.  Yes, it doesn't look recursive like your CS
# textbook.  Instead, it looks iterative so it's actually fast.
#
# of course, x! == x * (x-1) * (x-2) * ... * 1
#            x! == 1 when x == 0;
sub fact($)
{
	my $i;
	my $fact = shift();

	if ($fact > 400) {
		return 1;
	}

	my $resp = 1;
	for ($i = 1; $i <= $fact; $i++) {
		$resp *= $i;
	}
	$resp;
}

"combinatorics";
