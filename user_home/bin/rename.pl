#!/usr/bin/env perl

use strict;
use open qw/:std :encoding(UTF-8)/;
use feature 'unicode_strings';

# rename - Larry's filename fixer
my $op = shift or die "Usage: rename expr [files]\n";
chomp(@ARGV = <STDIN>) unless @ARGV;
for (@ARGV) {
	my $was = $_;
	eval $op;
	die $@ if $@;
	rename($was,$_) unless $was eq $_;
}
