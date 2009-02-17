#!/usr/bin/perl
use strict;
use utf8;

use Perlwikipedia;
use Derbeth::Wikitools;
use Derbeth::Util;
use Derbeth::Wiktionary;
use Encode;

my %settings = load_hash('settings.ini');
my $user = $settings{bot_login};
my $pass = $settings{bot_password};
my $wiki = 'pl.wiktionary.org';
my $prefix = 'w';
my @categories = (
	'Kategoria:islandzki (indeks)'
);
my $edit_summary = '{{zf}} -> "związek frazeologiczny"';

my $donefile='done/done_isl.txt';
Derbeth::Web::enable_caching(0);
#unlink($donfile);

my $server = "http://$wiki/$prefix/";

my $editor=Perlwikipedia->new($user);
$editor->set_wiki($wiki,$prefix);

$editor->login($user,$pass);

my @articles;
# @articles=('foo');
#foreach my $category (@categories) {
#	my @contents = get_category_contents($server,$category);
#	print encode_utf8($category),' - ',scalar(@contents)," pages\n";
#	push @articles, @contents;
#}

#@articles = get_linking_to($server, 'Szablon:dawn',1);
@articles = $editor->what_links_here('Szablon:zf');

print scalar(@articles), " articles\n";

my %done;
read_hash_loose($donefile,\%done);

$SIG{INT} = $SIG{TERM} = $SIG{QUIT} = sub { save_results(); exit; };

my $count=0;

foreach my $a (@articles) {
	my $article = $a->{'title'};
	if (++$count % 200 == 0) { print $count,"\n"; }
	
	if ($article =~ /^(Kategoria|Wikipedysta|Dyskusja)/ || exists($done{$article})) {
		next;
	}
	
	my $text=$editor->get_text($article);
	
	#my($before,$section,$after) = split_article_wikt('pl','język islandzki',$text);
	
	if ($text !~ /\w/) {
		save_results();
		print ">>>>$text<<<<\n";
		die "error on article ",encode_utf8($article);
	}
	
	my $initial_summary = initial_cosmetics('pl',\$text);
	$edit_summary .= ' '.$initial_summary if ($initial_summary);
	
	unless ($text =~ s/\{\{zf\}\}/związek frazeologiczny/g) {
		print encode_utf8("$article: no edit\n");
		next;
	}
	
	$done{$article} = 'none';

		print encode_utf8($article);
		print ' ', encode_utf8($edit_summary);
		print "\n"; 
		
		$editor->edit($article, $text, $edit_summary, 1);
		#last if (++$count > 5);
			
		sleep 1;
	
}


save_results();
 
sub save_results() {
	save_hash($donefile, \%done);
}
