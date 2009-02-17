#!/usr/bin/perl

use strict;
use utf8;
use Encode;
use Derbeth::Wikitools;
use Perlwikipedia;
use POSIX 'islower';

my $server='http://commons.wikimedia.org/w/';
my $category="Category:Chinese pronunciation";
my @pages=get_category_contents($server,$category);

my %settings = load_hash('settings.ini');
my $user = $settings{bot_login};
my $pass = $settings{bot_password};
my $editor=Perlwikipedia->new($user);
$editor->set_wiki('commons.wikimedia.org','w');
#$editor->{debug} = 1;
$editor->login($user, $pass);

foreach my $page (@pages) {
	print encode_utf8($page)."\n";
	
	my $text=$editor->get_text($page);
	
	if ($page =~ /zh-(.*)\.ogg/i) {
		my $sort=$1;
		if ($text =~ s/\[\[$category\]\]/\[\[$category|$sort\]\]/) {
			$editor->edit($page, $text, 'category sorting', 1);
			sleep 3;
		}
	}
}
