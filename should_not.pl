#!/usr/bin/perl

# should not be here - checks if pages from namespace other than main
# appear in categories

use strict;
use utf8;

use Perlwikipedia;
use Derbeth::Wikitools;
use Derbeth::Wiktionary;
use Derbeth::Util;
use Encode;

my $user = 'DerbethBot';
my $wiki = 'localhost/~piotr/'; #'pl.wiktionary.org';
my $prefix = 'plwikt'; #'w';
my $donefile='done/done_should_not.txt';

my $server = "http://$wiki/$prefix/";

#my @langs = $editor->get_all_pages_in_category('Indeks słów wg języków');
my @langs = get_category_contents($server,'Kategoria:Indeks słów wg języków',undef,{'main'=>0,'category'=>1});
print scalar(@langs), " languages\n";

foreach my $lang (@langs) {
	if ($lang !~ /Kategoria:/) {
		next;
	}
	
	my @articles = get_category_contents($server,$lang,undef,{'all'=>1});
	print encode_utf8("$lang: "),scalar(@articles)," articles\n";
	
	foreach my $article (@articles) {
		if (should_not_be_in_category_plwikt($article)) {
			print encode_utf8("* [[$article]]\n");
		}
	}
	
}

