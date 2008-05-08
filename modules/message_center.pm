#------------------------------------------------------------------------
# Message center module
#
# See the POD for more information
#
# $Id: message_center.pm,v 1.10 2007/10/31 00:58:57 dagbrown Exp $
#------------------------------------------------------------------------

=head1 NAME

message_center.pm - A message center

=head1 SERVING SUGGESTION

=over 4

=item floot, msg dagbrown Hi, I have a message for you!

Leaves a message for dagbrown

=item /msg floot messages

Asks floot if you have any messages waiting

=item /msg floot messages erase

Asks floot to erase your messages

=back

=head1 DESCRIPTION

This is a message center for Infobot.

=head1 AUTHORS

Dave Brown (dagbrown@lart.ca) based loosely on code by, um,
authors unknown

=cut

use strict;

package message_center;

my $message_center;

END {
    ::closeDBM('message');
}

sub leave_message {
    my ( $from, $to, $msg ) = @_;
    $to =~ s/:$//
      ;    ### Remove when TODO below regarding colon greediness fixed

    unless ( &::get( seen => lc($to) ) ) {
        return "Sorry, I've never seen $to before.";
    }

    my $msgs = ::get( message => lc($to) );
    my $new_message;
    if ( length($msgs) == 0 ) {
        $msgs = "0";    # "knows about messages" flag
    } else {
        substr( $msgs, 0, 1 ) = '0';
    }

    $new_message =
      $msgs . "\0$from [" . scalar localtime() . "] said: $msg";
    ::set( "message", lc($to), $new_message );
    return "Message for $to stored.";
}

sub have_message {
    my $who = shift;

    my $msgs = ::get( message => lc($who) );
    return unless defined $msgs;

    my @msgs = split "\0", $msgs;
    my $knows = shift @msgs;

    return undef if $knows == 1;
    ::msg( $who,
            "You have "
          . scalar @msgs
          . " message"
          . ( scalar @msgs == 1 ? "" : "s" )
          . " (\"messages\" to read)." );
    substr( $msgs, 0, 1 ) = 1;
    ::set( "message", lc($who), $msgs );
    return;
}

sub message_erase {
    my $who = shift;
    ::forget( message => $who );
    return "Messages erased";
}

sub message_read {
    my $who = shift;

    my $msgs = ::get( message => lc($who) );
    if ($msgs) {
        my @msgs = split "\0", $msgs;
        shift @msgs;
        ::msg( $who, "You received the following messages:" );

        foreach my $msg (@msgs) {
            ::msg( $who, $msg );
        }
        ::clear( "message", $who );
        return "";
    } else {
        ::msg( $who, "You have no messages waiting." );
        return "";
    }
}

sub preprocess {
    my ( $channel, $message, $who ) = @_;

    have_message($who);
}

sub scan(&$$) {
    my ( $callback, $message, $who ) = @_;

    # Check $message, if it's what you want, then do stuff with it
    if ( $message =~ /^(?:message|msg)\s+help$/i ) {
        $callback->(
"To leave a message, say \"msg <nickname> message\" to me.  To read your messages, msg me with \"messages\".  To erase your messages, msg me with \"messages erase\""
        );
        return 1;
    } elsif (
        $message =~ /^(?:message|msg)(?:\s+for)?\s+
                    (\S+)                # recipient
                    (?:\s*(?:\:|;))?\s*  # Optional colon and space
                    (.+?)                # text of the message
                    $/xi && $message !~ /^(?:message|msg)\s+from/i
      )
    {
        my $reply = leave_message( $who, lc($1), $2 );
        $callback->($reply);
        return 1;
    } elsif ( $message =~ /^(?:messages|msgs)\s*(?:forget|erase)/i
        && $::msgType =~ /private/ )
    {
        $callback->( message_erase( lc($who) ) );
        return 1;
    } elsif ( $message =~ /^(?:messages|msgs)\s*$/i ) {
        $callback->( message_read( lc($who) ) );
        return 1;
    }
}

"message_center";
