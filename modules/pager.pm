# Pager
#
# $Id: pager.pm,v 1.1 2004/03/09 04:36:41 rich_lafferty Exp $

package pager;

BEGIN {
    eval qq{
        use Mail::Mailer qw(sendmail);
    };
    $no_mail++ if ($@);
}

sub scan(&$$) {
    my ($callback, $message, $who)=@_;

    if ($no_mail) {
        &::status("pager requires Mail::Mailer");
        return undef;
    }

    unless ($message =~ /^page\s+(\S+)\s+(.*)$/) {
        return undef;
    }

    my $from = $who;
    my $to   = $1;
    my $msg  = $2;
    
    my $tofactoid = &::get('is', "${to}'s pager");

    if ($tofactoid =~ /(\S+@\S+)/) {
        my $toaddr = $1;
        $toaddr =~ s/^mailto://;
        
        my $fromfactoid = &::get('is', "${from}'s pager");

        my $fromaddr;
        if ($fromfactoid =~ /(\S+@\S+)/) {
            $fromaddr = $1;
            $fromaddr =~ s/^mailto://;
        }
        else {
            $fromaddr = 'infobot@example.com';
        }

        my $channel = &::channel() || 'infobot';

        &::status("pager: from $from <$fromaddr>, to $to <$toaddr>");
        my %headers = (
            To         => "$to <$toaddr>",
            From       => "$from <$fromaddr>",
            Subject    => "Message from $channel!",
            'X-Mailer' => "flooterbuck",
        );

        my $logmsg;
        for (keys %headers) {
            $logmsg .= "$_: $headers{$_}\n";
        }
        $logmsg .= "\n$msg\n";
        &::status("pager:\n$logmsg");

        my $failed;
        my $mailer = new Mail::Mailer 'sendmail';
        $failed++ unless $mailer->open(\%headers);
        $failed++ unless print $mailer "$msg\n";
        $failed++ unless $mailer->close;

        if ($failed) {
             $callback->("Sorry, an error occurred while sending mail.")
        }
        else {
             $callback->("$from: I sent mail to $toaddr.");
        }
    }
    else{
        $callback->("Sorry, I don't know ${to}'s email address.")
    }
    return 'NOREPLY';
}
"pager";
