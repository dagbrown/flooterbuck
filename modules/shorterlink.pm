#------------------------------------------------------------------------
# eBay auction status request
#
# Dave Brown
#
# $Id: shorterlink.pm,v 1.1 2002/08/01 23:42:06 dagbrown Exp $
#------------------------------------------------------------------------
package shorterlink;
use strict;


=head1 NAME

shorterlink.pm - generate a shorterlink from a big long one

=head1 PREREQUISITES

LWP::Simple

=head1 PARAMETERS

UTL

=head1 PUBLIC INTERFACE

sigsegv, shorterlink <url>

=head1 DESCRIPTION

This allows you to generate a "shorterlink" from a great big long one.

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
my ($no_shorterlink, $no_posix);

BEGIN {
    eval qq{
        use LWP::Simple qw();
    };
    $no_shorterlink++ if ($@);

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
# shorterlink_create
#
# Given a long URL, return the shorterlink version.
#------------------------------------------------------------------------
sub shorterlink_create($) {
    my $longurl=shift;

    my $response=LWP::Simple::get(
        'http://www.makeashorterlink.com/index.php?url='
        .$longurl);

    my (@elements)=snag_element("a",$response);
    my ($shorterlink)=grep { /http\:\/\/makeashorterlink\.com\/\?/ } @elements;
    
    # my ($longurl,$shorterlink)=snag_element("blockquote",$response);

    return "Your shorter link is $shorterlink";
}

#------------------------------------------------------------------------
# shorterlink_getdata
#
# Tear apart the line fed to the infobot, check its syntax,
# and feed the URL into shorterlink_create.
#------------------------------------------------------------------------
sub shorterlink_getdata($) {
    my $line=shift;

    if($line =~ /shorterlink\s+(\w+:\S+)/i) {
        return shorterlink_create($1);
    }
}

#------------------------------------------------------------------------
# shorterlink::get
#
# This handles the forking (or not) stuff.
#------------------------------------------------------------------------
sub shorterlink::get($$) {
    if($no_shorterlink) {
        &main::status("Sorry, shorterlink.pm requires LWP and couldn't find it");
        return "";
    }

    my($line,$callback)=@_;
    $SIG{CHLD}="IGNORE";
    my $pid=eval { fork(); };         # Don't worry if OS isn't forking
    return 'NOREPLY' if $pid;
    $callback->(&shorterlink_getdata($line));
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

    if ( ::getparam('shorterlink') and $message =~ /^\s*shorterlink\s+(\w+:\S+)/i ) {
        &main::status("ShorterLink Creation");
        &shorterlink::get($message,$callback);
        return 1;
    }
}

"shorterlink";
