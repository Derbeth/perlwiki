#!/usr/bin/perl
use strict;
use utf8;

use Perlwikipedia;
use Derbeth::Wikitools;
use Derbeth::Util;
use Derbeth::Wiktionary;
use Derbeth::Testeditor;
use Encode;

my %settings = load_hash('settings.ini');
my $user = $settings{bot_login};
my $pass = $settings{bot_password};
my $wiki = 'localhost/~piotr'; #'pl.wiktionary.org';
my $prefix = 'plwikt'; #'w';
my @categories = (
	'Kategoria:rosyjski (indeks)'
);

my $donefile='done/done_hyphen.txt';
Derbeth::Web::enable_caching(0);
my $server = "http://$wiki/$prefix/";

my $editor=Perlwikipedia->new($user);
#my $editor=Derbeth::Testeditor->new('in.txt', 'out.txt', $user);
$editor->set_wiki($wiki,$prefix);
$editor->login($user,$pass);

my %done;
read_hash_loose($donefile,\%done);

my @articles;
# @articles=('foo');
# foreach my $category (@categories) {
# 	my @contents = get_category_contents($server,$category);
# 	print encode_utf8($category),' - ',scalar(@contents)," pages\n";
# 	push @articles, @contents;
# }
while (my($key,$val) = each(%done)) {
	if ($val eq 'fixed') {
		push @articles, $key;
	}
}

print scalar(@articles), " articles\n";
$SIG{INT} = $SIG{TERM} = $SIG{QUIT} = sub { save_results(); exit; };

my $count=0;

foreach my $article (@articles) {
	if (++$count % 200 == 0) { print $count,"\n"; }
	
	#next if ($done{$article});
	
	my $text=$editor->get_text($article);
	
	if ($text !~ /\w/) {
		save_results();
		print ">>>>$text<<<<\n";
		die "error on article ",encode_utf8($article);
	}
	
	my $initial_summary = initial_cosmetics('pl',\$text);
	
	if ($text !~ /(?<!!)--(?!>)/) {
		$done{$article} = 'nothing_to_do';
		next;
	}
	
	$text =~ s/(?<!!)--(?!>)/–/g or die $article;
	my $final_summary = final_cosmetics('pl', \$text);
	
	my $edit_summary = 'zamiana podw. łącznika na półpauzę';
	$edit_summary .= ', '.$initial_summary if ($initial_summary);
	$edit_summary .= ', '.$final_summary   if ($final_summary);
	
	unless ($editor->edit($article, $text, $edit_summary, 1)) {
		print "crash: >>$article<<\n";
		save_results();
		die;
	}
	
	print encode_utf8("$article: $edit_summary\n");
	
	$done{$article} = 'fixed';
}

save_results();
 
sub save_results() {
	save_hash($donefile, \%done);
}
