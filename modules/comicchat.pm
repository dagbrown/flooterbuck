# Template infobot extension

use strict;

package comicchat;

sub scan(&$$) {
    my ( $callback, $message, $who ) = @_;

    # Check $message, if it's what you want, then do stuff with it
    if ( ::getparam('comicchat') && $message =~ /^comicchat/ ) {
        $callback->(
"# Appears as FLOOTERBUCK.http://village.infoweb.ne.jp/~iorin/aya_lollipop_cat.avb"
        );
        return 1;
    }

    if ( $message =~ /^\# Appears as/ ) {
        $callback->(
"# Appears as FLOOTERBUCK.http://village.infoweb.ne.jp/~iorin/aya_lollipop_cat.avb"
        );
        return 1;
    }

    return undef;
}

return "comicchat";

__END__

=head1 NAME

comicchat.pm

=head1 DESCRIPTION

Announces a comic chat character to other members in a comic chat channel.

=head1 PREREQUISITES

The URL to the character that you wish to use.  Replace it above in
the obvious places.

=head1 AUTHORS

Drew Hamilton <awh@awh.org>
