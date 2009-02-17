#!/usr/bin/perl
use strict;
use utf8;

use Perlwikipedia;
use Derbeth::Wikitools;
use Derbeth::Util;
use Encode;

my %settings = load_hash('settings.ini');
my $user = $settings{bot_login};
my $pass = $settings{bot_password};
my $wiki = 'localhost/~piotr/'; #'pl.wiktionary.org';
my $prefix = 'plwikt'; #'w';
my @categories = (
	'polski (indeks)'
);
my $edit_summary = 'poprawa linku do dolnołużyckiej Wikipedii';

#unlink($donfile);

$edit_summary = encode_utf8($edit_summary);
my $server = "http://$wiki/$prefix/";

my $editor=Perlwikipedia->new($user);
$editor->set_wiki($wiki,$prefix);

$editor->login($user,$pass);

print $editor->get_text('kot');

print "start\n";


my @articles;
# @articles=('foo');
foreach my $category (@categories) {
	#my @contents = get_category_contents($server,"$category");
	my @contents = $editor->get_pages_in_category($category);
	print encode_utf8($category),' - ',scalar(@contents)," pages\n";
	push @articles, @contents;
}
exit;

my $count=0;

foreach my $article (@articles) {
	my $text = get_wikicode($article);
	#my $text = $editor->get_text($article);
	last if (++$count > 800);
}