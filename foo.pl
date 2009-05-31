#!/usr/bin/perl

use strict;
use utf8;
use Encode;
use Derbeth::Wikitools;
use Derbeth::Wiktionary;
use Derbeth::Util;
use Derbeth::Web;
use Perlwikipedia;
use Getopt::Long;

my $res = get_wikicode('http://en.wiktionary.org/w/','kita-noun');

print ">>$res<<\n";

if ($res !~ /\w/) {
	print "no word\n";
} else {
	print "has word\n";
}

# while(<>) {
# 	/^# \[\[(.+?)\]\] >/;
# 	print "$1=unknown\n";
# }