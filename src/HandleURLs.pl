#!/usr/bin/perl -w

#------------------------------------------------------------------------
# handle URLs
#------------------------------------------------------------------------

use strict;

{
    my %urls;

    sub ::mentionURL($$) {
        my ($channel,$url)=@_;

        ::status("Storing url $url from $channel");
        $urls{$channel}=$url;
    }

    sub ::lastURL($) {
        my $channel=shift;

        return $urls{$channel};
    }
}

1;
