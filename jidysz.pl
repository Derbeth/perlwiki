#!/usr/bin/perl

use strict;
use utf8;

use Derbeth::Wikitools;
use Perlwikipedia;
use Encode;

`rm -f jidysz_done.txt yi_reserv.txt  yi2a.txt`;
#`rm -f yi1.txt yi2.txt yi3.txt yi4.txt yi5.txt`;
#`rm -f  yi6.txt yi7.txt yi8.txt yi9.txt yi10.txt yi11.txt`;

my $donefile='jidysz_done.txt';
my %done; # skip_word => 1
open(DONE,$donefile);
while(<DONE>) {
	chomp;
	$done{decode_utf8($_)} =1;
}
close(DONE);

my $user = ''; my $pass = '';
my $editor=Perlwikipedia->new($user);
#$editor->{debug} = 1;
$editor->set_wiki('localhost/~piotr','plwikt');
$editor->login($user, $pass);

my $language='jidysz';

my $server='http://localhost/~piotr/plwikt/';
my $category="Kategoria:jidysz (indeks)";

#my @pages=get_category_contents($server,$category);
# 10 9
#my @pages=(
#	'פּרינץ',
#	'שנײַדער', 'ראָמאַנטיסט', 'ראָמאַנטיש'
#	);
my @pages;
open(IN,'yi2.txt');
while(<IN>) {
	$_=decode_utf8 $_;
	/\[\[(.*)\]\]/;
	push @pages, $1;
}
close(IN);

my $count=0;

open(OUT1,'>>yi1.txt');
open(OUT2,'>>yi2a.txt');
open(OUT3,'>>yi3.txt');
open(OUT4,'>>yi4.txt');
open(OUT5,'>>yi5a.txt');
open(OUT6,'>>yi6.txt');
open(OUT7,'>>yi7.txt');
open(OUT8,'>>yi8.txt');
open(OUT9,'>>yi9.txt');
open(OUT10,'>>yi10.txt');
open(OUT11,'>>yi11.txt');
open(RESERV,'>>yi_reserv.txt');

foreach my $page (@pages) {
	if (exists $done{$page}) {
		#print encode_utf8($page).": already done\n";
		next;
	}
	$done{$page} = 1;
	
	my $page_text = $editor->get_text($page);
	my($before,$section,$after) = split_article_plwikt($language,$page_text);

	# ===========
	
	my $inflection='';
	if ($section =~ /{{odmiana}}((.|\n|\r|\f)*){{przykłady}}/) {
		$inflection = $1;
		$inflection =~ s/\n|\r|\f/ /g;
	}
	my @inf_parts = split /\([0-9.]+\)/, $inflection;
	
	# 1
	
	#if ($section =~ /\S לפּ\s*==/) {
	#	print OUT1 '* [['.encode_utf8($page)."]]\n";
	#}
	
	# 2 przyklady
	if ($section =~ /{{przykłady}}((.|\n|\r|\f)*){{(składnia|kolokacje)}}/) {
		if ($1 =~ /:\s*\(.*\)(.*→.*)/) {
			my $example = $1;
			if ($example =~ /{{rtl/) {
				print RESERV '* [['.encode_utf8($page)."]]\n";
			} elsif ($example !~ /przykład.*tłumaczenie/ && $example =~ /[^'→ ]/) {
				print OUT2 '* [['.encode_utf8($page)."]]\n";
			}
		}
	}
	
	
	# 3 - po lp
	
	if ($section =~ /lp(}}|'')\s*-/) {
		print OUT3 '* [['.encode_utf8($page)."]]\n";
	}
	
	# 4 - po lm
	
	if ($section =~ /lm(}}|'')\s*-/) {
		print OUT4 '* [['.encode_utf8($page)."]]\n";
	}
	
	# 5 / w liczbie mnogiej
	
	foreach my $part (@inf_parts) {
		next unless ($part =~ /lm(}}|'')(.*)/);
		if (index($2,'/') != -1) {
			print OUT5 '* [['.encode_utf8($page)."]]\n";
		}
	}
	
	# 6 tylda w mnogiej
	
	if (index($section,'jidyszbot')==-1) {
		foreach my $part (@inf_parts) {
			next unless ($part =~ /lm(}}|'')(.*)/);
			if (index($2,'~') != -1) {
				print OUT6 '* [['.encode_utf8($page)."]]\n";
			}
		}
	}
	
	# 7 w liczbie mnogiej
	
	foreach my $part (@inf_parts) {
		next unless ($part =~ /lm(}}|'')(.*)/);
		if (index($2,'הות')
		!= -1) {
			print OUT7 '* [['.encode_utf8($page)."]]\n";
		}
	}
	
	# 8 IPA2
	
	if (index($section,'IPA2') != -1) {
		print OUT8 '* [['.encode_utf8($page)."]]\n";
	}
	
	# 9
	
	if ($section =~ /pokrewne}}.*קע\]\]/) {
		print OUT9 '* [['.encode_utf8($page)."]]\n";
	}
	
	# 10
	
	if ($section =~ /pokrewne}}.*ין\]\]/) {
		print OUT10 '* [['.encode_utf8($page)."]]\n";
	}
	
	# 11 spacje i myslniki w tytule
	
	if ($page =~ /[ -]/) {
		print OUT11 '* [['.encode_utf8($page)."]]\n";
	}
	
	# ===========
	
	if (++$count > 20000) {
		print "interrupted\n";
		last;
	}
}

close(OUT);

open(DONE,">$donefile");
foreach my $done_word (keys %done) {
	print DONE encode_utf8($done_word)."\n";
}
close(DONE);
