#!/usr/bin/perl -w

#------------------------------------------------------------------------
# handle URLs
#------------------------------------------------------------------------

use strict;

{
    my %urls;

    sub ::mentionURL {
        my ($channel,$url,$who)=@_;

        $urls{$channel}=$url;
        ::seenURL($channel,$url,$who);
    }

    sub ::lastURL {
        my $channel=shift;

        return $urls{$channel};
    }

    sub ::seenURL {
        undef;
    }
}

1;
