#!/usr/bin/perl

use strict;
use utf8;

# wyszukuje i usuwa w rosyjskim linki po lewej stronie

use Derbeth::Wikitools;
use Derbeth::Wiktionary;
use Derbeth::Util;
use Perlwikipedia;
use Encode;

# ===== ustawienia

Derbeth::Web::enable_caching(1);

my %settings = load_hash('settings.ini');
my $user = $settings{bot_login};
my $pass = $settings{bot_password};
my $wiki = 'localhost/~piotr/'; #'pl.wiktionary.org';
my $prefix = 'plwikt'; #'w';
my $donefile = "done/done_rusacc.txt";

my $server = "http://$wiki/$prefix/";
my $NOTENOUGH = 'not_enough';

my %done; # 'polski' => 432.56
my $length_sum;
my $articles;

# ===== subs

sub fix_accent {
	my $text = shift  @_;
	while($text =~ s/\[\[(([^\]|]+)\x{0301}([^\]|]*))\]\]/[[$2$3|$1]]/xg) {}
	while($text =~ s/\[\[([^\]|]+)\x{0301}([^\]|]*)\|/[[$1$2|/xg) {}
	#$text =~ s/(́)/fsdjfdaskl/xg;
	#$text =~ s/\x{0301}/fsjdklfsld/xg;
	#$text =~ s/а/fjskldlfsd/xg;
	#$text =~ s/\[/TT/g;
	
	#$text = 'ddd';
	
	#print encode_utf8($text);
	
	return $text;	
}

sub has_wrong_accent {
	my $text = shift @_;
	my $text_mod = fix_accent($text);
	return ($text ne $text_mod) ? 1 : 0;
}

if (1) { # test
	my $text = text_from_file('in.txt');
	#print encode_utf8($text), "\n";
	print STDERR has_wrong_accent($text), "\n";
	print encode_utf8(fix_accent($text));
	exit;
}


# ===== start

read_hash_loose($donefile, \%done);

if (0) { # edit
	print STDERR "editing ", scalar(keys(%done)), "\n";
	my $editor=Perlwikipedia->new($user);
	$editor->set_wiki("pl.wiktionary.org",'w');
	$editor->login($user, $pass);
	
	while (my($article,$status) = each(%done)) {
		next if ($status ne 'wrong');
		
		my $text = $editor->get_text($article);
		if ($text !~ /\w/) {
			print STDERR encode_utf8("no article: $article\n");
			die;
		}
		
		my $initial_summary = initial_cosmetics('pl',\$text);
		my ($before, $section, $after) = split_article_plwikt('język rosyjski',$text);
		if ($section !~ /\w/) {
			print STDERR encode_utf8("no section: $article\n");
			die;
		}
		unless (has_wrong_accent($section)) {
			print STDERR encode_utf8("all ok: $article\n");
			next;
		}
		$section = fix_accent($section);
		$text = $before.$section.$after;
		
		my $edit_summary = 'usunięcie apostrofów psujących linki w rosyjskim';
		my $final_cosm_summary = final_cosmetics('pl', \$text);
		$edit_summary .= '; '.$initial_summary if ($initial_summary);
		$edit_summary .= '; '.$final_cosm_summary if ($final_cosm_summary);
		
		my $response = $editor->edit($article, $text, $edit_summary, 1);
		if($response) {
			print STDERR encode_utf8("fixed: $article\n");
		} else {
			print STDERR encode_utf8("edit problem: $article\n");
		}
		#exit;
	}
	exit;
}

$SIG{INT} = $SIG{TERM} = $SIG{QUIT} = sub {
	save_results();
	exit;
};

# ==== main

my @articles_in_lang = get_category_contents($server, "Kategoria:rosyjski (indeks)");
my $lang_articles_count = scalar(@articles_in_lang);

$articles = 0;
	
foreach my $article (@articles_in_lang) {
	if ($articles % 250 == 0) {
		print STDERR encode_utf8("$articles/$lang_articles_count\n");
	}
	
	if (exists $done{$article}) {
		next;
	}
	
	my $text = get_wikicode($server,$article);
	if ($text !~ /\w/) {
		print STDERR encode_utf8("no article: $article\n");
		die;
	}
	
	my ($before, $section, $after) = split_article_plwikt('język rosyjski',$text);
	if ($section !~ /\w/) {
		print STDERR encode_utf8("no section: $article\n");
		print encode_utf8("$before\n===\n$section\n===$after");
		save_results();
		die;
	}
	
	$done{$article} = has_wrong_accent($section) ? 'wrong' : 'ok';	
} continue {
	++$articles;
}

save_results();

sub save_results {
	save_hash($donefile, \%done);
}

	