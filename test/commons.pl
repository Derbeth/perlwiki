#!/usr/bin/perl -w

use strict;

use Derbeth::Commons;
use Encode;

my $input='testdata/commons.ini';
open(IN, $input) or die "cannot read $input";

my $tests=0;
my $line=0;
while(<IN>) {
	++$line;
	chomp;
	next if (/^#/ || !/\w/);
	$_ = decode_utf8($_);
	my ($key,$value) = split(/=/, $_);
	my ($lang, $input_file) = split(/\|/, $key);
	my @expected = split(/\|/, $value);

	die "parse error in $input:$line" unless($lang && $input_file);

	my ($file, @words) = word_pronounced_in_file("File:$input_file", $lang);
	if ($#words != $#expected) {
		die encode_utf8("$input:$line: expected '@expected' received '@words'");
	}
	for (my $i=0; $i<=$#words; ++$i) {
		if ($words[$i] ne $expected[$i]) {
			die encode_utf8("$input:$line: expected '$expected[$i]' received '$words[$i]'");
		}
	}
	++$tests;
}

print "\nAll $tests tests succeeded\n";
