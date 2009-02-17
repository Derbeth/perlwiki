#!/usr/bin/perl

use strict;
use utf8;

use Derbeth::Wikitools;
use Derbeth::Util;
use Perlwikipedia;
use Encode;

my %done;

my $server='http://localhost/~piotr/plwikt/';
my $donefile='done/done_equadus.txt';

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
foreach my $entry (keys(%done)) {
	if (++$count > 20000) {
		print "interrupted\n";
		last;
	}
	if ($count % 200 == 0) {
		print "$count\n";
	}
	
	if (exists($done{$entry}) && $done{$entry} ne 'unknown') {
		next;
	}
	
	my $text = get_wikicode($server,$entry);
	
	my($before,$section,$after) = split_article_wikt('pl','język polski',$text);
	
	if ($section !~ /\w/) {
		save_results();
		die 'no text: '.encode_utf8($entry);
	}
	
	$section =~ /\{\{wymowa\}\}(.*)/;
	my $wymowa = $1;
	if ($wymowa =~ /\{\{audio/ || $section =~ /^''skrót''/m) {
		$done{$entry} = 'has audio';
	} else {
		$done{$entry} = 'no audio';
	}	
}

save_results();

sub save_results() {
	save_hash($donefile,\%done);
}

