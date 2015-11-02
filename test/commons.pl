#!/usr/bin/perl -w

use strict;
use utf8;

use Derbeth::Commons;
use Encode;
use File::Slurp;
use Test::Assert ':all';

test_word_pronounced_in_file();
test_detect_pronounced_word();
test_latin_chars_disallowed();

sub test_word_pronounced_in_file {
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
	close(IN);

	print "\nword_pronounced_in_file: $tests tests succeeded\n";
}

sub test_detect_pronounced_word {
	my $checked = 0;

	$checked += _check_detected('zh-mofang.txt', 'zh', ['模仿']);
	$checked += _check_detected('or-Ghana dhatu.txt', 'or', ['ଘନ ଧାତୁ']);
	$checked += _check_detected('or-Ghanagarjita.txt', 'or', ['ଘନଗର୍ଜିତ']);
	$checked += _check_detected('ka-vietnami.txt', 'ka', ['ვიეტნამი']);

	print "detect_pronounced_word: $checked tests succeeded\n";
}

sub test_latin_chars_disallowed {
	my $checked = 0;

	assert_true latin_chars_disallowed('ru'); ++$checked;
	assert_false latin_chars_disallowed('en'); ++$checked;

	print "latin_chars_disallowed: $checked tests succeeded\n";
}

sub _check_detected {
	my ($input_file, $lang_code, $expected_arr) = @_;
	assert_true Derbeth::Commons::_detect_language_supported($lang_code);
	my $input = read_file("testdata/commons-detect/$input_file", binmode => ':utf8');
	my @actual = Derbeth::Commons::_detect($lang_code, $input);
	assert_deep_equals $expected_arr, \@actual;
	return 1;
}
