#!/usr/bin/perl -w

use strict;
use utf8;
use Encode;
use Derbeth::Util;
use Derbeth::Web;
use Derbeth::Wikitools;
use MediaWiki::Bot 3.3.1;
use POSIX 'islower';

my $server='http://commons.wikimedia.org/w/';
my $category="Category:German pronunciation";
my $from='';
$from='filefrom=D';
Derbeth::Web::enable_caching(1);

my @pages=get_category_contents($server,$category,undef,undef,$from);

print "$category: ", scalar(@pages), " pages\n";

my %settings = load_hash('settings.ini');
my $debug = 0;
# $debug = 1;
my $editor = MediaWiki::Bot->new({
	assert => 'bot',
	host => 'commons.wikimedia.org',
	debug => $debug,
	login_data => {'username' => $settings{bot_login}, 'password' => $settings{bot_password}},
	operator => $settings{bot_operator},
});

foreach my $page (@pages) {
	if ($page =~ /^(?:File|Image):(?:De-(.+))\.ogg$/i) {
		my $sort=$1;
		my $text=$editor->get_text($page);

		if ($text !~ /DEFAULTSORT/
		&& $text =~ s/\[\[(Category:German pronunciation)\]\]/\[\[$1|$sort\]\]/) {
			print encode_utf8("sorted $page as '$sort'\n");
			$editor->edit({page=>$page, text=>$text, summary=>'category sorting',
				bot=>1});
			sleep 3;
		} else {
			print encode_utf8("probably sorted: $page\n");
		}
	} else {
		print encode_utf8("ignored because of wrong name: $page\n");
	}
}
