# loadmodules written by dagbrown
# updated by rharman

use strict;
package Extras;


#------------------------------------------------------------------------
# Load modules
# 
# loads all files in infobot/modules with the extention of .pm
#------------------------------------------------------------------------

my @modules;

sub loadmodules() {
    @modules=();
    opendir(MODS,$::param{'moddir'});
    for my $module (grep { /\.pm$/ && -f $::param{'moddir'}."/$_" } readdir(MODS)) {
        &::status("Loading $module...");
        push @modules,eval { do $::param{'moddir'}."/$module" };
        die "$@" if $@;
    }
    closedir MODS;
    &::status(sprintf("Modules loaded: %s.\n",join(", ",@modules)));
}


sub Extras {
    my $callback;
    loadmodules unless @modules;

    for my $module(@modules) {
        if($::msgType eq 'public') {
            if (eval qq|${module}::scan {::say shift;} "\$::message",\$::who|)
            { &::status("caught by extras module '$module'"); return 'NOREPLY'}
            warn "$@" if "$@";
        } else {
            if (eval qq{ ${module}::scan { ::msg("\$::who",shift); } "\$::message","\$::who" })
            { &::status("caught by extras module '$module'"); return 'NOREPLY'}
            warn "$@" if "$@";
        }

    }
    return undef;
}
1;

