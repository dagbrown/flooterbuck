#------------------------------------------------------------------------
# Flight Tracker
#
# Drew Hamilton
#
#------------------------------------------------------------------------
package flighttracker;
use strict;

=head1 NAME

flighttracker.pm - Flight tracking from the good people at flytecomm.

=head1 PREREQUISITES

LWP::UserAgent

=head1 PARAMETERS

flighttracker

=head1 PUBLIC INTERFACE

purl, flighttracker SWA2012

purl, flighttracker random

=head1 DESCRIPTION

This module uses flytecomm's real-time flight tracker to provide the status of any flight arriving or departing in North America

=head1 AUTHOR

Drew Hamilton <awh@awh.org>

=cut

#------------------------------------------------------------------------
# Startup
#
# Check that LWP is available, so we don't waste our time
# generating error messages later on.
#------------------------------------------------------------------------
my ($no_flighttracker, $no_posix);

my $flytecomm_random_url = 'http://www.flytecomm.com/cgi-bin/trackflight?action=select_random';
my $flytecomm_url = 'http://www.flytecomm.com/cgi-bin/trackflight';

BEGIN {
    eval qq{
        use LWP::Simple qw();
        use HTTP::Request::Common;
    };
    $no_flighttracker++ if ($@);

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
sub flighttrack_get($$)
{
    if($no_flighttracker)
    {
        &main::status("Sorry, flighttracker.pm requires LWP, and XML::Simple couldn't find it.");
        return "";
    }

    my($line,$callback)=@_;
    $SIG{CHLD}="IGNORE";
    my $pid=eval { fork(); };         # Don't worry if OS isn't forking
    return 'NOREPLY' if $pid;
    $callback->(&flighttrack_getdata($line));
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
sub flighttrack_getdata($)
{
    my $flightdata;
    my $flighttrack_id=shift;

    if ($flighttrack_id =~ /random/i) {
        $flightdata = LWP::Simple::get($flytecomm_random_url);
    } else {
        $flighttrack_id =~ s/^flighttracker\s+//;
        my $ua = new LWP::UserAgent;
        my $res = $ua->request(POST $flytecomm_url,
            [    flight_id => $flighttrack_id,
                 action => "select_advanced"
            ]);
        if (!($res->is_success)) {
            return "Can't get flight info";
        }
        $flightdata = $res->as_string;
    }
    &parse_flightdata($flightdata);
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
sub parse_flightdata($)
{
    my $flightdata = shift;
    my %flightdata;
    

    # make sure that this page contains flight information.
    return "That flight was not found." if ($flightdata =~ /The flight is not in the database!/);

    # get the flight identifier.  The only place it's shown is as the
    # default value for one of the form inputs.
    my ($flight_id) = ($flightdata =~ /NAME=\"flight_id\" VALUE=\"([A-Z0-9]*)\"/);

    # loop through each Table Row on the page.  Sometimes two legs of
    # a flight are shown on the same page.  The final leg will always
    # "win" in this situation.  Ideally, any currently "in flight" leg
    # should win, but I suck.
    my (@rows) = snag_element("tr", $flightdata);
    foreach (@rows)
    {
        my @cols = snag_element("td", $_);
        $flightdata{"depcity"} = $cols[1] if ($cols[0] =~ /Departure City/);
        $flightdata{"deptime"} = $cols[1] if ($cols[0] =~ /Departure Time/);
        $flightdata{"arrcity"} = $cols[1] if ($cols[0] =~ /Arrival City/);
        $flightdata{"arrtime"} = $cols[1] if ($cols[0] =~ /Arrival Time/);
        $flightdata{"remtime"} = $cols[1] if ($cols[0] =~ /Remaining/);
        $flightdata{"alt"} = $cols[1] if ($cols[0] =~ /Altitude/);
        $flightdata{"gs"} = $cols[1] if ($cols[0] =~ /Groundspeed/);
        $flightdata{"status"} = $cols[1] if ($cols[0] =~ /Status/);
    }

    # format all of the information we grabbed from the page.
    ($flightdata{"status"}) = snag_element("font", $flightdata{"status"});
    ($flightdata{"alt"}) = snag_element("font", $flightdata{"alt"});
    ($flightdata{"gs"}) = snag_element("font", $flightdata{"gs"});
    ($flightdata{"remtime"}) = snag_element("font", $flightdata{"remtime"});
    $flightdata{"depcity"} =~ s/.*\(([A-Z0-9]*)\).*/$1/;
    $flightdata{"arrcity"} =~ s/.*\(([A-Z0-9]*)\).*/$1/;
    $flightdata{"deptime"} =~ s/.*([0-9][0-9]:[0-9][0-9] [AP]M).*/$1/;
    $flightdata{"arrtime"} =~ s/.*([0-9][0-9]:[0-9][0-9] [AP]M).*/$1/;

    # convert 12-hour times to 24-hour.
    $flightdata{"arrtime"} = &to_24_hour($flightdata{"arrtime"});
    $flightdata{"deptime"} = &to_24_hour($flightdata{"deptime"});

    # return the abbreviated flight information
    if ($flightdata{"status"} =~ /Arrived|Planned/) {
        return $flight_id . " " . $flightdata{"depcity"} . "[" . $flightdata{"deptime"} . "]->" . $flightdata{"arrcity"} . "[" . $flightdata{"arrtime"} . "] (" . $flightdata{"status"} . ")";
    } else {
        return $flight_id . " " . $flightdata{"depcity"} . "[" . $flightdata{"deptime"} . "]->" . $flightdata{"arrcity"} . "[" . $flightdata{"arrtime"} . "] (" . $flightdata{"status"} . ") " . $flightdata{"alt"} . ", " . $flightdata{"gs"} . ", " . $flightdata{"remtime"} . " remaining";
    }
}


#------------------------------------------------------------------------
# This is the main interface to infobot
#------------------------------------------------------------------------

sub scan(&$$) {
    my ($callback, $message, $who)=@_;

    if ( ::getparam('flighttracker') and $message =~ /^\s*flighttracker\s+/i ) {
        &main::status("Flight Tracker query");
        &flighttrack_get($message,$callback);
        return 1;
    }
}

return "flighttracker";
