#!/usr/bin/env perl
#
# ncol
#
# dwf -- initial
# Wed Mar 11 16:16:12 MDT 2009

use strict;
use FileHandle;
use Getopt::Long;

(my $optCol = shift) =~ s/^-//;
usage() if $optCol !~ /\d+/;

my (@data, @pad);
while(my $line = <>) {
    chomp $line;
    push(@data, split(' ', $line));
}

# Output a single line (@data columns) when $optCol == 0 
$optCol = @data if $optCol == 0;

my $n;
@pad = (0) x $optCol;
# Find the longest string in each column
for (my $i=0; $i<@data; $i++) {
    $n = $i % $optCol;
    if (length($data[$i]) > $pad[$n]) {
        $pad[$n] = length($data[$i]);
    }
}

for (my $i=0; $i<@data; $i++) {
    $n = $i % $optCol;
    print $data[$i] . ' ' x ($pad[$n] - length($data[$i]) + 1);
    print "\n" if $n == ($optCol - 1);
}
print "\n" unless $n == ($optCol - 1);

sub usage {
    my $bname = substr($0, rindex($0, "/") + 1);
    print STDERR "$bname n file|stdin\n";
    print STDERR "Examples:\n";
    print STDERR "    echo 1 2 3 4 5 6 | $bname 2\n";
    print STDERR "    1 2\n";
    print STDERR "    3 4\n";
    print STDERR "    5 6\n";
    print STDERR "\n    echo 1 2 3 4 5 6 | $bname 3\n";
    print STDERR "    1 2 3\n";
    print STDERR "    4 5 6\n";
    exit 1;
}
