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

my $word = decode_utf8($ARGV[1]);
$word .= '.ogg' if ($word !~ /\.ogg$/);

my @detected = detect_pronounced_word($ARGV[0], $word);

if ($#detected != -1) {
	$, = ' ';
	print scalar(@detected), ' detected words: ', encode_utf8("@detected"), "\n";
} else {
	print "word not detected\n";
}
