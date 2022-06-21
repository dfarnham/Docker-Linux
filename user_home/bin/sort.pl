#!/usr/bin/env perl -w

use strict;
use Getopt::Long;
use open qw/:std :encoding(UTF-8)/;
use feature 'unicode_strings';

my ($ignoreLines, $separator, $field, $numeric, $reverse, $help);
GetOptions('ignore=i'    => \$ignoreLines,
           'separator=s' => \$separator,
           'field=i'     => \$field,
           'numeric'     => \$numeric,
           'reverse'     => \$reverse,
           'help'        => \$help) or usage();
usage() if $help;


my $header = '';
my @data;
my @flds;
while(<>) {
    if ($ignoreLines) {
        $ignoreLines--;
        $header .= $_;
        next;
    }
    if ($separator) {
        @flds = split(/$separator/);
    }
    else {
        @flds = split;
    }

    if ($field) {
        push(@data, {'_line_' => $_, 'field' => $flds[$field - 1]});
    }
    else {
        push(@data, {'_line_' => $_, 'field' => $_});
    }
}

if ($numeric) {
    @data = sort {$a->{'field'} <=> $b->{'field'}} @data;
}
else {
    @data = sort {$a->{'field'} cmp $b->{'field'}} @data;
}

@data = reverse @data if $reverse;


print $header;
foreach my $item (@data) {
    print $item->{'_line_'}
}
exit 0;



sub usage {
    my $bname = substr($0, rindex($0, "/") + 1);
    print STDERR "$bname -field # [-ignore #] [-separator sep] [-numeric] [-reverse]\n";
    exit 1;
}
