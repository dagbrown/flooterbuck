#------------------------------------------------------------------------
# Earthquake 
#
# Drew Hamilton
#
#------------------------------------------------------------------------
package earthquake;
use strict;

=head1 NAME

earthquake.pm - Displays the most recent earthquake that the USGS knows about

=head1 PREREQUISITES

LWP::UserAgent

=head1 PARAMETERS

earthquake

=head1 PUBLIC INTERFACE

purl, earthquake

=head1 DESCRIPTION

This module displays the most recent earthquake that the USGS knows about.  
I'm not sure what the criteria is for an earthquake being on this 
list but it seems to know about the biggies that hit Japan at any rate.

=head1 AUTHOR

Drew Hamilton <awh@awh.org>

=cut

#------------------------------------------------------------------------
# Startup
#
# Check that LWP is available, so we don't waste our time
# generating error messages later on.
#------------------------------------------------------------------------
my ($no_earthquake, $no_posix);

my $earthquake_url = 'http://neic.usgs.gov/neis/bulletin/bulletin_list.html';

BEGIN {
    eval qq{
        use LWP::Simple qw();
        use HTTP::Request::Common;
    };
    $no_earthquake++ if ($@);

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
# flighttrack_get
#
# This handles the forking (or not) stuff.
#------------------------------------------------------------------------
sub earthquake_get($)
{
    if($no_earthquake)
    {
        &main::status("Sorry, earthquake.pm requires LWP, and XML::Simple couldn't find it.");
        return "";
    }

    my($callback)=@_;
    $SIG{CHLD}="IGNORE";
    my $pid=eval { fork(); };         # Don't worry if OS isn't forking
    return 'NOREPLY' if $pid;
    $callback->(&earthquake_getdata());
    if (defined($pid))                # child exits, non-forking OS returns
    {
        exit 0 if ($no_posix);
        POSIX::_exit(0);
    }
}


#------------------------------------------------------------------------
# Prepare the query, send it to Flytecomm, and then hand the result off
# to parse_flightdata().
#------------------------------------------------------------------------
sub earthquake_getdata()
{
    my $quakedata;

    $quakedata = LWP::Simple::get($earthquake_url);
    &parse_quakedata($quakedata);
}

#------------------------------------------------------------------------
# Takes a time like "04:37 PM" and returns "16:37"
#------------------------------------------------------------------------
sub to_24_hour($)
{
    my $time = shift;
    my ($hour, $minute, $ampm) = ($time =~ /([0-9][0-9]):([0-9][0-9]) ([AP]M)/);

    $hour = "00" if ($ampm =~ /AM/ and $hour == 12);
    $hour += 12 if ($ampm =~ /PM/ and $hour != 12);

    "$hour:$minute"
}


#------------------------------------------------------------------------
# Given the text of the HTML page that Flytecomm returns, parse out the
# flight information and return a one-line status report for the flight
#------------------------------------------------------------------------
sub parse_quakedata
{
    my ($quakedata) = @_;

    $quakedata =~ s/.*<td headers=\"t7\">&nbsp;<\/td>//gis;

    my @rows = snag_element("TR", $quakedata);

    my $firstrow = shift(@rows);

    my ($tm, $lat, $long, $depth, $mag, $loc) = snag_element("TD", $firstrow);

    # time and location live inside A tags
    ($tm) = snag_element("A", $tm);
    ($loc) = snag_element("A", $loc);

    # time has nbsps in it
    $tm =~ s/&nbsp;&nbsp;/ /;

    # lat, long, depth, and mag live inside FONT tags
    ($lat) = snag_element("FONT", $lat);
    ($long) = snag_element("FONT", $long);
    ($depth) = snag_element("FONT", $depth);
    ($mag) = snag_element("FONT", $mag);

    return ($tm . "UTC.  $lat, $long ($loc).  Magnitude $mag, Depth $depth km.");
}


#------------------------------------------------------------------------
# This is the main interface to infobot
#------------------------------------------------------------------------

sub scan(&$$) {
    my ($callback, $message, $who)=@_;

    if ( ::getparam('earthquake') and $message =~ /^\s*earthquake/i ) {
        &main::status("Earthquake query");
        &earthquake_get($callback);
        return 1;
    }
}

return "earthquake";
