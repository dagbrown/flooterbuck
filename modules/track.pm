#------------------------------------------------------------------------
# tracking report
#
# Richard Harman
#
# $Id: track.pm,v 1.4 2002/02/04 17:52:24 awh Exp $
#------------------------------------------------------------------------
package track;
use strict;
use CGI qw(escape);

=head1 NAME

track.pm - UPS, FedEX, Airborne, and Posten AB tracking, brought to you by www.pakalert.com

=head1 PREREQUISITES

LWP::UserAgent
XML::Simple
 (and, XML::Parser, and Expat)

=head1 PARAMETERS

track

=head1 PUBLIC INTERFACE

purl, track <Tracking ID>

=head1 DESCRIPTION

This module allows you to fetch tracking information provided by www.pakalert.com.  Since this module uses their XML interface, any shipping agents pakalert adds to their system should automatically work in this module.

=head1 AUTHOR

Richard G Harman Jr <flooterbuck+track.pm@richardharman.com>

=cut

#------------------------------------------------------------------------
# Startup
#
# Check that LWP is available, so we don't waste our time
# generating error messages later on.
#------------------------------------------------------------------------
my ($no_track, $no_posix);

my $pakalert_url = 'http://www.pakalert.com/trackpack.asp?';
my $pakalert_username = 'CHANGE ME';
my $pakalert_password = 'CHANGE ME';

BEGIN {
    eval qq{
        use LWP::Simple qw();
	use XML::Simple qw();
    };
    $no_track++ if ($@);

    eval qq{
        use POSIX;
    };
    $no_posix++ if ($@);
}

#------------------------------------------------------------------------
# track::get
#
# This handles the forking (or not) stuff.
#------------------------------------------------------------------------
sub track_get($$)
{
    if($no_track)
    {
        &main::status("Sorry, track.pm requires LWP, and XML::Simple couldn't find it or you need to pick a valid pakalert.com username/password.");
        return "";
    }

    my($line,$callback)=@_;
    $SIG{CHLD}="IGNORE";
    my $pid=eval { fork(); };         # Don't worry if OS isn't forking
    return 'NOREPLY' if $pid;
    $callback->(&track_getdata($line));
    if (defined($pid))                # child exits, non-forking OS returns
    {
        exit 0 if ($no_posix);
        POSIX::_exit(0);
    }
}

sub track_getdata($)
{
  my $track_id=shift;
  my $url = join("",$pakalert_url,"trackno=",escape($track_id),'&login=',escape($pakalert_username),"&password=",escape($pakalert_password));
  my $xs = new XML::Simple();
  my $XML = LWP::Simple::get($url);
  my $ref = $xs->XMLin($XML);
  my $hashref = \$ref->{trackinfo}->{objalertinformation}->{colltrackinginformation}->{colltrackinginformation_Item}[0];
  my $string = $$$hashref{dtimeofaction};
  $string =~ s/T/ /; # they separate date/time with a T.
  $string .= ": $$$hashref{taction} $$$hashref{tlocationcity}, $$$hashref{tlocationstate}";
  return $string;
}


#------------------------------------------------------------------------
# This is the main interface to infobot
#------------------------------------------------------------------------

sub scan(&$$) {
    my ($callback, $message, $who)=@_;

    if ( ::getparam('track') and $message =~ /^\s*track\s+(.+)$/i ) {
        &main::status("Pakalert (track) query");
        &track_get($1,$callback);
        return 1;
    }
}

return "track";
