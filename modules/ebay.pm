#------------------------------------------------------------------------
# eBay auction status request
#
# Dave Brown
#
# $Id: ebay.pm,v 1.10 2001/12/04 17:40:27 dagbrown Exp $
#------------------------------------------------------------------------
package ebay;
use strict;


=head1 NAME

ebay.pl - get auction summary from eBay

=head1 PREREQUISITES

LWP::UserAgent

=head1 PARAMETERS

quote

=head1 PUBLIC INTERFACE

purl, quote <eBay auction ID>

=head1 DESCRIPTION

This allows you to fetch the current status of an eBay
auction.

=head1 AUTHOR

Dave Brown <dagbrown@csclub.uwaterloo.ca>

=cut

#------------------------------------------------------------------------
# Startup
#
# Check that LWP is available, so we don't waste our time
# generating error messages later on.
#------------------------------------------------------------------------
my $no_ebay;

BEGIN {
    eval qq{
        use LWP;
    };
    $no_ebay++ if ($@);
}

#------------------------------------------------------------------------
# snag_element
#
# Sifts through a slug of HTML, and returns a list of items that live
# in the container you asked for.
#------------------------------------------------------------------------
sub snag_element($$) {
    my $element=shift;
    my $blob_o_html=shift;

    return ($blob_o_html=~/\<$element[^>]*\>(.*?)\<\/$element\>/gis);
}

#------------------------------------------------------------------------
# strip_html
#
# Takes the HTML junk out of a string.  Think of it as a very poor
# man's "lynx -dump".
#------------------------------------------------------------------------
sub strip_html($) {
    my $blob=shift;
    chomp $blob;
    $blob=~s/\<[^>]+\>//g;
    $blob=~s/\&[a-z]+\;?//g;
    $blob=~s/\s+/ /g;
    return $blob;
}

#------------------------------------------------------------------------
# parse_response
#
# Given an eBay auction page, return a quick one-line summary of it
#------------------------------------------------------------------------
sub parse_response($) {
    my $response=shift;

    $response=~s/\n//g;
    $response=~s/\r//g;

    my ($title)=snag_element("title",$response);
    chomp $title,"\n";
    $title =~ s/\(Ends .*\)//g;

    my %snagged_info;

    my @columns=snag_element("td",$response); # all columns, everywhere
    my $color=0;
    my $storedinfo=undef;

    map {
        my $info=strip_html $_;
        $info=~s/^\s*//;$info=~s/\s*$//;$info=~s/\n//g;
        if($storedinfo) {
            $snagged_info{$storedinfo}=$info;
        }
        $storedinfo=$info;
    } @columns;

    my $reply = $title."[".$snagged_info{"Seller (Rating)"}."] ".
        "Qty ".$snagged_info{"Quantity"}." ".
        $snagged_info{"Currently"}.
        " [".$snagged_info{"High bid"}."] ".
        $snagged_info{"Time left"};
}

#------------------------------------------------------------------------
# auction_summary
#
# Given an eBay auction ID number, grab the page and return a
# quick summary
#------------------------------------------------------------------------
sub auction_summary($) {
    my $auction_id=shift;

    my $ua=new LWP::UserAgent;
    $ua->timeout(12);
    my $request=new HTTP::Request(
        GET=>
            'http://cgi.ebay.com/aw-cgi/eBayISAPI.dll?ViewItem&item='
            .$auction_id);
    my $response=$ua->request($request);

    return "I can't seem to reach eBay right now, sorry."
        unless $response->is_success;

    my ($title)=snag_element("title",$response->content);

    if($title eq "eBay '$auction_id' - Invalid Item") {
        return "I'm sorry, I couldn't find that item on eBay.";
    } else {
        return parse_response($response->content);
    }
}

#------------------------------------------------------------------------
# ebay_getdata
#
# Tear apart the line fed to the infobot, check its syntax,
# and feed the auction ID number into the maw of auction_summary.
#------------------------------------------------------------------------
sub ebay_getdata($) {
    my $line=shift;

    if($line =~ /ebay\s+(\d+)/i) {
        return auction_summary($1);
    } else {
        return "That doesn't look like an eBay item number";
    }
}

#------------------------------------------------------------------------
# ebay::get
#
# This handles the forking (or not) stuff.
#------------------------------------------------------------------------
sub ebay::get($$) {
    if($no_ebay) {
        &main::status("Sorry, eBay.pl requires LWP and couldn't find it");
        return "";
    }

    my($line,$callback)=@_;
    $SIG{CHLD}="IGNORE";
    my $pid=eval { fork(); };         # Don't worry if OS isn't forking
    return 'NOREPLY' if $pid;
    $callback->(&ebay_getdata($line));
    exit 0 if defined($pid);          # child exits, non-forking OS returns
}

#------------------------------------------------------------------------
# This is the main interface to infobot
#------------------------------------------------------------------------

sub scan(&$$) {
    my ($callback, $message, $who)=@_;

    if ( ::getparam('ebay') and $message =~ /^\s*ebay\s+(\d+)$/i ) {
        &main::status("eBay query");
        &ebay::get($message,$callback);
        return 1;
    }
}

"ebay";
