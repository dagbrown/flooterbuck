#------------------------------------------------------------------------
# slnk url-shortener
#
# Richard Harman
#
# $Id: slnk.pm,v 1.1 2004/09/17 02:10:33 rharman Exp $
#------------------------------------------------------------------------
package slnk;
use strict;

=head1 NAME

slnk.pm - generate a slnk (short link) from a big long url

=head1 PREREQUISITES

LWP::UserAgent

=head1 PUBLIC INTERFACE

sigsegv, slnk <url>
sigsegv, prefix.slnk <url>

=head1 DESCRIPTION

This allows you to generate a short link on slnk.org from a long unweildy url.

=head1 INFOBOT CONFIG OPTIONS

=over 8 

=item slnk [true|yes|1]

Turns the slnk module on and off.  Defaults to off.  Valid "on" options are "true", "yes", and 1.  Anything else turns it off.

=back

=over 8

=item slnk_prefix [prefix]

Sets the bot-wide default prefix for short links generated on slnk.org.  Don't use the option if you don't want a bot-wide prefix.

=over 8

=head1 AUTHOR

Richard Harman <flooterbuck+slnk@richardharman.com>

=cut

# Check to see if LWP::UserAgent is available, and if it isn't report back to the
# bot log, and the channel/msg any problems.
my ( $no_slnk, $no_posix );
my $user_agent;
my @unavailable_modules;

BEGIN {
        eval "use LWP::UserAgent;";
        if ($@) { $no_slnk++; push @unavailable_modules,"LWP::UserAgent"};
        eval "use POSIX";
        if ($@) { $no_posix++};
        if ( !$no_slnk ) { $user_agent = LWP::UserAgent->new( agent => $::version, timeout => 15 ) }

        # disable if slnk isn't enabled via param
        $no_slnk++ if ($::param{'slnk'} !~ m/true|y(?:es)?|1/i);
}

sub slnk_create(@) {
  my %request_ref = @_;
  my ($callback,$who) = ($request_ref{callback},$request_ref{who});

  my $prefix = $request_ref{prefix} || $::param{"slnk_prefix"};
  my $response = $user_agent->post( 'http://slnk.org/interface/simplebot/interface', {url => $request_ref{url}, prefix => $prefix , automated => "no" });

  if ( $response->is_success ) {
    my $content = $response->content();
    my %response_data;
    foreach ( split( /\n/, $content ) ) {
      my ( $key, $value ) = split( /:/, $_, 2 );
      $response_data{$key} = $value
        if ( defined($key) && defined($value) );
    }
    if ( $response_data{STATUS} eq "OK" ) {
      # short-link generation was ok.
      # check if we were going short url -> long url
      if ( defined( $response_data{LONG_URL} ) )
      { $callback->(sprintf( "$who, that short link points to %s", $response_data{LONG_URL} )); }
      elsif ( $response_data{SHORT_URL} )
      { $callback->(sprintf( "$who, your short link is %s",        $response_data{SHORT_URL} )); }
      else { $callback->("Sorry $who, slnk.org returned something I didn't understand.  You may want to email slnk\@richardharman.com to help get this fixed.") }
    } elsif ( $response_data{STATUS} eq "BAD" ) {
      # defined error supplied by the website
      $callback->($response_data{MESSAGE});
    } else {
      # undefined error
      $callback->("$who, It looks like slnk.org is having problems, as it returned an undefined error while generating a shortlink for that url.  Please email slnk\@richardharman.com for support.");
    }
  } else {
    $callback->("Sorry $who, I had problems trying to talk to slnk.org, the web request wasn't a success.  Try again later?");
  }
}

# subroutine called by the fork handler
sub slnk_getdata(@) {
  my ($callback,$line,$who) = @_;

  if ( $line =~ /(?:(\w+)\.)?(?:slnk|xev|fcol)\s+(that(,?\s+please)?|please)?\s*$/ ) {
    return slnk_create( url => &::lastURL( &::channel() ), prefix => $1, callback => $callback, who => $who );
  } elsif ( $line =~ /(?:(\w+)\.)?(?:slnk|xev|fcol)\s+(.+)/i ) {
    return slnk_create( url => $2, prefix => $1 , callback => $callback, who => $who);
  }
}

# fork, or no fork handling
sub slnk::get {
  my ( $callback, $line, $who ) = @_;
  if (scalar @unavailable_modules) {
    my $message = sprintf( "Sorry $who, slnk.pm requires the following module(s) that were not found: %s", join( ", ", @unavailable_modules ) );
    &main::status($message);
    $callback->($message);
    return "";
  }

  # we might have all the necessary modules, and be disabled.
  return undef if ($no_slnk);

  $SIG{CHLD} = "IGNORE";
  my $pid = eval { fork(); };    # Don't worry if OS isn't forking
  return 'NOREPLY' if $pid;
  &slnk_getdata($callback,$line,$who);
  if ( defined($pid) )           # child exits, non-forking OS returns
  {
    exit 0 if ($no_posix);
    POSIX::_exit(0);
  }
}

#------------------------------------------------------------------------
# This is the main interface to infobot
#------------------------------------------------------------------------

sub scan(&$$) {
  my ( $callback, $message, $who ) = @_;

  if ( $message =~ /^\s*(?:\w+\.)?(?:slnk|fcol|xev)\s+(\w+:\S+)\??/i ) {
    &main::status("slnk small-URL creation");
    slnk::get( $callback, $message, $who );
    return 1;
  }
  if ( $message =~ /\s*(\w+\.)?(?:slnk|fcol|xev)\s+(?:that|please)/i ) {
    &main::status("auto-slnk last-url creation");
    slnk::get( $callback, $message, $who );
    return 1;
  }
}

sub help {
    return "If you ask me slnk http://really-long-url/, I will shorten it for you on slnk.org.  If you ask me to shorten an already shortened url on slnk.org, I'll tell you the long url.  If you want to use a prefix, you can ask me myprefix.slnk http://url/.";
}

"slnk";
