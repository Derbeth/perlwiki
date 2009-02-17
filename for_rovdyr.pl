#!/usr/bin/perl

# Sprawdza, dla jakich nagrań nie ma hasła

use strict;
use utf8;

use Derbeth::Wikitools;
use Derbeth::Util;
use Derbeth::I18n;
use Perlwikipedia;
use Encode;

my %done;
my %audio;

my $server='http://localhost/~piotr/plwikt/';
my $donefile='done/done_rovdyr.txt';

my $lang = 'ru';

read_hash_loose($donefile,\%done);
read_hash_loose("audio_${lang}.txt",\%audio);

$SIG{INT} = $SIG{TERM} = $SIG{QUIT} = sub { save_results(); exit; };

print "lang: $lang, audios: ", scalar(keys(%audio)),"\n";

my $count = 0;
my $done_count=0;
while (my ($entry,$audio_file) = each(%audio)) {
	if (++$count % 200 == 0) {
		print "$count\n";
	}
	
	if (exists($done{$entry})) {
		next;
	}
	if (++$done_count > 20000) {
		print "interrupted\n";
		last;
	}
	
	my $text = get_wikicode($server,$entry);
	
	if ($text !~ /\w/) {
		$done{$entry} = "no_entry|$audio_file";
		next;
	}
	
	my($before,$section,$after) = split_article_wikt('pl',get_language_name('pl',$lang),$text);
	
	if ($section !~ /\w/) {
		$done{$entry} = "entry_without_audio|$audio_file";
		next;
	}
	
	$done{$entry} = 'entry_exists';
}

save_results();

sub save_results() {
	save_hash($donefile,\%done);
}
