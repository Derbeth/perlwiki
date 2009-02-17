#!/usr/bin/perl -w

use utf8;
use strict;

use Encode;
use Derbeth::I18n;

my $sum=0;
my %count;

while(<>) {
	if (/^(\w+)=(\d+)/) {
		$sum += $2;
		my $lang=get_language_name('pl',$1);
		my $c=$2;
		$lang =~ s/^język //;
		$count{$lang} = $c;
	}
}

my @sorted = sort { $a cmp $b } (keys(%count));

foreach my $s (@sorted) {
	print "|-\n| ", encode_utf8($s), ,' || ', $count{$s}, "\n";
}

print "sum: ",$sum,"\n";

