#------------------------------------------------------------------------
# "sunhelp" command
#
# Based on "slashdot" module, but this should be torn apart a bit
# to make a generid RDF module.
#
# $Id: sunhelp.pm,v 1.6 2002/01/22 20:01:19 dagbrown Exp $
#------------------------------------------------------------------------

#####################
#                   #
#  Sunhelp.pl for   #
# Sunhelp headline  #
#     retrival      #
#  tessone@imsa.edu #
#   Chris Tessone   #
#   Licensing:      #
# Artistic License  #
# (as perl itself)  #
#####################
#fixed up to use XML'd /. backdoor 7/31 by richardh@rahga.com
#My only request if this gets included in infobot is that the 
#other header gets trimmed to 2 lines, dump the fluff ;) -rah

#added a status message so people know to install LWP - oznoid
#also simplified the return code because it wasn't working.

use strict;

package sunhelp;

my $no_slashlines;

BEGIN {
    $no_slashlines = 0;
    eval "use LWP::UserAgent";
    $no_slashlines++ if $@;
}

sub getsunhelpheads {
    # configure
    if ($no_slashlines) {
        &status("sunhelp headlines requires LWP to be installed");
        return '';
    }
    my $ua = new LWP::UserAgent;
    if (my $proxy = main::getparam('httpproxy')) { 
        $ua->proxy('http', $proxy) 
    };
    $ua->timeout(12);
    my $maxheadlines=5;
    my $slashurl='http://www.sunhelp.org/backend/sunhelp.rdf';
    my $story=0;
    my $slashindex = new HTTP::Request('GET',$slashurl);
    my $response = $ua->request($slashindex);

    if($response->is_success) {
        $response->content =~ /<time>(.*?)<\/time>/;
        my $lastupdate=$1;
        my $headlines = "Sunhelp - Updated ".$lastupdate;
        my @indexhtml = split(/\n/,$response->content);

        # gonna read in this xml stuff.
        foreach(@indexhtml) {
            if (/<story>/){$story++;}
            elsif (/<title>(.*?)<\/title>/){
                my $headline = $1;
                $headline =~ s/([A-Z])([A-Z]+)/${1}.lc($2)/eg;
                $headlines .= " | $headline";
            }
            elsif (/<url>(.*?)<\/url>/){
                # do nothing
            }
            elsif (/<time>(.*?)<\/time>/){
                # do nothing
            }     
            last if $story >= $maxheadlines;
            next;
        }

        return $headlines;
    } else {
        return "I can't find the headlines.";
    }
}

sub scan(&$$) {
    my($callback,$message,$who) = @_;

    if (defined(::getparam('slash')) 
            and $message =~ /^\s*sunhelp( headlines)?\W*\s*$/) {
        my $headlines = &getsunhelpheads();
        $callback->($headlines);
        return 1;
    } else {
        return undef;
    }
}

return "sunhelp";

__END__

=head1 NAME

sunhelp.pm - Sunhelp headlines grabber 

=head1 PREREQUISITES

	LWP::UserAgent

=head1 PARAMETERS

sunhelp

=head1 PUBLIC INTERFACE

	sunhelp [headlines]

=head1 DESCRIPTION

Retrieves the headlines from Sunhelp; probably obsoleted by RDF.

=head1 AUTHORS

Chris Tessone <tessone@imsa.edu>

