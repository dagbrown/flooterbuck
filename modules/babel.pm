#------------------------------------------------------------------------
# Babelfish Translation Module
#
# See the POD documentation (right here!) for more info
#
# $Id: babel.pm,v 1.8 2006/10/08 04:30:06 rich_lafferty Exp $
#------------------------------------------------------------------------

=head1 NAME

babel.pm - Translates things from one language to another by passing them
to babelfish.altavista.com

=head1 PREREQUISITES

 URI::Escape
 LWP::UserAgent
 Jcode, if translating Japanese messages

=head1 SERVING SUGGESTION

 floot, translate Im Himmel gibt's kein Bier from de
 floot, translate ce qui embellit le desert, c'est qu'il cache un puits quelque part from fr to de
 floot, translate dos huevos, por favor from es to fr through en

=head1 DESCRIPTION

Uses Babelfish to translate phrases from one language to another, through an
optional third language.

=head1 PARAMETERS

floot, translate <phrase> [to <lang>] [from <lang>] [through <lang>]

to - The language to translate to.  Defaults to en if not given.

from - The language to translate from.  Defaults to en if not given.

through - If given, rather than a direct translation from to_lang to from_lang,
does a translation from to_lang to through_lang and then from through_lang to
to_lang.  This is useful when using a language pair not explicitly supported
by babelfish.  It is also an endless source of amusement to have Flooterbuck
translate from one language, through another language, and back to the original language. 

=head1 KNOWN ISSUES

Babelfish seems fairly unreliable.  During "busy periods", as many as 60%
of requests fail.

=head1 AUTHORS

The original program was written by Jonathan Feinberg, jdf@pobox.com

The program was modified heavily by Drew Hamilton <awh@awh.org>, adding
translations between arbitrary language pairs, translations through languages,
and support for babelfish's current screen layout.

=cut

package babel;
use strict;

my $no_babel;
my $no_japanese;
my $no_posix;

BEGIN {
    eval "use URI::Escape";    # utility functions for encoding the
    if ($@) { $no_babel++ }
    ;                          # babelfish request
    eval "use LWP::UserAgent";
    if ($@) { $no_babel++ }
    eval "use Encode";
    if ($@) { $no_babel++ }

    eval qq{
		use Jcode qw();
	};
    $no_japanese++ if ($@);
    $no_japanese++ if ( !::getparam('japanese') );

    eval "use POSIX";
    if ($@) { $no_posix++ }
}

BEGIN {

    # Translate some feasible abbreviations into the ones babelfish
    # expects.
    use vars qw!%lang_code %lang_pairs $lang_regex!;
    %lang_code = (
        fr => 'fr',
        sp => 'es',
        es => 'es',
        po => 'pt',
        pt => 'pt',
        it => 'it',
        ge => 'de',
        de => 'de',
        gr => 'de',
        en => 'en',
        cn => 'zh',
        zh => 'zh',
        jp => 'ja',
        ja => 'ja',
        ru => 'ru',
        kr => 'ko',
        ko => 'ko'
    );

    %lang_pairs = (
        en => 'zh|fr|de|it|ja|ko|pt|es',
        zh => 'en',
        fr => 'en|de',
        de => 'en|fr',
        it => 'en',
        ja => 'en',
        ko => 'en',
        pt => 'en',
        ru => 'en',
        es => 'en'
    );

    # Here's how we recognize the language you're asking for.  It looks
    # like RTSL saves you a few keystrokes in #perl, huh?
    $lang_regex = join '|', keys %lang_code;
}

