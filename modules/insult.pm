# Template infobot extension

# CHANGES
#
# 2002/08/20 -- Added check for Net::Telnet -- awh@awh.org

use strict;
package insult;

my $no_insult;
BEGIN {
	eval "use Net::Telnet ();";
	$no_insult++ if ($@) ;
}

sub scan(&$$) {
    my ($callback,$message,$who) = @_;

    # Check $message, if it's what you want, then do stuff with it
    if($message =~ /^insult\s+/)
    {
	if ($no_insult)
	{
		$callback->("insult.pm requires Net::Telnet, $who");
		return 1;
	}
      my $nick = $1;
      my $t = new Net::Telnet (Errmode => "return", Timeout => 3);
      $t->Net::Telnet::open(Host => "insulthost.colorado.edu", Port => "1695");
      my $line = $t->Net::Telnet::getline(Timeout => 4);
      $callback->($line);
      return 1;
    }
    return undef;
}

return "insult";

__END__

=head1 NAME

insult.pm - Description

insult module for flooterbuck infobot, using insulthost.colorado.edu:1695.

=head1 PREREQUISITES

	Net::Telnet

=head1 DESCRIPTION

Port of the Extras.pl code from stock infobot

=head1 AUTHORS

flooterbuck+insult.pm@richardharman.com
