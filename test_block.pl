#!/usr/bin/perl -w

use MediaWiki::Bot;
use Derbeth::Web;

my $wiki = 'pl.wikinews.org';

my $editor = new MediaWiki::Bot;
$editor->set_wiki($wiki);

my $ip=$ARGV[0];

print $editor->test_blocked($ip), "\n";
my $page = get_page("http://$wiki/w/index.php?title=Special%3AIpblocklist&uselang=en&ip=$ip");
my @parts = split (/bodyContent|visualClear/, $page);
$page = $parts[1];
$page =~ s/<[^>]+>//g;
$page =~ s/\s+/ /g;
print $page, "\n";

