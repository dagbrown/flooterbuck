#------------------------------------------------------------------------
# Yahoo stock quote module
#
# See the POD documentation (right here!) for more info
#
# $Id: stockquote.pm,v 1.9 2002/02/04 17:52:24 awh Exp $
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
sigsegv, index <popular index name>

=head1 DESCRIPTION

This allows you to fetch the current value of a stock, subject to
Yahoo!'s 20-minute delay (15 minutes for NASDAQ).

index <mnemonic> will fetch index values from the same server, but
without the user having to remember stupid index ticker symbols that
bear no resemblance whatsoever to the actual index name.

=head1 AUTHOR

Dave Brown <dagbrown@csclub.uwaterloo.ca>

Yahoo! URL from the original stockquote.pl by LotR <martijn@earthling.net>
which was based on quote.pl from Xachbot (http://www.xach.com/xachbot/quote.pl)

index added by Drew Hamilton <awh@awh.org>

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
my ($no_quote, $no_posix);

BEGIN {
    eval qq{
        use LWP;
    };
    $no_quote++ if ($@);

    eval qq{
        use POSIX;
    };
    $no_posix++ if ($@);
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
# get_index_symbol
#
# Given an index mnemonic, retreive the actual ticker symbol for that
# index.  Based on the indexes that Drew Hamilton <awh@awh.org> feels
# are popular on January 26, 2002.  So obviously it's a complete list.
#------------------------------------------------------------------------
sub get_index_symbol($)
{
    my $index_name=shift;

    $index_name =~ tr/A-Z/a-z/;

    return "^DJI" if ($index_name eq "djia");
    return "^IXIC" if ($index_name eq "nasdaq");
    return "^GSPC" if ($index_name eq "sp500");
    return "^TSE" if ($index_name eq "tse300");
    return "^FTSE" if ($index_name eq "ftse");
    return "^n225" if ($index_name eq "nikkei");

    return "notfound:djia, nasdaq, sp500, tse300, ftse, nikkei";
}

#------------------------------------------------------------------------
# stockquote::scan
#
# This is the main interface to infobot.  It checks to see whether
# this is relevant or not, if it is then it goes and grabs the stock
# quote.
#------------------------------------------------------------------------

sub scan(&$$) {
    my ($callback,$message,$who) = @_;
    my ($symbol);

    if ($message =~ /^(?:quote|stock price|index)(?: of| for)? (\^?[A-Z.0-9]{1,8})\?*$/i) {
        if($no_quote) {
            &main::status("Sorry, quote requires LWP and couldn't find it");
            return undef;
        }
        $SIG{CHLD}="IGNORE";
        my $pid=eval { fork(); };         # Don't worry if OS isn't forking
        return 'NOREPLY' if $pid;

	$symbol = $1;
	if ($message =~ /index/)
	{
	    $symbol = &get_index_symbol($symbol);
	    if ($symbol =~ s/^notfound://) {
	        $callback->("I don't know that index name!  I know $symbol");
                if (defined($pid))
                {
	            exit 0 if ($no_posix);
                    POSIX::_exit(0);
                }
	        return 1;
	    }
	}
        $callback->(quote_summary(uc($symbol)));
        if (defined($pid))               # child exits, non-forking OS returns
        {
            exit 0 if ($no_posix);
            POSIX::_exit(0);
        }
        return 1;
    } else {
        return undef;
    }
}


return "stockquote";
