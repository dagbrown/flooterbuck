# Template infobot extension

use strict;
package help;

BEGIN {
	# eval your "use"ed modules here
}

sub scan(&$$) {
    my ($callback,$message,$who) = @_;

    # Check $message, if it's what you want, then do stuff with it
    if($message =~ /^\s*help\s+(\w+)/) {
        my $mod=$1;
        my $reply="NULL";
        ::status("Module $mod");
        ::status(join(" ; ",Extras::modules()));
        if(grep { /$mod/ } Extras::modules()) {
            &::status("Eval'ing $mod\:\:help()");
            $reply=$who.": ".eval "$mod\:\:help()";
            if($@) {
                $reply="$who: No help is available for $mod";
                my $randnum=rand;
                if($randnum<0.2) {
                    $reply .= ", unfortunately.";
                } elsif($randnum<0.4) {
                    $reply .= ", I'm afraid.";
                } elsif($randnum<0.6) {
                    $reply .= ".  Sorry.";
                } elsif($randnum<0.8) {
                    $reply .= " (I tried).";
                } else {
                    $reply .= ", so you'll have to figure it out yourself.";
                }
            }
        }
        $callback->($reply);
        return 1;
    }

    return undef;
}

sub help {
    return "If you say help <modulename>, it will explain what the module does, and briefly tell you how to use it.";
}

"help";

__END__

=head1 NAME

help.pm - Help for other modules

=head1 PARAMETERS

help [module]

=head1 PUBLIC INTERFACE

    <dagbrown> purl, help help
    <purl> If you say help <modulename>, it will explain what the module does,
           and briefly tell you how to use it.

=head1 DESCRIPTION

This module provides a user interface to brief help for other modules.
If you're a module author, simply provide a function "help" in your module,
which returns a string containing the help text.

=head1 AUTHORS

Dave Brown <flooterbuck@dagbrown.com>
