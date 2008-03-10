#------------------------------------------------------------------------
# daily horoscopes
#
# Richard Harman
#
# $Id: horoscope.pm,v 1.3 2004/08/14 04:40:34 dagbrown Exp $
#------------------------------------------------------------------------
package horoscope;
use strict;

=head1 NAME

horoscope.pm - horoscopes, horoscopes, get 'em right here!

=head1 PREREQUISITES

LWP::UserAgent

=head1 PARAMETERS

horoscope

=head1 PUBLIC INTERFACE

purl, horoscope for gemini
purl, gemini horoscope

=head1 DESCRIPTION

This module fetches the daily horoscope for you from http://horoscopes.astrology.com/dailyFOO.html and returns today's horoscope.

=head1 AUTHOR

Richard G Harman Jr <flooterbuck+horoscope.pm@richardharman.com>

=cut

#------------------------------------------------------------------------
# Startup
#
# Check that LWP is available, so we don't waste our time
# generating error messages later on.
#------------------------------------------------------------------------
my ($no_horoscope, $no_posix);

my $horoscope_url = 'http://horoscopes.astrology.com/daily';

BEGIN {
    eval qq{
        use LWP::Simple qw();
    };
    $no_horoscope++ if ($@);

    eval qq{
        use POSIX;
    };
    $no_posix++ if ($@);
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
# horoscope::get
#
# This handles the forking (or not) stuff.
#------------------------------------------------------------------------
sub horoscope_get($$)
{
    if($no_horoscope)
    {
        &main::status("Sorry, horoscope.pm requires LWP and can't find it.");
        return "";
    }
    my($line,$callback)=@_;
    $SIG{CHLD}="IGNORE";
    my $pid=eval { fork(); };         # Don't worry if OS isn't forking
    return 'NOREPLY' if $pid;
    $callback->(&horoscope_getdata($line));
    if (defined($pid))                # child exits, non-forking OS returns
    {
        exit 0 if ($no_posix);
        POSIX::_exit(0);
    }
}

sub horoscope_getdata($)
{
  my @signs = qw(aries taurus gemini cancer leo virgo libra scorpio sagittarius capricorn aquarius pisces);
  my $horoscope_sign=shift;
  my ($sign_good,$horoscope);

  foreach (@signs)
  {
    if ($_ =~ /$horoscope_sign/i)
    {
      $sign_good = $_;
    }
  }
  if ($sign_good)
  {
    my $url = $horoscope_url.$sign_good.".html";
    my $string = LWP::Simple::get($url);
   
    ($horoscope) = ($string =~ m|.+<daily_horoscope>(.+)</daily_horoscope>.+|sgi);
    $horoscope = &strip_html($horoscope);
    $horoscope =~ s/^\s+//sgi;
    $horoscope =~ s/\s+^//sgi;
  }

  $horoscope =~ s/\s+Send this page to a friend.\s*$//;
  return $horoscope;
}


#------------------------------------------------------------------------
# This is the main interface to infobot
#------------------------------------------------------------------------

sub scan(&$$) {
    my ($callback, $message, $who)=@_;
    # don't complain dagbrown.
    if 
        (
         ($message =~ /(?:daily )?horoscope(?: for)? (.+)\\?/)
         or 
         ($message =~ /(.+)\s+horoscope\??/)
        )
    {
        &main::status("horoscope query");
        &horoscope_get($1,$callback);
        return 1;
    }
}

return "horoscope";
