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
my ( $no_flighttracker, $no_posix );

my $flytecomm_random_url =
  'http://www.flytecomm.com/cgi-bin/trackflight?action=select_random';
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
    my $element     = shift;
    my $blob_o_html = shift;

    return (
        $blob_o_html =~ /\<$element[^>]*\>(.*?)\<\/$element\>/gis );
}

#------------------------------------------------------------------------
# flighttrack_get
#
# This handles the forking (or not) stuff.
#------------------------------------------------------------------------
sub flighttrack_get($$) {
    if ($no_flighttracker) {
        &main::status(
"Sorry, flighttracker.pm requires LWP, and XML::Simple couldn't find it."
        );
        return "";
    }

    my ( $line, $callback ) = @_;
    $SIG{CHLD} = "IGNORE";
    my $pid = eval { fork(); };    # Don't worry if OS isn't forking
    return 'NOREPLY' if $pid;
    $callback->( &flighttrack_getdata($line) );
    if ( defined($pid) )           # child exits, non-forking OS returns
    {
        exit 0 if ($no_posix);
        POSIX::_exit(0);
    }
}

#------------------------------------------------------------------------
# Prepare the query, send it to Flytecomm, and then hand the result off
# to parse_flightdata().
#------------------------------------------------------------------------
sub flighttrack_getdata($) {
    my $flightdata;
    my $flighttrack_id = shift;

    if ( $flighttrack_id =~ /random/i ) {
        $flightdata = LWP::Simple::get($flytecomm_random_url);
    } else {
        $flighttrack_id =~ s/^flighttracker\s+//;
        my $ua  = new LWP::UserAgent;
        my $res = $ua->request(
            POST $flytecomm_url,
            [
                flight_id => $flighttrack_id,
                action    => "select_advanced"
            ]
        );
        if ( !( $res->is_success ) ) {
            return "Can't get flight info for $flighttrack_id";
        }
        $flightdata = $res->as_string;
    }
    &parse_flightdata( $flighttrack_id, $flightdata );
}

#------------------------------------------------------------------------
# Takes a time like "04:37 PM" and returns "16:37"
#------------------------------------------------------------------------
sub to_24_hour($) {
    my $time = shift;
    my ( $hour, $minute, $ampm ) =
      ( $time =~ /([0-9][0-9]):([0-9][0-9]) ([AP]M)/ );

    $hour = "00" if ( $ampm =~ /AM/ and $hour == 12 );
    $hour += 12 if ( $ampm =~ /PM/ and $hour != 12 );

    "$hour:$minute";
}

#------------------------------------------------------------------------
# Given the text of the HTML page that Flytecomm returns, parse out the
# flight information and return a one-line status report for the flight
#------------------------------------------------------------------------
sub parse_flightdata {
    my ( $flighttrack_id, $flightdata ) = @_;
    my %flightdata;

    # make sure that this page contains flight information.
    return "Flight \"$flighttrack_id\" was not found."
      if ( $flightdata =~ /Flight Not Found in Database/ );

    # populate the hash with empty lists
    foreach my $key (
        qw/depcity deptime arrcity arrtime remtime
        alt gs status/
      )
    {
        $flightdata{$key} = [];
    }

    # get the flight identifier.  The only place it's shown is as the
    # default value for one of the form inputs.
    my ($flight_id) =
      ( $flightdata =~ /NAME=\"flight_id\" VALUE=\"([A-Z0-9]*)\"/ );

    # loop through each Table Row on the page.  For each of the Elements
    # Of A Flight, push the element onto the end of a list.  Then we'll
    # collate all this at the end.
    my (@rows) = snag_element( "tr", $flightdata );

    my $flightnum = 0;
    foreach (@rows) {
        my @cols = snag_element( "td", $_ );

        push @{ $flightdata{depcity} },
          ( ( $cols[1] =~ /.*\(([A-Z0-9]*)\).*/ )[0] )
          if ( $cols[0] =~ /Departure City/ );

        push @{ $flightdata{deptime} },
          to_24_hour(
            ( $cols[1] =~ /.*([0-9][0-9]:[0-9][0-9] [AP]M).*/ )[0] )
          if ( $cols[0] =~ /Departure Time/ );

        push @{ $flightdata{arrcity} },
          ( ( $cols[1] =~ /.*\(([A-Z0-9]*)\).*/ )[0] )
          if ( $cols[0] =~ /Arrival City/ );

        push @{ $flightdata{arrtime} },
          to_24_hour(
            ( $cols[1] =~ /.*([0-9][0-9]:[0-9][0-9] [AP]M).*/ )[0] )
          if ( $cols[0] =~ /Arrival Time/ );

        push @{ $flightdata{remtime} },
          ( snag_element( "font", $cols[1] ) )[0]
          if ( $cols[0] =~ /Remaining/ );

        push @{ $flightdata{alt} },
          ( snag_element( "font", $cols[1] ) )[0]
          if ( $cols[0] =~ /Altitude/ );

        push @{ $flightdata{gs} },
          ( snag_element( "font", $cols[1] ) )[0]
          if ( $cols[0] =~ /Groundspeed/ );

        push @{ $flightdata{status} },
          ( snag_element( "font", $cols[1] ) )[0]
          if ( $cols[0] =~ /Status/ );
    }

    # return the abbreviated flight information
    for my $flightsnum ( 0 .. $#{ $flightdata{status} } ) {
        if ( $flightdata{status}->[$flightsnum] =~
            /Landed|Arrived|Planned/ )
        {
            $flightdata{summary}->[$flightsnum] =
                $flight_id . " "
              . $flightdata{depcity}->[$flightsnum] . "["
              . $flightdata{deptime}->[$flightsnum] . "]->"
              . $flightdata{arrcity}->[$flightsnum] . "["
              . $flightdata{arrtime}->[$flightsnum] . "] ("
              . $flightdata{status}->[$flightsnum] . ")";
        } else {
            $flightdata{summary}->[$flightsnum] =
                $flight_id . " "
              . $flightdata{depcity}->[$flightsnum] . "["
              . $flightdata{deptime}->[$flightsnum] . "]->"
              . $flightdata{arrcity}->[$flightsnum] . "["
              . $flightdata{arrtime}->[$flightsnum] . "] ("
              . $flightdata{status}->[$flightsnum] . ") "
              . $flightdata{alt}->[$flightsnum] . ", "
              . $flightdata{gs}->[$flightsnum] . ", "
              . $flightdata{remtime}->[$flightsnum]
              . " remaining";
        }
        main::status(
            "flight data: " . $flightdata{summary}->[$flightsnum] );
    }
    return join( "; ", @{ $flightdata{summary} } );
}

#------------------------------------------------------------------------
# This is the main interface to infobot
#------------------------------------------------------------------------

sub scan(&$$) {
    my ( $callback, $message, $who ) = @_;

    if ( ::getparam('flighttracker')
        and $message =~ /^\s*flighttracker\s+/i )
    {
        &main::status("Flight Tracker query");
        &flighttrack_get( $message, $callback );
        return 1;
    }
}

return "flighttracker";
