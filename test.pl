#!/usr/bin/perl -w
use strict; # 'strict' insists that all variables be declared

use utf8;
use Encode;

use Derbeth::Wikitools;
use Derbeth::Wiktionary;
use Derbeth::I18n;
use Derbeth::Inflection;
use Derbeth::Util;
use Derbeth::Web;

#     WAŻNE!
#     do opisu zmian link do de.wikt gdy niezerowe ipa lub odmiana


my $user = 'DerbethBot';
my $wiki = 'localhost/~piotr/'; #'pl.wiktionary.org';
my $prefix = 'plwikt'; #'w';
my $donefile='done/done_should_not.txt';

my $server = 'http://localhost/~piotr/dewikt/';

#open(OUT,'>out.txt');

my $text = text_from_file('in.txt');

my $language = 'język rosyjski';

#my $initial_summary = initial_cosmetics('en',\$text);
my ($before, $section, $after) = split_article_plwikt($language,$text);

print length($section), "\n";
exit;

my @retval = add_audio('en',\$section,'foo.ogg',$language,0,'donot','donot.ogg','I1','I2');
print STDERR @retval, "\n";
print OUT encode_utf8($before.$section.$after);
close(OUT);
exit(0);

my $count = 0;
Derbeth::Web::enable_caching(1);
for my $article (get_category_contents($server,'Kategorie:Englisch')) {
++$count;
next if ($count < 2900);

$text = get_wikicode($server,$article);
initial_cosmetics('de',\$text);
my($before,$section,$after) = split_article_wikt('de','Englisch',$text);
#print encode_utf8(">>>$section<<<\n");
#exit;
foreach my $e (extract_en_inflection_dewikt($article,\$section)) {
	print "'",encode_utf8($e), "' / ";
}
print "\n";
last if (++$count > 2930);

}

exit;

# initial_cosmetics('pl',\$text);
# my ($before, $section, $after) = split_article_plwikt($language,$text);

#if ($section eq '') { die "no match"; }

#print "before:\n=====\n$before\n========\n";
#print "section:\n----++---\n".encode_utf8($section)."\n--++--\n";
#print "after:\n========\n$after\n=====\n";
#exit(0);

#print "jest" if ($section =~ /(==\s*$language\s*==(.|\n|\r|\f)*?)(==)/);
#print "wwoo" if ($section =~ /(==\s*$language\s*==)/);
#exit;

# my $pron = 'foo.ogg';
# my ($result,$audios_count,$edit_summary)
# 	= add_audio('en',\$section,$pron,$language,0);
# 
# $text = $before.$section.$after;
# 
# print STDERR encode_utf8("RESULT: $result $edit_summary\n");
# print OUT encode_utf8($text);

close(OUT);
`kdiff3 in.txt out.txt`

