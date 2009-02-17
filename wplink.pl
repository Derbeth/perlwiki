#!/usr/bin/perl
# do linkowania z wikipedii do wikisłownika
 
use strict;
use utf8;

use Derbeth::Wikitools;
use Derbeth::Util;
use Perlwikipedia;
use Encode;
use English;

my %done;

my $server='http://localhost/~piotr/plwikt/';
my $wpserver='http://pl.wikipedia.org/w/';
my $donefile='done/done_wplink.txt';

read_hash_loose($donefile,\%done);

$SIG{INT} = $SIG{TERM} = $SIG{QUIT} = sub { save_results(); exit; };

#my @polish = get_category_contents($server,'Kategoria:polski (indeks)',undef,{main=>1, category=>0, image=>0});
#print scalar(@polish), " Polish entries\n";
#for my $entry (@polish) {
#	$done{$entry} = 'unknown';
#}
#save_results();
#exit;

my $count = 0;
my $done_count = 0;
foreach my $entry (keys(%done)) {
	if (++$count % 200 == 0) {
		print "$count\n";
	}
	
	if ($done{$entry} ne 'unknown') {
		next;
	}
	if (++$done_count > 70000) {
		print "finshed part\n";
		last;
	}
	
	if ($entry eq ucfirst($entry)) {
		$done{$entry} = 'capital_letter';
		next;
	}
	
	my $text = get_wikicode($server,$entry);
	
	my($before,$section,$after) = split_article_wikt('pl','język polski',$text);
	
	if ($section !~ /\w/) {
		save_results();
		die 'no text: '.encode_utf8($entry);
	}
	
	if ($section !~ /''rzeczownik/) {
		$done{$entry} = 'not_noun';
		next;
	}
	if ($section =~ 'nazwa własna') {
		$done{$entry} = 'is_proper_name';
		next;
	}
	
	my $wp_addr = $entry;
	my $wp_text = get_wikicode($wpserver,$wp_addr);
	if ($wp_text !~ /\w/) {
		$done{$entry} = 'nothing_on_wp';
		next;
	}
	
	if ($wp_text =~ /\{\{((w|W)ikisłownik|(w|W)wiktionary)/) {
		$done{$entry} = 'already_has';
		next;
	}
	
	if ($wp_text =~ /disambig/i) {
		if ($wp_text =~ /disambigR/i && $wp_text =~ /\[\[(.*?\(ujednoznacznienie\))/) {
			$wp_addr = $1;
			if ($wp_addr =~ /^.*\[\[/) {
				$wp_addr = $POSTMATCH;
			}
			#print encode_utf8("disambig: $wp_addr\n");
			$wp_text = get_wikicode($wpserver,$wp_addr);
			#print encode_utf8("text: '$wp_text'\n");
			if ($wp_text !~ /\w/) {
				$done{$entry} = 'nothing_on_disambigR';
				next;
			}
			if ($wp_text !~ /\{\{disambig/i) {
				$done{$entry} = 'no_dismabig_on_disambigR';
				next;
			}
		}
		
		if ($wp_text =~ /\{\{((w|W)ikisłownik|(w|W)wiktionary)/) {
			$done{$entry} = 'already_has';
			next;
		} else {
			$done{$entry} = "candidate_${wp_addr}";
			#print encode_utf8($wp_text."\n");
			
			sleep 1;
			
			next;
		}
	} else {
		$done{$entry} = 'no_disambig';
		next;
	}
}

save_results();

sub save_results() {
	save_hash($donefile,\%done);
}