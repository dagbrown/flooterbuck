#!/usr/bin/perl

package ups;
use strict;

my $ups_version = "1.03f";

#------------------------------------------------------------------------
# Startup
#
# Check that LWP is available, so we don't waste our time
# generating error messages later on.
#------------------------------------------------------------------------
my $no_ups;

BEGIN {
    eval qq{
        use LWP;
    };
    $no_ups++ if ($@);
}

#------------------------------------------------------------------------
# strip_html
#
# Takes the HTML junk out of a string.  Think of it as a very poor
# man's "lynx -dump".
#------------------------------------------------------------------------
sub strip_html($) {
    my $blob=shift;
    $blob=~s,</tr>|<br>,,gi;
    $blob=~s/&nbsp;/ /sgi;
    $blob=~s/\<[^>]+\>//g;
    $blob=~s/\s+/ /g;

    $blob =~ s/\&amp;/&/g;

    $blob=~s/\&[a-z]+\;?//ig;
    return $blob;
}

#------------------------------------------------------------------------
# track_it
#
# Given an UPS tracking #, grab the page and return a
# quick summary
#------------------------------------------------------------------------
sub track_it($) {
    my $track_num=uc(shift);

    my $ua=new LWP::UserAgent;
    my $request=new HTTP::Request(
        GET=>
	"http://wwwapps.ups.com/etracking/tracking.cgi?tracknums_displayed=1&TypeOfInquiryNumber=T&HTMLVersion=4.0&InquiryNumber1=$track_num&track=Track"
    );
    my $response=$ua->request($request);

    return "I can't seem to reach UPS right now, sorry." unless $response->is_success;
    
    my $stripped = strip_html($response->content);

    return ("Sorry, I can't find any information on that tracking number.") if ($stripped =~ /One or more of the numbers you entered are not valid UPS Tracking Numbers/);

# delete up to the point of usable data (we don't need the header stuff)
# the '1.' we search for is actually the itemized tracking list.
    $stripped =~ s/^.*1\.//;

# delete from the end of usable data to EOL.  We don't need the notice or
# anything else past it.
    $stripped =~ s/NOTICE:.*$//;

# rewrite the timestamp to make it more succinct.
    $stripped =~ s/Tracking results provided by UPS:/. Results as of/;

# get rid of spaces followed by periods.
    $stripped =~ s/\s+\./\./g;

# OK, this next block is because the tracking # in the response
# is returned as "1Z 828 747 7277 1 ......" and it takes up a
# lot of space (plus is redundant).  I start removing spaces
# from the beginning until we've got a full tracking # with
# no internal spaces ("1Z82874772771 ....", then I just get rid of it.

    while (!($stripped =~ /^$track_num/)) {
      $stripped =~ s/ // ;
    }

    $stripped =~ s/^$track_num//;

# get rid of multiple spaces
    $stripped =~ s/\s+/ /g;

    return $stripped;
}

#------------------------------------------------------------------------
# ups_getdata
#
# Tear apart the line fed to the infobot, check its syntax,
# and feed the auction ID number into the maw of auction_summary.
#------------------------------------------------------------------------
sub ups_getdata($) {
    my $line=shift;

    if($line =~ /ups\s+(.+)/i) {
        return track_it($1);
    } else {
        return "That doesn't look like a UPS tracking number ($1).";
    }
}

#------------------------------------------------------------------------
# ups::get
#
# This is the main interface to infobot.  It handles the forking
# (or not) stuff.
#------------------------------------------------------------------------
sub ups::get($$) {
    if($no_ups) {
        &main::status("Sorry, UPS.pl requires LWP and couldn't find it");
        return "";
    }

    my($line,$callback)=@_;
    $SIG{CHLD}="IGNORE";
    my $pid=eval { fork(); };         # Don't worry if OS isn't forking
    return 'NOREPLY' if $pid;
    $callback->(&ups_getdata($line));
    exit 0 if defined($pid);          # child exits, non-forking OS returns
}

1;

__END__

=head1 NAME

UPS.pl - get tracking info from UPS

=head1 PREREQUISITES

LWP::UserAgent

=head1 PARAMETERS

quote

=head1 PUBLIC INTERFACE

purl, ups <TRACKING #>

=head1 DESCRIPTION

This allows you to fetch the current status of a UPS
delivery.

=head1 AUTHOR

Seth Bromberger <seth@bromberger.com>

=head1 CREDITS

Thanks to Dave Brown <dagbrown@csclub.uwaterloo.ca> for the base
code and several subroutines, pilfered shamelessly from his
eBay module.

=end
