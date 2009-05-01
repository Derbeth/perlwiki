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

my %done_audio;
my %done_de;

read_hash_loose('audio/audio_de.txt', \%done_audio);
read_hash_loose('done/done_dewikt_de.txt', \%done_de);

my $deleted = 0;

foreach my $audio (keys(%done_audio)) {
	if (exists($done_de{$audio})) {
		delete $done_de{$audio};
		++$deleted;
	}
}

print "deleted $deleted\n";

save_hash_sorted('done/done_dewikt_de.txt', \%done_de);

# while(<>) {
# 	/^# \[\[(.+?)\]\] >/;
# 	print "$1=unknown\n";
# }