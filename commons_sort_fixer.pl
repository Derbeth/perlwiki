#!/usr/bin/perl

use strict;
use utf8;
use Encode;
use Derbeth::Util;
use Derbeth::Wikitools;
use MediaWiki::Bot 3.3.1;
use POSIX 'islower';

my $server='http://commons.wikimedia.org/w/';
my $category="Category:Romansh pronunciation";
my @pages=get_category_contents($server,$category);

print "$category: ", scalar(@pages), " pages\n";

my %settings = load_hash('settings.ini');
my $user = $settings{bot_login};
my $pass = $settings{bot_password};
my $debug = 0;
# $debug = 1;
my $editor = MediaWiki::Bot->new({
	assert => 'bot',
	host => 'commons.wikimedia.org',
	debug => $debug,
	login_data => {'username' => $user, 'password' => $pass}
});

foreach my $page (@pages) {
	if ($page =~ /^File:(?:Roh-sursilvan \(Breil\)|Roh-sursilvan|Roh)-(.+)\.ogg$/i) {
		my $sort=$1;
		my $text=$editor->get_text($page);
		if ($text =~ s/\[\[$category\]\]/\[\[$category|$sort\]\]/) {
			print encode_utf8("sorted $page as '$sort'\n");
			$editor->edit($page, $text, 'category sorting', 1);
			sleep 3;
		} else {
			print encode_utf8("probably sorted: $page\n");
		}
	} else {
		print encode_utf8("ignored because of wrong name: $page\n");
	}
}
