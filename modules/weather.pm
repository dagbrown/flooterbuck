#------------------------------------------------------------------------
# NOAA Weather module.
#
# kevin lenzo (C) 1999 -- get the weather forcast NOAA.
# feel free to use, copy, cut up, and modify, but if
# you do something cool with it, let me know.
#
# $Id: weather.pm,v 1.11 2005/01/21 20:58:03 rich_lafferty Exp $
#------------------------------------------------------------------------

package weather;

my $no_weather;
my $default = 'KAGC';

BEGIN {
    $no_weather = 0;
    eval "use LWP::UserAgent";
    $no_weather++ if ($@);
}

sub get_weather {
    my ($station) = shift;
    my $result;

    # make this work like Aviation
    $station = uc($station);
    
    my $station = uc($2);
    $station =~ s/[.?!]$//;
    $station =~ s/\s+$//g;
    return "'$station' doesn't look like a valid ICAO airport identifier."
        unless $station =~ /^[\w\d]{3,4}$/;
    $station = "C" . $station if length($station) == 3 && $station =~ /^Y/;
    $station = "K" . $station if length($station) == 3;

    if ($no_weather) {
        return 0;
    } else {

        my $ua = new LWP::UserAgent;
        if (my $proxy = main::getparam('httpproxy')) { $ua->proxy('http', $proxy) };

        $ua->timeout(10);
        my $request = new HTTP::Request('GET', "http://weather.noaa.gov/weather/current/$station.html");
        my $response = $ua->request($request); 

        if (!$response->is_success) {
            return "Something failed in connecting to the NOAA web server. Try again later.";
        }

        $content = $response->content;

        if ($content =~  /ERROR/i) {
            return "I can't find that station code (see http://weather.noaa.gov/weather/curcond.html for locations codes)";
        } 

        $content =~ s|.*?current weather conditions:<BR>(.*?)</B>.*?</TR>||is;
        my $place = $1;

        # $content =~ s|.*?<TR>(?:\s*<[^>]+>)*\s*([^<]+)\s<.*?</TR>||is;
        my $place = $1;
        chomp $place;

        $content =~ s|.*?<TR>(?:\s*<[^>]+>)*\s*([^<]+)\s<.*?</TR>||is;
        my $id = $1;
        chomp $id;

        $content =~ s|.*?conditions at.*?</TD>||is;

        $content =~ s|.*?<OPTION SELECTED>\s+([^<]+)\s<OPTION>.*?</TR>||s;
        my $time = $1;
        $time =~ s/-//g;
        $time =~ s/\s+/ /g;

        $content =~ s|\s(.*?)<TD COLSPAN=2>||s;
        my $features = $1;

        my %feat;
        while ($features =~ s|.*?<TD ALIGN[^>]*>(?:\s*<[^>]+>)*\s+([^<]+?)\s+<.*?<TD>(?:\s*<[^>]+>)*\s+([^<]+?)\s<.*?/TD>||s) {
            my ($f,$v) = ($1, $2);
            chomp $f; chomp $v;
            $feat{$f} = $v;
        }

        $content =~ s|.*?>(\d+\S+\s+\(\S+\)).*?</TD>||s;  # max temp;
        $max_temp = $1;
        $content =~ s|.*?>(\d+\S+\s+\(\S+\)).*?</TD>||s;  
        $min_temp = $1;

        if ($time) {
            $result = "$place; $id; last updated: $time";
            foreach (sort keys %feat) {
                next if $_ eq 'ob';
                $result .= "; $_: $feat{$_}";
            }
            my $t = time();
        } else {
            $result = "I can't find that station code (see http://weather.noaa.gov/weather/curcond.html for locations and codes)";
        }
        return $result;
    }
}

sub scan (&$$) {
    my ($callback,$message,$who) = @_;

    if (::getparam('weather') 
            and ($message =~ /^\s*(wx|weather)\s+(?:for\s+)?(.*?)\s*\?*\s*$/)) {
        my $code = $2;
        $callback->(get_weather($code));
        return 'NOREPLY';
    }
    return undef;
}


"weather";

__END__

=head1 NAME

weather.pm - Get the weather from a NOAA server

=head1 PREREQUISITES

	LWP::UserAgent

=head1 PARAMETERS

weather

=head1 PUBLIC INTERFACE

	weather [for] <station>

=head1 DESCRIPTION

Contacts C<weather.noaa.gov> and gets the weather report for a given
station.

=head1 AUTHORS

Kevin Lenzo
