#!/usr/bin/perl -w

use strict;
use utf8;

use Encode;
use Getopt::Long;
use Derbeth::Util;
use Derbeth::Wikitools 0.8.0;
use Derbeth::Wiktionary;

my $wikt_lang='en';
my $lang_code='de';
my @entries;

GetOptions('w|wikt=s' => \$wikt_lang, 'l|lang=s'=> \$lang_code) or die;
die "expects entry names as arguments" if ($#ARGV == -1);
@entries = @ARGV;

my $server = "http://$wikt_lang.wiktionary.org/w/";

foreach my $entry (@entries) {
	my $page_text = get_wikicode($server,$entry);

	initial_cosmetics($wikt_lang, \$page_text,$entry);
	my ($before,$section,$after) = split_article_wikt($wikt_lang,$lang_code,$page_text,1);
	if ($section !~ /\w/) {
		print "no $lang_code section in ", encode_utf8($entry), "\n";
	} else {
		print encode_utf8($section), "\n\n";
	}
}

