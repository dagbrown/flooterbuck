#------------------------------------------------------------------------
# Magic 8-ball
#------------------------------------------------------------------------

use strict; 

package magic8ball;

my @m8_answers;

sub scan(&$$) {
    my ($callback,$message,$who)=@_;

    # divine added routine (boojum++)
    if ($message =~ /^(8-?ball|divine)\s+(.*)/i) {
        my %m8ball = ('original'  => 'shakes the psychic black sphere...',
                      'sarcastic' => 'shakes the psychic purple sphere...',
                      'userdef'   => 'shakes the psychic prismatic sphere...',
		      );

        if (!@m8_answers) {
            my $answer_file  =  ::getparam('magic8_answers') 
                || "$::param{miscdir}/magic8.txt";

            print "reading from $answer_file\n";

            if (open MAGIC8, "<$answer_file") {
                while (<MAGIC8>) {
                    chomp;
                    push @m8_answers, $_;
                }
            } else {
                @m8_answers = ('the Magic Ball is cloudy or missing a fact file.');
            }
        }

        my ($type, $reply) = split /\s+=>\s+/, $m8_answers[rand(@m8_answers)];

        $callback->("\cAACTION $m8ball{$type}\cA");
        $callback->("It says '$reply,' $who");
        return 'NOREPLY';
    }
    return undef;
}

return "magic8ball";
