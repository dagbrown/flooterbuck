#------------------------------------------------------------------------
# "exchange" command, change currencies
#
# $Id: exchange.pm,v 1.10 2003/07/11 18:27:00 awh Exp $
#------------------------------------------------------------------------

use strict;
package exchange;

# exchange.pl - currency exchange module
#
# Last update: 2003/07/11 -- awh@awh.org, rewrote to use Yahoo.
#

my $no_exchange; 
my $no_posix;

BEGIN {
    eval qq{
        use LWP::UserAgent;
        use HTTP::Request::Common qw(POST GET);
    };

    $no_exchange++ if($@);

    eval qq{
        use POSIX;
    };

    $no_posix++ if ($@);
}

sub exchange {
    my($From, $To, $Amount) = @_;

    return "exchange.pl: not configured. needs LWP::UserAgent and HTTP::Request::Common" if( $no_exchange );

    # set up the HTTP connection
    my $ua = new LWP::UserAgent;
    $ua->agent("Mozilla/4.5 " . $ua->agent);        # Let's pretend
    if (my $proxy = main::getparam('httpproxy')) { $ua->proxy('http', $proxy) };
    $ua->timeout(10);

    # request the currency conversion from Yahoo
    my $Converter="http://finance.yahoo.com/m5?a=$Amount&s=$From&t=$To";
    my $req = GET $Converter;
    my $res = $ua->request($req);                   # Submit request

    # make sure it worked.
    if (!$res->is_success) {
       return "EXCHANGE: ". $res->status_line;
    }
      
    my $html = $res->as_string;
    
    # trim it down so it's a bit easier for me to see when I print it
    # out for debugging. 
    $html =~ s/.*Symbol//s; 
    $html =~ s/<img.*//s; 

    # gross screen-scraping.  It would be nice if they gave a nice XML
    # document, but they don't.
    my ($curnamefrom, $curnameto, $amount) = ($html =~ m/<th align=center>([^<]*)<\/th>.*<th align=center>([^<]*).*<th.*<th.*<th.*<tr.*<b>([^<]*)<\/b>/);

    # yay, it matched!
    if ($curnamefrom and $curnameto and $amount) {
        return "$Amount $curnamefrom makes $amount $curnameto";
    }

    # neither currency name got set at all.  It probably means that Yahoo
    # has changed its screen format, but it's possible that the user set
    # both input currency symbols to invalid ones.
    if ((!$curnamefrom) and (!$curnameto)) {
        return "Either '$From' and '$To' are both invalid currencies, or Yahoo changed its screen format for the currency exchanger.";
    }

    # One or the other of the currency names didn't get set.  This almost
    # certainly means that the user input a wrong currency symbol.
    if (!$curnamefrom) {
        return "'$From' probably isn't a real currency.";
    }
    if (!$curnameto) {
        return "'$To' probably isn't a real currency.";
    }

    # Uh-oh, how did we get here?
    return "Um, something bad has happened.";
}

sub scan(&$$) {
    my ($callback,$message,$who) = @_;

    # currency exchanger, bobby@bofh.dk
    if( defined(::getparam('exchange'))
            and ::getparam('exchange')
            and ($message =~ /^\s*(?:ex)?change\s+/i)){

        &::status("message($message)");
        my $response='';

        my $pid = fork;
        if ($pid) {
            # this takes some time, so fork.
            return 1;
        }

        if ($message =~ /^\s*(?:ex)?change\s+  # "exchange" 
                         ([\d\.\,]+)           # some number of $CURRENCY
                         \s+                   # (whitespace)
                         (\S+)                 # currency name
                         \s+                   # (more whitespace)
                         (?:into|to|for)       # "into" (or "to" or "for")
                         \s+                   # (more whitespace)
                         (\S+)                 # Other currency name
                         /xi) {
            my($Amount,$From,$To) = ($1,$2,$3);
            $From = uc $From;
            $To = uc $To;
            &::status("calling exchange($From, $To, $Amount) ...");
            $response = &exchange($From, $To, $Amount);
        } else {
            $response = "that doesn't look right";
        }

        &::status("exchange got response($response)");

        if($response =~ /^EXCHANGE: \S*/) {
            &::status($response);
            $callback->("$who: $response");
        } else {
            $callback->("$who: $response");
        }

        # close the child process if we fork()ed before.  Prefer 
        # POSIX::_exit(), but if the person doesn't have POSIX.pm,
        # use perl's built-in exit.
        if (defined($pid))
        {
            exit 0 if ($no_posix);
            POSIX::_exit(0);
        }
    }				# end exchange
    return undef;
}

"exchange";

__END__

=head1 NAME

exchange.pl - Exchange between currencies

=head1 PREREQUISITES

	LWP::UserAgent
	HTTP::Request::Common

=head1 PARAMETERS

exchange

=head1 PUBLIC INTERFACE

	Exchange <amount> <currency> for|[in]to <currency>

=head1 DESCRIPTION

Contacts C<finance.yahoo.com> and grabs the exchange rates.

=head1 AUTHORS

Bobby <bobby@bofh.dk>

Drew Hamilton <awh@awh.org>, rewrote for yahoo


