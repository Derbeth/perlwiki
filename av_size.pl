#!/usr/bin/perl

use strict;
use utf8;

# hasło po 2 kroku obrazkowego kursu (testdata/av_size/nić1.txt): 285;
#       po końcu (nić2.txt): 568
# http://pl.wiktionary.org/w/index.php?title=demagogeria&oldid=487986 - 35

use Derbeth::Wikitools;
use Derbeth::Wiktionary;
use Derbeth::Util;
use Getopt::Long;
use Encode;

# ===== ustawienia

Derbeth::Web::enable_caching(1);

my %settings = load_hash('settings.ini');
my $user = $settings{bot_login};
my $pass = $settings{bot_password};
my $wiki = 'localhost/~piotr'; #'pl.wiktionary.org';
my $prefix = 'plwikt'; #'w';
my $donefile = "done/done_av_size.txt";

my $server = "http://$wiki/$prefix/";
my $NOTENOUGH = 'not_enough';

my %done; # 'polski' => 432.56
my $length_sum;
my $articles; # total number of articles in current language
my $with_audio; # total number of articles with audio file in current language

# ===== subs

sub strip_notfilled {
	my ($text) = @_;
	if ($text =~ /{{źródła}}/ && $' !~ /{{tłumaczenia}}/) {
		# źródła na samą górę
		#print STDERR "move!\n";
		$text = $&.$'.$`;
	}
	if ($text =~ /{{tłumaczenia}}/) {
		$text = $`;
	}
	$text =~ s/ {2,}/ /g;
	$text =~ s/\r\n/\n/g;
	$text =~ s/\r/\n/g;
	$text =~ s/\r\n/\n/g;
	
	
	$text =~ s/^==.+//m;
	$text =~ s/ ''(przym|rzecz|czas|przysł)\.'' / {{$1}} /g;
	
	$text =~ s/{{odmiana}} *\(1\.1\) *$//gm;
	$text =~ s/\{\{(trans|wymowa|czytania|znaczenia|odmiana|przykłady|składnia|kolokacje|synonimy|antonimy|złożenia|pokrewne|pochodne|frazeologia|etymologia|uwagi|źródła)[^}]*\}\} ?//g;
	$text =~ s/\{\{(do weryfikacji|dopracować|jidyszbot|TODO|ImportIA|ImportEO19)[^}]*\}\} *//gi;
	$text =~ s/ +$|^ +//gm;
	$text =~ s/(\<\!\-\-)?''(\[\[prosty\|)?Proste(\]\])? (\[\[)?zdanie(\]\])? (\[\[)?z(\]\])? (\[\[)?charakterystyczny(\]\])?m (\[\[)?użycie(\]\])?m ((''')|(\[\[słowo\|))?słowa((''')|(\]\]))?\.''( \→ (\[\[tłumaczenie\|)?Tłumaczenie(\]\])? (\[\[)?na(\]\])? (''')?polski(''')?\.)?(\-\-\>)?//g;
	$text =~ s/\:\s\((\d\.\d\))\s\[\[słowo\]\] \[\[po\]\] \[\[polski\|polsku\]\] \[\[lub\]\] \[\[definicja\]\]//g;
	$text =~ s/ *\[\[Aneks:IPA\|IPA\]\]: \/ *\/ *$//gm;
	$text =~ s/ *\<\!\-\- *(?:\[\[Aneks\:IPA\|[^\]\n]*\]\]|\{\{IPA[^\}\n]*\}\})[^\n]*\-\-\> *//g;
	$text =~ s/<!-- *-->//g;
	$text =~ s/ *\{\{IPA\|?\}\} *//g;
	$text =~ s/ ''przykład''( → tłumaczenie)?$//gm;
	$text =~ s/: *\(1\.\d\)( *('' *''\.?)? *)?→? *$//gm;
	$text =~ s/^: +\(/:(/gm;
	$text =~ s/^\* +/*/gm;
	$text =~ s/''rzeczownik, rodzaj żeński, męski''//g;
	$text =~ s/ st\. wyższy ; st\. najwyższy//g;
	$text =~ s/ ?''Uwaga: szablon wygenerowany automatycznie.*//gm;
	$text =~ s/ ?''Hasło zaimportowane automatycznie.*//gm;
	$text =~ s/ ?Hasło i jego pochodne zostały uzupełnione automatycznie.*//gm;
	$text =~ s/ \(\[\[pierwiastek]] \[\[chemiczny]] \[\[o]] \[\[symbol]]u.*//gm;
	$text =~ s/ \(\[\[wg]] \[\[kalendarz]]a \[\[gregoriański]]ego\)//gm;
	$text =~ s/#\S+ \([^)]+\)\|/|/g; # [[a#a (język polski)|a]] -> [[a|a]]
	$text =~ s/\|thumb\|right|\|right\|thumb/|thumb/g;
	$text =~ s/\[\[(plik|file|grafika|image):/[[Plik:/gi;
	
	$text =~ s/ +/ /g;	
	$text =~ s/(\s){2,}/$1/g;
	$text =~ s/\s+$|^\s+//g;
		
	return $text;
}

sub print_results {
	print <<END;
{| class="wikitable sortable" style="width:70%; margin: 0 auto;"
! miejsce !! język !! śr. długośc hasła !! liczba haseł
! „suma dł.” (w&nbsp;tys.) !! z nagraniem !! % z nagraniem
END
	my @filtered_langs;
	while (my ($lang,$note) = each(%done)) {
		unless ($note eq $NOTENOUGH) {
			push @filtered_langs, $lang;
		}
	}
	
	my @sorted_langs = sort {
		my $c1 = $done{$a}; my $c2 = $done{$b};
		$c1 =~ s/\|.*//;
		$c2 =~ s/\|.*//;
		if ($c1 != $c2) {
			return $c2 <=> $c1;
		} else {
			return $a cmp $b;
		}
	} @filtered_langs;
	
	my $place = 0;
	foreach my $lang (@sorted_langs) {
		++$place;
		my $lang_data = $done{$lang};
		my ($av,$with_a,$a_perc) = split /\|/, $lang_data;
		my $lang_entries = get_category_contents($server, "Kategoria:$lang (indeks)");
		my $lang_count = scalar($lang_entries);
		my $sum = $av * $lang_count;
		print  "|-\n| align=\"center\"| $place\n";
		print encode_utf8("| $lang\n");
		printf "| align=\"right\"| %.1f\n", $av;
		print  "| align=\"right\"| $lang_count\n";
		printf "| align=\"right\"| %d\n", ($sum/1000);
		print  "| align=\"right\"| $with_a\n";
		printf "| align=\"right\"| %.1f\n", ($a_perc*100);
	}
	print "|}\n";
}

my $count_only=0;
my $print_summary=0;
my $infile='in.txt';

GetOptions('c|count' => \$count_only, 's|summary' => \$print_summary,
	'i|infile=s' => \$infile,
);

if ($count_only) {
	my $text = text_from_file($infile);
	my $shorter = strip_notfilled($text);
	print encode_utf8($shorter);
	print STDERR "length: ",length($shorter),"\n";
	exit;
}

# ===== start

read_hash_loose($donefile, \%done);

if ($print_summary) {
	print_results();
	exit();
}

$SIG{INT} = $SIG{TERM} = $SIG{QUIT} = sub {
	print_progress();
	save_results(); exit;
};

# ==== main

my @indices = get_category_contents($server,'Kategoria:Indeks słów wg języków',undef,{'category'=>1});
# @indices = ('Kategoria:czeski (indeks)', 'Kategoria:holenderski (indeks)');
my $all_langs = scalar(@indices);
my $lang_count = 0;

foreach my $index (@indices) {
	#next if ($index =~ /angiels/);
	#next if ($index =~ /^Kategoria:[a]/);
	next if ($index =~ /użycie międzynarodowe|staropolski/);
	
	++$lang_count;
	print STDERR "languages: $lang_count/$all_langs\n" if ($lang_count % 10 == 0);
	
	$index =~ / \(indeks\)$/ or next; #die $index;
	my $lang = $`; # prematch
	$lang =~ s/^Kategoria://;
	if ($done{$lang}) {
		next;
	}
	my @articles_in_lang = get_category_contents($server, "$index");
	my $lang_articles_count = scalar(@articles_in_lang);
	
	if ($lang_articles_count < 250) {
		$done{$lang} = $NOTENOUGH;
		print STDERR encode_utf8("$lang: not enough ($lang_articles_count)\n");
		next;
	}
	
	my $errors = 0;
	$length_sum = 0;
	$articles = 0;
	$with_audio = 0;
	
	foreach my $article (@articles_in_lang) {
		if ($articles % 250 == 0) {
			print STDERR encode_utf8("$lang: $articles/$lang_articles_count ");
			print_progress();
		}
		
		my $text = get_wikicode($server,$article);
		if ($text !~ /\w/) {
			print STDERR encode_utf8("no article: $lang/$article\n");
			++$errors;
			next;
		}
		
		my ($before,$section,$after) = split_article_plwikt('język '.$lang,$text);
		if ($section !~ /\w/) {
			($before,$section,$after) = split_article_plwikt($lang,$text);
		}
		if ($section !~ /\w/) {
			print STDERR encode_utf8("no section: $lang/$article\n");
			++$errors;
			if($errors > 20) {
				print_progress();
				save_results();
				die;
			}
			next;
		}
		
		my $length = length(strip_notfilled($section));
		++$with_audio if ($section =~ /{{audio/);
		#print STDERR encode_utf8("$article: $length\n");
		
		++$articles;
		$length_sum += $length;
	}
	if($errors > 0) {
		if ($errors > 15) {
			print_progress();
			save_results();
			die "errors";
		} else {
			#next;
		}
	}
	
	$done{$lang} = ($length_sum / $articles).'|'.$with_audio.'|'.($with_audio/$articles);
	print STDERR encode_utf8("$lang: $done{$lang}\n");
	
	if ($lang_count >= 10000) {
		print STDERR "interrupted\n";
		last;
	}
}

save_results();

sub save_results {
	save_hash($donefile, \%done);
}

sub print_progress {
	print STDERR "at the moment: ", $length_sum/$articles, " ${with_audio}a" if($articles>0);
	print "\n";
}
