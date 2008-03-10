use strict;
package say;

sub scan(&$$) {
    my ($callback,$message,$who) = @_;

        if ($::addressed and &::IsFlag("S")) {
        if ($message =~ s/^\s*say\s+(\S+)\s+(.*)//) {
            &::msg($1, $2);
            &::msg($who, "ok.");
            return 'NOREPLY';
        }
    }
undef;
}

"say";
