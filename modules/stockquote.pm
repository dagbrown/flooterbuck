#------------------------------------------------------------------------
# Yahoo module
#
# See the POD documentation (right here!) for more info
#------------------------------------------------------------------------

=head1 NAME

quote.pm - get a stock quote from Yahoo

=head1 PREREQUISITES

LWP::UserAgent, infobot

=head1 PARAMETERS

quote

=head1 SERVING SUGGESTION

purl, quote <ticker symbol>
sigio, stock price for <ticker symbol>

=head1 DESCRIPTION

This allows you to fetch the current value of a stock, subject to
Yahoo!'s 20-minute delay (15 minutes for NASDAQ).

=head1 AUTHOR

Dave Brown <dagbrown@csclub.uwaterloo.ca>

Yahoo! URL from the original stockquote.pl by LotR <martijn@earthling.net>
which was based on quote.pl from Xachbot (http://www.xach.com/xachbot/quote.pl)

=head1 NOTE

This is an example of how to do New And Improved Infobot Modules.

=cut

package stockquote;
use strict;

#------------------------------------------------------------------------
# Startup
#
# Check that LWP is available, so we don't waste our time
# generating error messages later on.
#------------------------------------------------------------------------
my $no_quote;

BEGIN {
    eval qq{
        use LWP;
    };
    $no_quote++ if ($@);
}

#------------------------------------------------------------------------
# commify
# 
# Add commas into a number (stolen from the perl FAQ)
#------------------------------------------------------------------------
sub commify {
    local $_  = shift;
    1 while s/^([-+]?\d+)(\d{3})/$1,$2/;
    return $_;
}

#------------------------------------------------------------------------
# parse_response
#
# Given an eBay auction page, return a quick one-line summary of it
#------------------------------------------------------------------------
sub parse_response($$) {
    my $response=shift;
    my $symbol=shift;

    $response=~s/["\s]//g;

    my ($name, $current, $date, $time, $change, 
        $open, $min, $max, $volume )=split /,/,$response;

    return "No such ticker symbol $symbol"
        if $min eq "N/A" and $max eq "N/A" and $change eq "N/A"
           and $date eq "N/A";

    return "$name last $date $time: $current $change ($min - $max) ".
        "[Open $open] Vol ".commify($volume);
}

#------------------------------------------------------------------------
# quote_summary
#
# Given a ticker symbol, get the Really Brief Summary from Yahoo as CSV
#------------------------------------------------------------------------
sub quote_summary($) {
    my $symbol=shift;

    my $ua=new LWP::UserAgent;
    my $request=new HTTP::Request(
        GET=>'http://quote.yahoo.com/d/quotes/csv?s='
             . $symbol
             . '&f=sl1d1t1c1ohgv&e=.csv'
    );
    my $response=$ua->request($request);

    return "I can't seem to reach Yahoo right now, sorry."
        unless $response->is_success;

    return parse_response($response->content,$symbol);
}

#------------------------------------------------------------------------
# stockquote::scan
#
# This is the main interface to infobot.  It checks to see whether
# this is relevant or not, if it is then it goes and grabs the stock
# quote.
#------------------------------------------------------------------------

sub scan(&$$) {
    my ($callback,$message,$who)=@_;

    if ($message =~ /^(?:quote|stock price)(?: of| for)? ([A-Z]{1,7})\?*$/) {
        if($no_quote) {
            &main::status("Sorry, quote requires LWP and couldn't find it");
            return undef;
        }
        $SIG{CHLD}="IGNORE";
        my $pid=eval { fork(); };         # Don't worry if OS isn't forking
        return 'NOREPLY' if $pid;
        $callback->(quote_summary($1));
        exit 0 if defined($pid);          # child exits, non-forking OS returns
        return 1;
    } else {
        return undef;
    }
}


"stockquote";
