#!/usr/bin/perl

use strict;
use utf8;

use Derbeth::Wikitools;
use Derbeth::Util;
use Perlwikipedia;
use Encode;

my %done;
my %candidates;

my $donefile='done/done_wplink.txt';

read_hash_loose($donefile,\%done);

my %stat = ('not_noun' => 0, 'is_proper_name' => 0,
	'nothing_on_wp' => 0, 'nothing_on_disambigR' => 0,
	'already_has' => 0, 'candidate' => 0, 'no_disambig' => 0,
	'unknown'=>0, 'capital_letter' => 0,
	'no_dismabig_on_disambigR' =>0);

my $done_count = 0;
while (my($word,$result) = each(%done)) {
	my $found = 0;
	foreach my $type (keys(%stat)) {
		if ($result =~ /$type/) {
			$found = 1;
			++$stat{$type};
			if ($type ne 'unknown') {
				++$done_count;
			}
			if ($result =~ 'candidate_(.*)') {
				$candidates{$word} = $1;				
			}
			last;
		}
	}
	unless($found) {
		die "unknown type for ".encode_utf8($word).": $result";
	}
}

my $format = "%25s: %6d\n";
while (my($type,$count) = each(%stat)) {
	printf $format, $type, $count;
}
printf $format, 'done', $done_count;

foreach my $word (sort(keys(%candidates))) {
	my $link = $candidates{$word};
	print encode_utf8("# [[$word]] > [[w:$link]]\n");
}