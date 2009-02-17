#!/usr/bin/perl

use strict;

use Perlwikipedia;
use Derbeth::Wikitools;
use Encode;

# Scans IPA from a wiki and stores it in ipa_de.txt

my %ipa;

my $language='Deutsch';
my $outfile='w_ipa_de.txt';

my $donefile='de_scanner_done.txt';
my %done; # skip_word => 1

open(DONE,$donefile);

while(<DONE>) {
	chomp;
	$done{decode_utf8($_)} =1;
}

close(DONE);

my $user = ''; my $pass = '';
my $editor=Perlwikipedia->new($user);
#$editor->{debug} = 1;
$editor->set_wiki('localhost/~piotr','dewikt');
$editor->login($user, $pass);

my $count=0;

#my @foo = $editor->get_pages_in_category("Category:Deutsch");
#print "size: $#foo\n";
#exit(0);

my $server='http://localhost/~piotr/dewikt/';
my $category="Kategorie:$language";
my @pages=get_category_contents($server,$category);

foreach my $page (@pages) {
	#print "$page\n";
	
	if (exists $done{$page}) {
		print encode_utf8($page).": already done\n";
		next;
	}
	$done{$page} = 1;
	
	#sleep 5;
	
	my $page_text = $editor->get_text($page);
	if ($page_text !~ /\w/) {
		print "entry does not exist: ".encode_utf8($page)."\n";
		next;
	}
	
	my($before,$section,$after) = split_article_dewikt($language,$page_text);
	
	if ($section eq '') {
		print "no $language section: ".encode_utf8($page)."\n";
		next;
	}
	
	# ===== section processing =======
	
	if ($section !~ /{{Lautschrift\|[^.]/) {
		print encode_utf8($page).": no IPA\n";
		next;
	}
	
	++$count;
	
	print encode_utf8($page).": has IPA\n";
	
	if ($section =~ /:\[\[Hilfe:IPA\|IPA\]\]:\s+{{Lautschrift\|([^.}]+)}},\s+{{Pl\.}}\s+{{Lautschrift\|([^}]+)}}/) {
		$ipa{$page} = "$1|$2";
	}
	elsif ($section =~ /:\[\[Hilfe:IPA\|IPA\]\]:\s+{{Lautschrift\|([^}]+)}},/) {
		$ipa{$page} = $1;
	}
	
	if ($count > 1000) {
		print "finished\n";
		last;
	}
}

open(OUT,">>$outfile");

while (my($page,$pron) = each(%ipa)) {
	print OUT encode_utf8($page).'='.encode_utf8($pron)."\n";
}

close(OUT);

open(DONE,">$donefile");
foreach my $done_word (keys %done) {
	print DONE encode_utf8($done_word)."\n";
}
close(DONE);
