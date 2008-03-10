#------------------------------------------------------------------------
# eBay auction status request
#
# Dave Brown
#
# $Id: ebay.pm,v 1.23 2004/09/17 01:46:48 dagbrown Exp $
#------------------------------------------------------------------------
package ebay;
use strict;


=head1 NAME

ebay.pl - get auction summary from eBay

=head1 PREREQUISITES

LWP::UserAgent

=head1 PARAMETERS

ebay

=head1 PUBLIC INTERFACE

purl, ebay <eBay auction ID>

purl, ebay <eBay seller nickname>

=head1 DESCRIPTION

This allows you to fetch the current status of an eBay
auction.

When called with a seller nickname, fetches abbreviated statuses for
each of his first 10 auctions.

=head1 AUTHOR

Dave Brown <dagbrown@csclub.uwaterloo.ca>

Nickname interface added by Drew Hamilton <awh@awh.org>

=cut

#------------------------------------------------------------------------
# Startup
#
# Check that LWP is available, so we don't waste our time
# generating error messages later on.
#------------------------------------------------------------------------
my ($no_ebay, $no_posix);

BEGIN {
    eval qq{
        use LWP::Simple qw();
    };
    $no_ebay++ if ($@);

    eval qq{
        use POSIX;
    };
    $no_posix++ if ($@);
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
    $blob=~s/\<br\>/; /ig;
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
    chomp $title;
    $title =~ s/\(Ends [^\)]*\)//g;
    $title =~ s/ +/ /g;

    my %snagged_info;
    my @seller_info;

    my @columns=snag_element("td",$response); # all columns, everywhere
    my $color=0;
    my $storedinfo=undef;

    my $sellerinfo_mode=0;

    map {
        my $info=strip_html $_;
        $info=~s/^\s*//;$info=~s/\s*$//;$info=~s/\n//g;
        if($info eq "Seller information") {
            $sellerinfo_mode++;
        }
        if($sellerinfo_mode>0) {
            push(@seller_info,$info);
            $sellerinfo_mode++;
            if($sellerinfo_mode>10) {
                $sellerinfo_mode=0;
            }
        }
        if($storedinfo) {
            $snagged_info{$storedinfo}=$info;
        }
        $storedinfo=$info;
    } @columns;

    @seller_info=grep {/./} @seller_info;

    # fix the Buy It Now bug
    $snagged_info{"Currently"} =~ s/Buy.*//;
    $snagged_info{"Time left:"} =~ s/ *\;.*//;

    my $reply = $title." [".$seller_info[1]."] ".
        ($snagged_info{"Current bid:"}
            || $snagged_info{"Starting bid:"}
            || $snagged_info{"Winning bid:"}) ." ".
        ($snagged_info{"Current bid:"} ?
            " [".$snagged_info{"High bidder:"}."]"
            : ($snagged_info{"Winning bid:"} ?
                " [".$snagged_info{"Winning bidder:"}."]"
                : "[no bids]")) ." ".
        ($snagged_info{"Time left:"} ?
            $snagged_info{"Time left:"}. " to go" :
            "Auction ended ".$snagged_info{"Ended:"});
}


#------------------------------------------------------------------------
# parse_seller_response
#
# Given an eBay "search by seller" results page, return summary of each
# item for sale.
#------------------------------------------------------------------------
sub parse_seller_response($) {
    my $response = shift;

    $response =~ s/\n//g;
    $response =~ s/\r//g;

    my @rows = snag_element("tr", $response);

    my ($reply, $gotreply);
    foreach (@rows)
    {
        my @cols = snag_element("td", $_);
        # it's the right row if the first column is a URL to an item listing.
        if ($cols[0] =~ m#ViewItem#) {
            my ($item) = ($cols[0] =~ /item=(\d+)/);
            my ($price) = $cols[3];
            ($price) = snag_element("b", $price) if ($price =~ /<b>/); 
            $price .= " (No Bids)" if ($cols[5] =~ m#No Bids#);
            $reply .= "$item - $price, ";
            $gotreply++;
        }
    }

    $reply =~ s/, $//;
    $reply = "No listings by that seller.\n" unless ($gotreply);
    $reply;
}

#------------------------------------------------------------------------
# auction_summary
#
# Given an eBay auction ID number, grab the page and return a
# quick summary
#------------------------------------------------------------------------
sub auction_summary {
    my $auction_id=shift;

    my $response;
    if($auction_id =~ /^[0-9]+$/) {
        $response=LWP::Simple::get(
            'http://cgi.ebay.com/aw-cgi/eBayISAPI.dll?ViewItem&item='
            .$auction_id);
    }

    if($auction_id =~ /http:\/\/.*ebay.com\/.*item=\d+/) {
        $response=LWP::Simple::get($auction_id);
    }

    my ($title)=snag_element("title",$response);

    if($title =~ /Invalid Item/) {
        return "I'm sorry, I couldn't find that item on eBay.";
    } else {
        return parse_response($response);
    }
}

#------------------------------------------------------------------------
# auction_sellerlist
#
# Given an eBay seller ID, grab the page and return a
# quick summary of his first 10 auctions listed.
#------------------------------------------------------------------------
sub auction_sellerlist($) {
    my $seller_id=shift;

    my $response=LWP::Simple::get(
        "http://cgi6.ebay.com/aw-cgi/eBayISAPI.dll?MfcISAPICommand=ViewListedItems&userid=$seller_id&include=0&since=-1&sort=3&rows=10");

    my ($title)=snag_element("title",$response);

    if($title =~ /User Error/) {
        return "I'm sorry, I couldn't find that seller ID on eBay.";
    } else {
        return parse_seller_response($response);
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

    if(
        ($line =~ /ebay\s+(\d+)/i && ($1 > 0)) 
            or
        ($line =~ /ebay\s+(http:\/\/.*ebay.com\/\S*item=\d+\S*)/)
    ) {
        return auction_summary($1); 
    } elsif($line =~ /ebay\s+that/i) {
        my $auction_url=::lastURL(::channel());
        if($auction_url =~ /http:\/\/.*ebay.com\/\S*item=\d+\S*/) {
            return auction_summary($auction_url);
        } else {
            if($::addressed){
                return "The last URL wasn't eBay";
            } else {
                # don't say anything (assume someone saying "ebay that then")
                return 'NOREPLY'; 
            }
        }
    } elsif ($line =~ /ebay\s+(\S+)/i) {
        return auction_sellerlist($1);
    } else {
        return "That doesn't look like an eBay item number or seller ID.\n";
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
    if (defined($pid))                # child exits, non-forking OS returns
    {
        exit 0 if ($no_posix);
        POSIX::_exit(0);
    }
}

#------------------------------------------------------------------------
# This is the main interface to infobot
#------------------------------------------------------------------------

sub scan(&$$) {
    my ($callback, $message, $who)=@_;

    if ( ::getparam('ebay') and $message =~ /^\s*ebay\s+(\S+)\s*$/i ) {
        &main::status("eBay query");
        &ebay::get($message,$callback);
        return 1;
    }
}

#------------------------------------------------------------------------
# And the help text
#------------------------------------------------------------------------

sub help {
    q(Say "ebay" and then a number, and I'll summarize that auction for you.  If someone pasted an eBay URL recently, you can say "ebay that" and I'll summarize.);
}

"ebay";
