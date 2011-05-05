#!/usr/bin/perl -w

# usage: ./detect_word th Th-farang
# downloads description of Th-farang.ogg from Wikimedia Commons and tries to
# detect which word was actually pronounced (in this case: ฝรั่ง).

use strict;

use Derbeth::Commons;
use Encode;

if ($#ARGV != 1) {
	die "expects 2 arguments";
}

my $lang_code=$ARGV[0];
my $word = decode_utf8($ARGV[1]);
$word =~ s/^File://i;
$word .= '.ogg' if ($word !~ /\.ogg$/);

my @detected = detect_pronounced_word($lang_code, $word);

if ($#detected != -1) {
	$, = ' ';
	print scalar(@detected), ' detected words: ', encode_utf8("@detected"), "\n";
} else {
	my $page = "File:$word";
	my ($file, @words) = word_pronounced_in_file($page, $lang_code);
	if ($#words != -1) {
		$, = ' ';
		print scalar(@words), ' candidate words: ', encode_utf8("@words"), "\n";
	} else {
		print "word not identified\n";
	}
}
