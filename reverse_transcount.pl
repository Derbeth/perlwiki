#!/usr/bin/perl

# liczy liczbę tłumaczeń podanych w sekcji tłumaczenia

use strict;
use utf8;

use Derbeth::Wikitools;
use Derbeth::Wiktionary;
use Derbeth::Util;
use Encode;

Derbeth::Web::enable_caching(1);

my %settings = load_hash('settings.ini');
my $user = $settings{bot_login};
my $pass = $settings{bot_password};
my $wiki = 'localhost/~piotr/'; #'pl.wiktionary.org';
my $prefix = 'plwikt'; #'w';
my @categories = (
	'Kategoria:polski (indeks)'
);
my $MAX_COUNT = 200000;
my $REPORT_EVERY = 200;

my $server = "http://$wiki/$prefix/";

my @articles;
#@articles=('piwo','wódka','myśleć');
foreach my $category (@categories) {
	my @contents = get_category_contents($server,$category);
	print encode_utf8($category),' - ',scalar(@contents)," pages\n";
	push @articles, @contents;
}

my $count=0;

# language => word => 1
my %tran = ();
# language => polish articles with translation
my %reverse_count = ();
# language => number of entries
my %word_count = ();
# language => one or two words in this language
my %example_words;

$SIG{INT} = $SIG{TERM} = $SIG{QUIT} = sub { save_results(); exit; };

sub remember_word {
	my ($lang,$polish_art,$word) = @_;
	if ($reverse_count{$lang} > 2) {
		delete $example_words{$lang};
		return;
	}
	my $entry = "$word ($polish_art)";
	if (exists($example_words{$lang})) {
		$example_words{$lang} .= ', ' . $entry;
	} else {
		$example_words{$lang} = $entry;
	}
}

foreach my $article (@articles) {
	if (++$count % $REPORT_EVERY == 0) { print STDERR $count,"\n"; }
	last if($count > $MAX_COUNT);
	
	if (should_not_be_in_category_plwikt($article)) {
		print 'should not be here: ', encode_utf8($article), "\n";
		next;
	}
	
	my $text=get_wikicode($server,$article);
	
	my($before,$section,$after) = split_article_wikt('pl','język polski',$text);
	
	if ($section !~ /\w/) {
		print ">>>>$section<<<<\n";
		print "error on article ",encode_utf8($article);
	}
	
	if ($section =~ /.*{{tłumaczenia}}/s) {
		$section = $';
	} else {
		if ($section !~ /\{\{aspekt dok/) {
			print 'missing tlumaczenia: ',encode_utf8($article),"\n";
		}
		next;
	}
	my @lines = split /\n/, $section;
	foreach my $line (@lines) {
		next if ($line !~ /\w/ || $line =~ /zobtlum|zobtłum/);
		if ($line =~ /\*\s*([^ :]+)/) {
			$line = $';
			my $lang = $1;
			$lang =~ s/^\s+|\s+$//g;
			if (!exists($tran{$lang})) {
				$tran{$lang} = {};
			}
			if (!exists($reverse_count{$lang})) {
				$reverse_count{$lang} = 0;
			}
			++$reverse_count{$lang};
			
			while ($line =~ /\[\[([^\]]+)\]\]/g) {
				my $translation = $1;
				
				$translation =~ s/.*\|//; # [[#a (b)|a]] -> a
				
				$translation =~ s/^\s+|\s+$//g;
				next if ($translation eq '');
				$tran{$lang}{$translation} = 1;
				remember_word($lang, $article, $translation);
			}
			
		} else {
			print "no match in ",encode_utf8($article),": ";
			print encode_utf8($line),"\n";
		}
	}
	
}
save_results();

sub save_results {
	print STDERR "printing results\n";

	print "\nDziwne jezyki:\n";
	foreach my $lang (sort(keys(%example_words))) {
		my $words = $example_words{$lang};
		print encode_utf8("$lang: $words\n");
	}
	
	print STDERR "reading categories\n";

	foreach my $language(keys(%tran)) {
		my $index = "Kategoria:$language (indeks)";
		my @contents = get_category_contents($server,$index);
		$word_count{$language} = scalar(@contents);
	}
	
	print STDERR "sorting\n";
	
	my @languages = sort {
		my $c1 = $reverse_count{$a} + $word_count{$a};
		my $c2 = $reverse_count{$b} + $word_count{$b};
		if ($c1 != $c2) {
			return $c2 <=> $c1;
		} else {
			return $a cmp $b;
		}
	}
	keys(%tran);
	
	print "\n{| class=\"wikitable sortable\"\n";
	print encode_utf8("! Język !! Słów w tłumaczeniach !! Haseł polski -> X !! Haseł X -> polski !! Haseł w obie strony\n");
	foreach my $language (@languages) {
		print "|-\n| ";
		printf '%12s', encode_utf8($language);
		print ' || ';
		printf '%4s', scalar(keys(%{$tran{$language}}));
		print ' || ';
		printf '%4s', $reverse_count{$language};
		print ' || ';
		printf '%4s', $word_count{$language};
		print ' || ';
		printf '%4s', $reverse_count{$language} + $word_count{$language};
		#foreach my $word (sort keys(%{$tran{$language}})) {
		#	print '[',encode_utf8($word),'], ';
		#}
		print "\n";
	}
	print "|}\n";
	
}
