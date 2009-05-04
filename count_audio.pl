#!/usr/bin/perl -w

use utf8;
use strict;

use Encode;
use Derbeth::I18n;
use Getopt::Long;

my $wikt_lang='en';

GetOptions(
	'f|lang=s' => \$wikt_lang,
);

my $sum=0;
my %count;

open(IN,"audio_count_${wikt_lang}wikt.txt") or die;

while(<IN>) {
	if (/^(\w+)=(\d+)/) {
		if ($2 > 0) {
			$sum += $2;
			my $lang=get_language_name($wikt_lang,$1);
			my $c=$2;
			$lang =~ s/^język //;
			$count{$lang} = $c;
		}
	}
}
close(IN);

my @sorted = sort { $a cmp $b } (keys(%count));

foreach my $s (@sorted) {
	print "|-\n| ", encode_utf8($s), ,' || ', $count{$s}, "\n";
}

print "|- class=\"sortbottom\"\n! sum !! $sum\n|}\n";
