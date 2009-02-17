#!/usr/bin/perl

use strict;
use utf8;

use Derbeth::Wikitools;
use Derbeth::Util;
use Perlwikipedia;
use Encode;

my %done;
my @found;

my $server='http://localhost/~piotr/plwikt/';
my $donefile='done/done_equadus.txt';

read_hash_loose($donefile,\%done);

while (my($word,$result) = each(%done)) {
	if ($result eq 'no audio') {
		push @found, $word;
	}
}

my @found_sorted = sort(@found);

open(REPORT,'>done/equadus_report.txt');
foreach my $word (@found_sorted) {
	print REPORT encode_utf8("$word\n");
}
close(REPORT);