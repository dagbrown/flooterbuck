#------------------------------------------------------------------------
# Load modules
# 
# Loads all files in the infobot "moddir" (see infobot.conf in the
# config directory) with the extension of .pm
#------------------------------------------------------------------------
# loadmodules written by dagbrown
# updated by rharman

use strict;
package Extras;


my @modules;

my %nopreprocess_modules;

sub loadmodules() {
    @modules=();
    opendir(MODS,$::param{'moddir'});
    for my $module (
        grep {
            /\.pm$/ && -f $::param{'moddir'}."/$_" 
        } readdir(MODS)
    ) {
        &::status("Loading $module...");
        push @modules,eval { do $::param{'moddir'}."/$module" };
        die "$@" if $@;
    }
    closedir MODS;
    %nopreprocess_modules=();
    &::status(sprintf("Modules loaded: %s.\n",join(", ",@modules)));
}

sub main::Modules_Preprocess {
    my ($channel, $message, $who) = @_;

    loadmodules unless @modules;

    for my $module(@modules) {
        if($::msgType eq 'public') {
            unless($nopreprocess_modules{$module}) {
                if(eval qq{${module}::preprocess(\$channel,
                        "\$message",\$who)}) {
                    &::status("preprocess caught by $module");
                }

                if($@) {
                    if("$@" =~ /^Undefined subroutine.*preprocess/) {
                        $nopreprocess_modules{$module}++;
                    } else {
                        warn "$@" 
                    }
                }
            }
        }
    }

    return undef;
}

sub main::Extras {

    loadmodules unless @modules;

    for my $module(@modules) {
        if($::msgType eq 'public') {
            if (
                eval qq{
                    ${module}::scan( sub {
                        ::say shift;
                    },"\$::message",\$::who )
                }
            ) {
                &::status("caught by $module");return 'NOREPLY'
            }

            if($@) {
                warn "$@" unless "$@" =~ /^Undefined subroutine/;
            }

        } else {
            if (
                eval qq{ 
                    ${module}::scan( sub {
                        ::msg("\$::who",shift); 
                    },"\$::message","\$::who" )
                }
            ) { 
                &::status("caught by $module");
                return 'NOREPLY'
            }
            warn "$@" if "$@";
        }
    }
    return undef; # To keep stock infobot happy
}

sub modules { @modules; }

1;
