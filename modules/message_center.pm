#------------------------------------------------------------------------
# Message center module
#
# See the POD for more information
#
# $Id: message_center.pm,v 1.3 2003/04/25 02:22:28 dagbrown Exp $
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

BEGIN {
    $message_center=1;  # used by User.pl to see if it should run have_message
}

sub leave_message {
    my ($from, $to, $msg)=@_;

    unless( &::get(seen=>$to) ) {
        return "Sorry, I've never seen $to before.";
    }

    my $msgs=::get(messages => $to);
    if (length($msgs)==0) {
        $new_message="0\0";   # "knows about messages" flag
    } else {
        $new_message=$msgs;
        substr($new_message,0,1)='0';
    }

    $new_message="$from [".scalar localtime()."] said: $msg\0";
    ::set("messages",$to,$new_message);
    return "Message for $to logged.";
}

sub have_message {
    my $who=shift;

    my $msgs=::get(messages => $who);
    return 0 unless defined $msgs;

    my @msgs=split "\0",$msgs;
    my $knows=shift @msgs;

    return 0 if $knows==1;
    
    ::msg($who,"You have ".scalar @msgs." messages waiting.");
    substr($msgs,0,1)=1;
    ::set("messages",$who,$msgs);
}

sub message_erase {
    my $who=shift;
    ::forget(messages => $who);
    return "Messages erased";
}

sub message_read {
    my $who=shift;

    my $msgs=::get(messages => $who);
    if($msgs) {
        my @msgs=split "\0",$msgs;
        shift @msgs;
        ::msg($who,"You received the following messages:");

        foreach my $msg (@msgs) {
            ::msg($who,$msg);
        }
        return "";
    } else {
        return "You have no messages waiting."
    }
}

sub scan(&$$) {
    my ($callback,$message,$who) = @_;

    # Check $message, if it's what you want, then do stuff with it
    if($message =~ /^(?:message|msg)\s+help$/i) {
        $callback->("To leave a message, say \"msg <nickname> message\" to me.  To read your messages, msg me with \"messages\".  To erase your messages, msg me with \"messages erase\"");
        return 1;
    } elsif($message =~ /^(?:message|msg)(?:\s+for)?\s+
                    (\S+)                # recipient
                    (?:\s*(?:\:|;))?\s*  # Optional colon and space
                    (.+?)                # text of the message
                    $/xi &&
       $message !~ /^(?:message|msg)\s+from/i
    ) {
        my $reply=leave_message($who,lc($1),$2);
        $callback->($reply);
        return 1;
    } elsif($message =~ /^(?:messages|msgs)\s*(?:forget|erase)/i 
            && $::msgType =~ /private/) {
        $callback->(message_erase(lc($who)));
        return 1;
    } elsif($message =~ /^(?:messages|msgs)\s*$/i) {
        $callback->(message_read(lc($who)));
        return 1;
    }
    return undef;
}

return "message_center";
