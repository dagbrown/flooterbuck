#------------------------------------------------------------------------
# shorten url-shortener
#
# Dave Brown
# Paul Blair
#
# $Id: shorten.pm,v 1.1 2004/04/01 08:08:55 dagbrown Exp $
#------------------------------------------------------------------------
package shorten;
use strict;


=head1 NAME

shorten.pm - generate a shorten from a big long url

=head1 PREREQUISITES

LWP::Simple, URI::Escape, POSIX

=head1 PARAMETERS

UTL

=head1 PUBLIC INTERFACE

sigsegv, shorten <url>

=head1 DESCRIPTION

This allows you to generate a "shorten" from a great big long url.

=head1 AUTHOR

Dave Brown <dagbrown@csclub.uwaterloo.ca>

=cut

#------------------------------------------------------------------------
# Startup
#
# Check that LWP is available, so we don't waste our time
# generating error messages later on.
#------------------------------------------------------------------------
my $no_shorten;
my $no_posix;

BEGIN {
    foreach (qw(LWP::Simple URI::Escape)) {
        eval qq{
            use $_;
        };
        $no_shorten++ if ($@);
    }
    eval qq/use POSIX;/;
    $no_posix++ if ($@);
}

#------------------------------------------------------------------------
# shorten_create
#
# Given a long URL, return the shorten version.
#------------------------------------------------------------------------
sub shorten_create($) {
    my $longurl=shift;

    my $shorten=LWP::Simple::get('http://metamark.net/api/rest/simple?long_url='
        . uri_escape($longurl));
    chomp $shorten;

    unless ($shorten =~ /^ERROR:/) {
        (my $best_guess) = $longurl =~ m!^\w+://www[0-9]*\.([a-z0-9.-]+)/!;
        ($best_guess) = $longurl =~ m!^\w+://(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/! unless $best_guess;

        $shorten .= " [$best_guess]" if $best_guess;
        return "That URL is at $shorten";
    } else {
        if(rand>0.95) {
            return "That URL is at--oh, whoops, it said $shorten, sorry";
        } else {
            return $shorten;
        }
    }
}

#------------------------------------------------------------------------
# shorten_getdata
#
# Tear apart the line fed to the infobot, check its syntax,
# and feed the URL into shorten_create.
#------------------------------------------------------------------------
sub shorten_getdata($) {
    my $line=shift;

    if($line =~ /^shorten\s+(that(,?\s+please)?|please)?[!?.]?\s*$/) {
        return shorten_create(::lastURL(::channel()));
    } elsif ($line =~ /^shorten\s+(.+)/i) {
        return shorten_create($1);
    }
}

#------------------------------------------------------------------------
# shorten::get
#
# This handles the forking (or not) stuff.
#------------------------------------------------------------------------
sub shorten::get {
    if($no_shorten) {
        &main::status("Sorry, shorten.pm requires LWP and couldn't find it");
        return "";
    }

    my($line,$callback)=@_;
    $SIG{CHLD}="IGNORE";
    my $pid=eval { fork(); };         # Don't worry if OS isn't forking
    return 'NOREPLY' if $pid;
    $callback->(&shorten_getdata($line));
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


    if ( $message =~ /^\s*(?:shorten)\s+(\w+:\S+)\??/i ) {
        &main::status("shorten small-URL creation");
        shorten::get($message,$callback);
        return 1;
    }
    if ( $message =~ /\s*(?:shorten)\s+(?:that|please)/i) {
        &main::status("auto-shorten last-url creation");
        shorten::get($message,$callback);
    }
}

"shorten";
