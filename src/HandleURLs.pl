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

        ::status("Storing url $url from $channel");
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
                &status("Found URL again: $url at $oldurl");
                my @instances=split(/\;/,$oldurl);
                ($firsttime,$firstnick)=split(/,/,$instances[0]);
                ($lasttime,$lastnick)=split(/,/,$instances[-1]);

                if($::param{"seenurls_obnoxious"}) {
                    # lambaste 'em for being so uncool as to paste a URL
                    # that anyone had ever seen before ever
                    if($firsttime == $lasttime) {
                        ::say("$who: That URL was mentioned here only ".
                            (get_timediff($lasttime))[0].
                            " ago by ".
                            ($lastnick==$who?
                                "yourself" :
                                $lastnick)."!")
                    } else {
                        ::say("$who: You out-of-it clod.  That URL was ".
                              "first mentioned here ".
                              (get_timediff($firsttime))[0].
                              " ago by ".
                              (($firstnick eq $who)?"yourself":$firstnick).
                              ", and last mentioned ".
                              (get_timediff($lasttime))[0].
                              " ago by ".
                              (($lastnick eq $who)?
                                  (($firstnick eq $lastnick)?
                                      "yourself (again)!":
                                      "yourself")
                                  :
                                  (($lastnick eq $firstnick)?
                                      "$lastnick (again)!":
                                      "$lastnick.")));
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
