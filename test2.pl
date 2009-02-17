#!/usr/bin/perl
use strict;

use Perlwikipedia;
use Encode;
use Derbeth::Wikitools;

use utf8;

my $user=''; my $pass='';
my $editor=Perlwikipedia->new($user);
$editor->set_wiki('localhost/~piotr','plwikt');
$editor->{debug} = 1;
$editor->login($user, $pass);

my $article = "Katze";

my $lang = 'język niemiecki';

my $text=$editor->get_text($article);

my ($before, $section, $after) = split_article_plwikt($lang,$text);

# ==

$text = $before.$section.$after;
	
	($before,$after) = split_before_sections($text);

	$before =~ s/(z|Z)obacz (też|także):?\s+\[\[([^\]]+)\]\]\s*\n/{{zobteż|$3}}\n/;
	$before =~ s/(\n|\r|\f)+({{zobteż[^}]+}})(\n|\r|\f)+/$1$2$3/;
$before =~ s/(\n|\r|\f){2,}$/$1/;
	
	$text = $before.$after;
	
	$text =~ s/ ''w''/ {{w}}/g;
	$text =~ s/(\n|\r|\f){3}/$1$1/g;
	$text =~ s/<!-- \[\[Aneks:IPA\|(IPA)?\]\]:.*?-->//;
	$text =~ s/\[\[Aneks:IPA\|(IPA)?\]\]: \/ \///;

my $edit_summary='zobtez';
my $is_minor = 0;
$editor->edit($article, $text, $edit_summary, $is_minor);
