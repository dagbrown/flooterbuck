#------------------------------------------------------------------------
# DNS
#
# Look up the IP address of a host, or the hostname of an IP address.
#
# infobot :: Kevin Lenzo  (c) 1997
# once again, thanks to Patrick Cole
#------------------------------------------------------------------------

package dns;

use strict;
use Socket;

my $no_posix;

BEGIN {
    eval "use POSIX";
    if ($@) { $no_posix++};
}

my $DNS_CACHE_EXPIRE_TIME = 7*24*60*60;
my %DNS_CACHE;
my %DNS_TIME_CACHE;

sub dns_byname {
    my $name=$_[0];
    my $result;

    my $x = join('.',unpack('C4',(gethostbyname($name))[4]));
    if ($x !~ /^\s*$/) {
        $result = "$name is $x";
    } else {
        $result = "I can\'t find the machine name \"$name\"";
    }
    return $result;
}

sub dns_byaddr {
    my $addr=$_[0];
    my $result;

    my $y = pack('C4', split(/\./, $addr));
    my $x = (gethostbyaddr($y, &AF_INET));
    if ($x !~ /^\s*$/) {
        $result = "$addr is $x" unless ($x =~ /^\s*$/);
    } else {
        $result = "I can't seem to find $addr in DNS";
    }
}

sub dns_getdata {
    my $in=$_[0];
    my $result;

    if($DNS_CACHE{$in}
        and ((time()-$DNS_TIME_CACHE{$in}) < $DNS_CACHE_EXPIRE_TIME)) {
        return $DNS_CACHE{$in};
    }

    if ($in =~ /(\d+\.\d+\.\d+\.\d+)/) {
        &::status("DNS: $$: query by IP address: $in");
        my $match = $1;
        $result=dns_byaddr($match);
    } else { 
        &::status("DNS: $$: query by name: $in");
        $result=dns_byname($in);
    }
    $DNS_TIME_CACHE{$in} = time();
    $DNS_CACHE{$in} = $result;

    return $result;
}

sub get {
    my($callback, $addr, $who)=@_;

    $SIG{CHLD}="IGNORE";
    my $pid=eval { fork(); }; # Don't worry if the OS doesn't fork
    return 'NOREPLY' if $pid;
    $callback->("$who: ".&dns_getdata($addr));
    if (defined($pid))                # child exits, non-forking OS returns
    {
        exit 0 if ($no_posix);
        POSIX::_exit(0);
    }
}

sub scan(&$$) {
    my($callback,$message,$who)=@_;
    if ($message =~ /^\s*(?:nslookup|dns)(?: for)?\s+(\S+)$/i) {
        &::status("DNS Lookup: $1");
        &get($callback,$1,$who);
	return 1;
    }
    return undef;
}

"dns";

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
