#!/usr/bin/env perl

use strict;
use open qw/:std :encoding(UTF-8)/;
use feature 'unicode_strings';

#
# Reads 2 columns of numbers and outputs the
# Pearson Product Moment Correlation Coefficient.
#
# dwf -- initial
# Tue Feb 25 14:51:35 MST 2003
#
########################################################################
#
#          __
#          \       _         _
#          / ( x - x ) ( y - y )
#          --
#  r = -----------------------------------
#        -------------------------------
#        | __              __
#        | \       _  2    \       _  2
#        | / ( x - x )     / ( y - y )
#        | --              --
#       \|
#


my (@a, @b);

while (<>) {
    my @flds = split;
    if (isNumber($flds[0]) && isNumber($flds[1])) {
        push @a, $flds[0];
        push @b, $flds[1];
    }
}

print "N = ",scalar(@a),", r = ", correlate(\@a, \@b), "\n";
exit 0;

########################################################################

sub correlate {
    my ($x, $y) = @_;
    my ($n, $sx, $sy, $sxx, $syy, $sxy);

    die "correlate: array lengths unequal\n" if @$x != @$y;
    die "correlate: array of size==0\n" if @$x == 0;

    my $n = @$x;
    $sx = $sy = $sxx = $syy = $sxy = 0.0;

    for (my $i=0; $i<$n; ++$i) {
        $sx += $x->[$i];
        $sy += $y->[$i];
        $sxx += $x->[$i] * $x->[$i];
        $syy += $y->[$i] * $y->[$i];
        $sxy += $x->[$i] * $y->[$i];
    }

    return ($sxy - (($sx*$sy)/$n)) / sqrt(($sxx - ($sx*$sx)/$n) * ($syy - ($sy*$sy)/$n));
}

########################################################################

sub isNumber {
    return shift =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/;
}
