# $Id: bash.pm,v 1.4 2003/01/23 01:37:59 dagbrown Exp $
package bash;
use strict;

=head1 NAME

bash.pl - foo

=head1 PREREQUISITES

LWP::UserAgent

=head1 PARAMETERS

bash

=head1 PUBLIC INTERFACE

purl, playback <bash.org quote id>

=head1 DESCRIPTION

foo

=head1 AUTHOR

Richard Harman <flooterbuck+bash.pm@richardharman.com>

=cut

#------------------------------------------------------------------------
# Startup
#
# Check that LWP is available, so we don't waste our time
# generating error messages later on.
#------------------------------------------------------------------------
my ( $no_bash, $no_posix );

BEGIN {
    eval qq{
        use LWP::Simple qw();
    };
    $no_bash++ if ($@);

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
    my $blob = shift;
    chomp $blob;
    $blob =~ s/\<[^>]+\>//g;
    $blob =~ s/\&[a-z]+\;?//g;
    $blob =~ s/\s+/ /g;
    return $blob;
}

#------------------------------------------------------------------------
# bash_getdata
#
# Tear apart the line fed to the infobot, check its syntax,
# and feed the auction ID number into the maw of auction_summary.
#------------------------------------------------------------------------
sub bash_getdata($) {
    my $line = shift;

    if ( $line =~ /bash\s+(\d+)/i && ( $1 gt 0 ) ) {
        return &get_quote($1);
    }
}

sub bash::get_quote ($) {
    my $quote_number = shift;
    my $bash         = LWP::Simple::get( 'http://bash.org/?' . $quote_number );
    my ($quote) = ( $bash =~ m/<p class="qt">(.+)<\/p>/sgi );
    $quote =~ s/<br \/>//g;
    $quote = HTML::Entities::decode($quote);
    $quote =~ s/\r//g;
    return split ( "\n", $quote );
}

#------------------------------------------------------------------------
# bash::get
#
# This handles the forking (or not) stuff.
#------------------------------------------------------------------------
sub bash::get($$) {
    if ($no_bash) {
        &main::status("Sorry, bash.pm requires LWP and couldn't find it");
        return "";
    }

    my ( $line, $callback ) = @_;
    $SIG{CHLD} = "IGNORE";
    my $pid = eval { fork(); };    # Don't worry if OS isn't forking
    return 'NOREPLY' if $pid;
    my @lines = &bash_getdata($line);
    if ( !scalar @lines ) {
        $callback->(
"Either that quote id does't exist, or bash.org is busted at the moment."
        );
    }
    else {
        foreach (@lines) {
            $callback->($_);
            sleep 1;
        }
    }
    if ( defined($pid) )    # child exits, non-forking OS returns
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

    if ( ::getparam('bash') and $message =~ /^\s*bash\s+(\d+)$/i ) {
        &main::status("bash playback");
        &bash::get( $message, $callback );
        return 1;
    }
}

"bash";
