#!/usr/bin/perl

use strict;
use utf8;

use Encode;
use Derbeth::Wikitools;
use Derbeth::Wiktionary;
use Derbeth::Util;
use Derbeth::I18n;
use Perlwikipedia;
use Getopt::Long;

my $donefile='done_wyrazy.txt';

my $server='http://localhost/~piotr/plwikt/';
my $user='';
my $pass='';
my $language=get_language_name('pl','pl');

my %done;
read_hash_loose($donefile,\%done);

my $editor=Perlwikipedia->new($user);
$editor->set_wiki('localhost/~piotr', 'pl'.'wikt');
$editor->login($user, $pass);


my @polish = get_category_contents($server,'Kategoria:polski (indeks)');
print "all: ", scalar(@polish),"\n";

$SIG{INT} = $SIG{TERM} = $SIG{QUIT} = sub { save_results(); exit; };

my $counter=0;
foreach my $word (@polish) {
	++$counter;
	if ($counter % 250 == 0) { print $counter,"\n"; }
	if (length($word) != 5 && length($word) != 10
		&& length($word) != 4 && length($word) != 9
		&& length($word) != 8) {
		next;
	}
	
	my $page_text = $editor->get_text($word);
	my($before,$section,$after) = split_article_wikt('pl',$language,$page_text);
	
	if ($section !~ /\w/) {
		print "fatal error: ",encode_utf8($word), "\n";
		next;
	}
	if ($section !~ /''\s*rzeczownik/) {
		$done{$word} = 'nie_rzeczownik';
		next;
	}
	my $odmiana='';
	if ($section =~ /\{\{odmiana[^}]*\}\}(.*)/) {
		$odmiana = $1;
	}
	
	my $lm = get_liczba_mnoga($word,$odmiana);
	my $donetext = '';
	$donetext .= ",$word" if (length($word) == 5 || length($word) == 10);
	$donetext .= ",$lm" if ($lm ne '' && $lm ne $word && (length($lm) == 5 || length($lm) == 10));
	if ($donetext) {
		$donetext = "jest$donetext";
		$done{$word} = $donetext;
	} else {
		$done{$word} = 'zla_dlugosc';
	}
}
save_results();

sub save_results() {
	save_hash($donefile,\%done);
}

sub get_liczba_mnoga {
	my ($word,$odmiana)=@_;
	
	return '' unless ($odmiana);
	my $lp = $word;
	if ($odmiana =~ /({{lp}}|''lp'')\s+([^, ]+)/) {
		my $mian = $2;
		if ($mian =~ /([^|]+)\|/) {
			$lp = $1;
		}
	}
	
	my $lm='';
	if ($odmiana =~ /({{lm}}|''lm'')\s*([^, ]+)/) {
		#print "ofsjdklfsdl";
		$lm = $2;
		$lm =~ s/\|//g;
		$lm =~ s/~/$lp/;
	}
	return $lm;
}
