#------------------------------------------------------------------------
# DNS
#
# Look up the IP address of a host, or the hostname of an IP address.
#
# infobot :: Kevin Lenzo  (c) 1997
# once again, thanks to Patrick Cole
#------------------------------------------------------------------------

package DNS;

use strict;
use Socket;

sub REAPER {
	$SIG{CHLD} = \&REAPER;	# loathe sysV
	my $waitedpid = wait;
}

$SIG{CHLD} = \&REAPER;
my $DNS_CACHE_EXPIRE_TIME = 7*24*60*60;
my %DNS_CACHE;
my %DNS_TIME_CACHE;

sub DNS {
    my $callback=shift;
    my $in = shift;
    my $who = shift;

    my($match, $x, $y, $result);

    if($DNS_CACHE{$in}
        and ((time()-$DNS_TIME_CACHE{$in}) < $DNS_CACHE_EXPIRE_TIME)) {
        return $DNS_CACHE{$in};
    }

    my $pid=fork;
    return 1 if $pid;  # have it still work on non-forking OSes
    if ($in =~ /(\d+\.\d+\.\d+\.\d+)/) {
        &::status("DNS query by IP address: $in");
        $match = $1;
        $y = pack('C4', split(/\./, $match));
        $x = (gethostbyaddr($y, &AF_INET));
        if ($x !~ /^\s*$/) {
            $result = $match." is ".$x unless ($x =~ /^\s*$/);
        } else {
            $result = "I can't seem to find that address in DNS";
        }
    } else { 
        &::status("DNS query by name: $in");
        $x = join('.',unpack('C4',(gethostbyname($in))[4]));
        if ($x !~ /^\s*$/) {
            $result = $in." is ".$x;
        } else {
            $result = "I can\'t find that machine name";
        }
    }
    $DNS_TIME_CACHE{$in} = time();
    $DNS_CACHE{$in} = $result;

    $callback->($result);
    exit if defined($pid);			# bye child
}

sub scan(&$$) {
    my($callback,$message,$who)=@_;
    if ($message =~ /^\s*(?:nslookup|dns)(?: for)?\s+(\S+)$/i) {
        &::status("DNS Lookup: $1");
        &DNS($callback,$1,$who);
	return 1;
    }
    return undef;
}

"DNS";

__END__

=head1 NAME

DNS.pl - Look up hosts in DNS

=head1 PREREQUISITES

None.

=head1 PARAMETERS

allowDNS

=head1 PUBLIC INTERFACE

	nslookup|DNS [for] <host>

=head1 DESCRIPTION

Looks up DNS entries for the given host using
C<gethostbyaddr>/C<gethostbyname> calls.

=head1 AUTHORS

Kevin Lenzo
