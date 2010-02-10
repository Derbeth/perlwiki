#!/usr/bin/perl -w

use strict;

use Getopt::Long;

my $times = 10;

GetOptions('times|t=i' => \$times) or die "wrong usage";

foreach (my $i=0; $i<$times; ++$i) {
	my $res = system(@ARGV);
	last if ($res == 0);
}

