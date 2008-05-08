#------------------------------------------------------------------------
# infobot module to report ping summary statistics.
#------------------------------------------------------------------------

package ping;

my ( $no_posix, $no_socket );

BEGIN {
    eval qq{
        use Socket;
    };
    $no_socket++ if ($@);

    eval qq{
        use POSIX;
    };
    $no_posix++ if ($@);
}

sub ping {
    my $host = shift;

    # look up host outside the shell, to avoid insertion attacks
    my $inetaddr = gethostbyname($host);
    return "I can't find $host in the DNS." unless $inetaddr;
    my $addr = inet_ntoa( scalar gethostbyname($host) );
    my $ping;
    my %opts = (
        '/bin/ping'  => '-q -c 10 -w 15',
        '/sbin/ping' => '-q -c 10 -t 15'
    );
    for my $try ( sort keys %opts ) {
        if ( -x $try ) {
            $ping = $try;
            last;
        }
    }
    return "can't find a ping command." unless defined $ping;
    my $cmd = "$ping $opts{$ping} $addr";

    # http://www.amazon.com/exec/obidos/tg/detail/-/0140502416/
    unless ( open( DUCK, "$cmd |" ) ) {
        &main::status("$cmd returned $!");
        return "$ping returned an error.";
    }

    my @out;
    while (<DUCK>) {
        chomp;
        if ( /^\d+ packets transmitted/ or /^rtt/ ) {
            push( @out, "$host: $_" );
        }
    }

    close DUCK;

    if (@out) {
        return join( ", ", @out );
    } else {

        # leave this to the admin to debug.
        &main::status("$cmd returned something odd");
        return "$ping returned something I can't understand.";
    }

}

sub scan(&$$) {
    my ( $callback, $message, $who ) = @_;

    if ( $message =~ /^\s*ping\s+(\S+)\D*$/ ) {

        my $host = $1;

        if ($no_socket) {
            &main::status(
                "Sorry, ping requires Socket.pm and can't find it");
            return undef;
        }

        $SIG{CHLD} = "IGNORE";
        my $pid = eval { fork(); };    # Don't worry if OS isn't forking
        return "NOREPLY" if $pid;

        my $response = ping($host);

        $callback->($response);
        if ( defined($pid) )    # child exits, non-forking OS returns
        {
            exit 0 if ($no_posix);
            POSIX::_exit(0);
        }
        return 1;
    } else {
        return undef;
    }
}

"ping";
