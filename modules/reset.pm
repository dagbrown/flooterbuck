#------------------------------------------------------------------------
# "reset!" module
#
# Allows on-the-fly rescanning of the modules directory
#------------------------------------------------------------------------

package reset;

sub scan(&$$) {
    my $callback=shift;
    my $message=shift;
    my $who=shift;

    if($message=~/^\s*reset!\s*$/) {
        &Extras::loadmodules;
        $callback->("$who: Okay.");
        return 1;
    } else {
        return undef;
    }
}

"reset";
