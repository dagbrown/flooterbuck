#------------------------------------------------------------------------
# eBay auction status request
#
# Dave Brown
#
# $Id: fcol.pm,v 1.4 2002/08/02 22:25:40 dagbrown Exp $
#------------------------------------------------------------------------
package fcol;
use strict;


=head1 NAME

fcol.pm - generate a fcol from a big long one

=head1 PREREQUISITES

LWP::Simple

=head1 PARAMETERS

UTL

=head1 PUBLIC INTERFACE

sigsegv, fcol <url>

=head1 DESCRIPTION

This allows you to generate a "fcol" from a great big long one.

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
my ($no_fcol, $no_posix);

BEGIN {
    foreach my $lib qw(LWP::Simple URI::Escape POSIX) {
        eval qq{
            use $lib;
        };
        $no_fcol++ if ($@);
    }
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

sub snag_file($) {
    my $file=shift;
    open(FILE,"<$file");
    my @lines=<FILE>;
    close(FILE);
    return join("",@lines);
}

#------------------------------------------------------------------------
# fcol_create
#
# Given a long URL, return the fcol version.
#------------------------------------------------------------------------
sub fcol_create($) {
    my $longurl=shift;

    my $response=LWP::Simple::get(
        'http://fcol.org/add?life=7&url='
        .uri_escape($longurl));

    print STDERR $response,"\n";
    my ($fcol)=snag_element("a",$response);

    return "Your fcol is $fcol";
}

#------------------------------------------------------------------------
# fcol_getdata
#
# Tear apart the line fed to the infobot, check its syntax,
# and feed the URL into fcol_create.
#------------------------------------------------------------------------
sub fcol_getdata($) {
    my $line=shift;

    if($line =~ /fcol\s+(\w+:\S+)/i) {
        return fcol_create($1);
    }
}

#------------------------------------------------------------------------
# fcol::get
#
# This handles the forking (or not) stuff.
#------------------------------------------------------------------------
sub fcol::get($$) {
    if($no_fcol) {
        &main::status("Sorry, fcol.pm requires LWP and couldn't find it");
        return "";
    }

    my($line,$callback)=@_;
    $SIG{CHLD}="IGNORE";
    my $pid=eval { fork(); };         # Don't worry if OS isn't forking
    return 'NOREPLY' if $pid;
    $callback->(&fcol_getdata($line));
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

    if ( $message =~ /^\s*(?:fcol|tinyurl|shrivel)\s+(\w+:\S+)/i ) {
        &main::status("fcol small-URL creation");
        fcol::get($message,$callback);
        return 1;
    }
}

"fcol";
