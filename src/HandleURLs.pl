#!/usr/bin/perl -w

#------------------------------------------------------------------------
# handle URLs
#------------------------------------------------------------------------

use strict;

{
    my %urls;

    # Mea culpa, this code was pasted from seen.pm
    sub get_timediff($) {
        my $when = shift;

        my $howlong = time() - $when;
        $when = localtime $when;


        my @tstring = (($howlong % 60). " second".(($howlong%60>1)&&"s"));
        my $shorttstring = sprintf("%02d", ($howlong % 60));
        $howlong = int($howlong / 60);

        $shorttstring = sprintf("%02d", ($howlong % 60)). ":$shorttstring";
        if ($howlong % 60 > 0) {
            unshift @tstring, ($howlong % 60). " minute".(($howlong%60>1)&&"s");
        }
        $howlong = int($howlong / 60);

        $shorttstring = ($howlong % 24). ":$shorttstring";
        if ($howlong % 24 > 0) {
            unshift @tstring, ($howlong % 24). " hour".(($howlong%24>1)&&"s");
        }
        $howlong = int($howlong / 24);

        if ($howlong % 365 > 0) {
            $shorttstring = ($howlong % 365). "d, $shorttstring";
            unshift @tstring, ($howlong % 365). " day".(($howlong%365>1)&&"s");
        }
        $howlong = int($howlong / 365);

        if ($howlong > 0) {
            unshift @tstring, "$howlong years";
            $shorttstring = $howlong."y, $shorttstring";
        }

        my $tstring;
        if(scalar(@tstring)==1) {
            $tstring=$tstring[0];
        } else {
            $tstring="$tstring[0] and $tstring[1]"
        }
        return ($tstring, $shorttstring);
    }

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
        my ($channel,$url,$who)=@_;

        # are you COOL enough?!
        if($::param{"seenurls"}) {
            my ($firsttime,$firstnick);
            my ($lasttime,$lastnick);

            $lasttime=$firsttime=time;
            $lastnick=$firstnick=$who;

            my $oldurl = ::get(seenurls => "$channel|$url");
            if($oldurl) {
                my @instances=split(/\;/,$oldurl);
                ($firsttime,$firstnick)=split(/,/,$instances[0]);
                ($lasttime,$lastnick)=split(/,/,$instances[-1]);

                if( ( $::param{"seenurls_obnoxious"} + 0.0 > 0 &&
                      rand > $::param{"seenurls_obnoxious"} ) ||
                    $::param{"seenurls_obnoxious"} eq "true" ) {
                    # lambaste 'em for being so uncool as to paste a URL
                    # that anyone had ever seen before ever
                    if($firsttime == $lasttime) {
                        ::say("$who: ".
                            ($lastnick==$who?
                                "You" :
                                $lastnick).
                            " mentioned that URL here only ".
                            (get_timediff($lasttime))[0].
                            " ago!");
                    } else {
                        ::say("$who: You out-of-it clod.  " .
                            (($firstnick eq $who)?"You":$firstnick) .
                            " first mentioned that URL here " .
                              (get_timediff($firsttime))[0] .
                              " ago, and " .
                              (($lastnick eq $who) ?
                                  "you" :
                                  $lastnick).
                              " last mentioned it " .
                              (get_timediff($lasttime))[0] .
                              " ago" .
                              (($lastnick eq $firstnick) ?
                                  ", again!":
                                  "."))
                    }
                }
            }

            $lasttime=time;
            $lastnick=$who;

            ::set("seenurls","$channel|$url",
                             "$firsttime,$firstnick;$lasttime,$lastnick");
        }
    } # ::seenURL
}

1;