# takes a phrase, a from language, and a to language, and contacts babelfish
# for a translation.  Assumes that the language pair is a valid babelfish
# one, and also assumes that Jcode is installed and ::param('japanese') is
# true if either the to_lang or from_lang is japanese.
sub translate {
    my ( $phrase, $from_lang, $to_lang ) = @_;
    my $languagepair = "$from_lang" . "_" . "$to_lang";

    my $ua = new LWP::UserAgent;
    $ua->timeout(20);

    my $req = HTTP::Request->new( 'POST',
        'http://babelfish.altavista.com/babelfish/tr' );
    $req->content_type('application/x-www-form-urlencoded');

    # translate Japanese from EUC into UTF-8
    if ( $from_lang eq "ja" && !defined($no_japanese) ) {
        $phrase = Jcode::convert( $phrase, 'utf8' );
    } else {

        # latin-1
        $phrase = Encode::decode( 'iso-8859-1', $phrase );
        $phrase = Encode::encode( 'utf-8', $phrase );
    }

    #$phrase = "### " . $phrase . " ###";
    my $urltext = uri_escape($phrase);
    $req->content("urltext=$urltext&lp=$languagepair");

    my $res = $ua->request($req);

    if ( $res->is_success ) {

        my $html = $res->content;

        # even translating from Japanese to English convert the
        # result because it probably has some characters that didn't
        # translate
        if ( ( ( $from_lang eq "ja" ) || ( $to_lang eq "ja" ) )
            && !defined($no_japanese) )
        {
            $html = Jcode::convert( $html, 'euc', 'utf8' );
        } else {

            # latin-1
            $html = Encode::decode( 'utf-8', $html );
            $html = Encode::encode( 'iso-8859-1', $html );
        }

        # It's the contents of the first <div> tag after the "Babel Fish
        # Translation header
        my $translated = "The translation confused me.";

        if ( $html =~ m|<td bgcolor=white class=s>(.*?)</td>|s ) {
            $translated = $1;
            $translated =~ s/<.*?>//g;
            $translated =~ s/\n/ /mg;
        }
        return $translated;
    } else {
        return "I tried, but got: " . $res->status_line;    # failure
    }
}

sub scan(&$$) {
    my ( $callback, $message, $who ) = @_;

    # compatibility with old infobot syntax
    if ( ::getparam('babel_compat')
        && ( $message =~ /^x\s+(to|from|through)\s+(\w+)\s+(.*)$/ ) )
    {
        $message = "translate $3 $1 $2";
    }

    if ( ::getparam('babel') && ( $message =~ /^translate/ ) ) {
        if ($no_babel) {
            $callback->(
                'translate requires URI::Escape and LWP::UserAgent');
            return 'NOREPLY';
        }

# strip away the "from [xx]" and "to [xx]" so that what is left is the message
        my ( $from_lang, $to_lang, $through_lang );
        if ( $message =~ s/from\s+($lang_regex)(?:\s|$)// ) {
            $from_lang = $1;
        }

        if ( $message =~ s/to\s+($lang_regex)(?:\s|$)// ) {
            $to_lang = $1;
        }

        if ( $message =~ s/through\s+($lang_regex)(?:\s|$)// ) {
            $through_lang = $1;
        }

        $message =~ s/^translate//;

        # default language is English
        $from_lang = 'en' if ( !defined($from_lang) );
        $to_lang   = 'en' if ( !defined($to_lang) );

        #correct users' mis-guesses at the language codes.
        $from_lang    = $lang_code{$from_lang};
        $to_lang      = $lang_code{$to_lang};
        $through_lang = $lang_code{$through_lang};

      # make sure babelfish can translate to/from the languages involved
        if ( !defined($through_lang) ) {
            if ( $lang_pairs{$from_lang} !~ /$to_lang/ ) {
                $callback->(
"babelfish cannot translate from $from_lang to $to_lang.  Try translating through English."
                );
                return 'NOREPLY';
            }
        } else {
            if ( $lang_pairs{$from_lang} !~ /$through_lang/ ) {
                $callback->(
"babelfish cannot translate from $from_lang to $through_lang.  Try translating through English."
                );
                return 'NOREPLY';
            } elsif ( $lang_pairs{$through_lang} !~ /$to_lang/ ) {
                $callback->(
"babelfish cannot translate from $through_lang to $to_lang.  Try translating through English."
                );
                return 'NOREPLY';
            }
        }

        # we can only handle Japanese if we have Jcode.
        if (   ( ( $from_lang eq "ja" ) || ( $to_lang eq "ja" ) )
            && ($no_japanese) )
        {
            $callback->(
                "This particular infobot is not configured for Japanese"
            );
            return 'NOREPLY';
        }

        # we got here, so it's time to fork.
        $SIG{CHLD} = 'IGNORE';
        my $pid =
          eval { fork() };    # catch non-forking OSes and other errors
        return 'NOREPLY' if $pid;    # parent does nothing

        # doing a straight translation.
        if ( !defined($through_lang) ) {
            $callback->( &translate( $message, $from_lang, $to_lang ) );
        } else {

          # doing a double-translation (through an intermediary language
            my $intermediary =
              &translate( $message, $from_lang, $through_lang );
            $callback->(
                &translate( $intermediary, $through_lang, $to_lang ) );
        }

        # exit the forked process
        if ( defined($pid) ) {
            exit 0 if ($no_posix);
            POSIX::_exit(0);
        }

    }

    return undef;
}

"babel";
