#!/usr/bin/perl
use strict;
use utf8;

use Perlwikipedia;
use Derbeth::Wikitools;
use Derbeth::Util;
use Encode;

my $donefile='done/done_isl.txt';

my %data;
my @with_fraz;
read_hash_strict($donefile,\%data);

while (my($key,$val) = each(%data)) {
	if ($val =~ /present/) {
		push @with_fraz, $key;
	}
}

my @fraz_sorted = sort @with_fraz;

open(OUT,'>done/fraz_for_zajac.txt');
foreach my $entry (@fraz_sorted) {
	print OUT encode_utf8("# [[$entry]]\n");
}
