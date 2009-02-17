#!/usr/bin/perl

use utf8;
use strict;
use English;

use Derbeth::Util;
use Encode;

my %done;

my $donefile='done_wyrazy.txt';
read_hash_loose($donefile,\%done);

open(OUT,'>raport_wyrazy.txt');

my %wyrazy;

while (my ($key,$val) = each(%done)) {
	if ($val =~ /^jest,/) {
		$val = $POSTMATCH;
		my ($v1,$v2) = split /,/, $val;
		
		$wyrazy{$v1} = 1 if ($v1);
		$wyrazy{$v2} = 1 if ($v2);
	}
}

my @sorted = sort keys(%wyrazy);

foreach my $word (@sorted) {
	print OUT encode_utf8($word), "\n";
}

close(OUT);

