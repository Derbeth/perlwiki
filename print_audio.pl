#!/usr/bin/perl

use strict;
use utf8;

use Perlwikipedia;
use Derbeth::Wikitools;
use Derbeth::Wiktionary;
use Derbeth::I18n;
use Derbeth::Util;
use Encode;
use Getopt::Long;

my $filename=$ARGV[0];

my %audios;

read_hash_strict($filename, \%audios);

print "{| class=\"wikitable\"\n";
foreach my $entry (sort(keys(%audios))) {
	my $line = $audios{$entry};
	my @files = split /\|/, $line;
	for (my $i=0; $i<=$#files;++$i) {
		$files[$i] =~ s/<.*>//g;
		$files[$i] = '[[commons:File:'.$files[$i].'|'.$files[$i].']]';
	}
	
	print "|-\n";
	print encode_utf8("| [[$entry]]\n");
	print encode_utf8("| ".join(', ', @files)."\n");
}
print "|}\n";
