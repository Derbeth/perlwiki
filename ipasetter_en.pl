#!/usr/bin/perl

use Perlwikipedia;
use Derbeth::Wikitools;
use Encode;

use strict;
use utf8;

my $language; 
$language = 'Greek';

my @words;

my %done; # skip_word => 1
my %ipa; # word => IPA without brackets

open(DONE,'done_en.txt');

while(<DONE>) {
	chomp;
	$done{decode_utf8($_)} =1;
}

close(DONE);

open(IPA,'enwikt_ipa_el.txt');

while(my $line=<IPA>) {
	chomp $line;
	$line=decode_utf8($line);
	
	if ($line=~/([^=]+)=(.+)/) {
		$ipa{$1} = $2;
	} else {
		#print "no match '".encode_utf8($line)."'!\n";
	}
}

#while (my($word,$pron) = each(%ipa)) {
#	print "'".encode_utf8($word)."' => [".encode_utf8($pron)."]\n";
#}
#exit(0);

my $added=0;

my $user = 'DerbethBot'; my $pass = '';
my $editor=Perlwikipedia->new($user);
#$editor->{debug} = 1;
$editor->set_wiki('en.wiktionary.org','w');
$editor->login($user, $pass);

while (my($word,$pron) = each(%ipa)) {
	#print "'$word' => '$pron'\n";
	
	if (exists $done{$word}) {
		print encode_utf8($word).": already done\n";
		next;
	}
	$done{$word} = 1;
	
	sleep 3;
	
	my $page_text = $editor->get_text($word);
	if ($page_text !~ /\w/) {
		print "entry does not exist: ".encode_utf8($word)."\n";
		next;
	}
	
	my($before,$section,$after) = split_article_enwikt($language,$page_text);
	
	if ($section eq '') {
		print "no $language section: ".encode_utf8($word)."\n";
		next;
	}
	
	# ===== section processing =======
	
	if ($section =~ /IPA/) {
		print encode_utf8($word).": has IPA\n";
		next;
	}
	
	print "adding pronunciation: ".encode_utf8($word)." => "
		.encode_utf8($pron)."\n";
	
	++$added;
	
	if ($section !~ /===\s*Pronunciation\s*===/) {
		print encode_utf8($word).": no pronunciation section\n";
		
		if (0) {
		#if ($section =~ /===\s*Etymology\s*===/) {
			$section =~ s/===\s*Etymology\s*===/===Etymology===\n\n
===Pronunciation===\n/x;
		} else {
			$section =~ s/==\s*$language\s*==/==$language==\n
===Pronunciation===\n* {{IPA|[$pron]}}/x;
		}
	} else {
		$section =~ s/===\s*Pronunciation\s*===/===Pronunciation===\n* {{IPA|[$pron]}}/;
	}
	
	$page_text = $before.$section.$after;
	
	my $summary='IPA from [[Transwiki:Greek language/Swadesh list]]';
	#print "page text:".encode_utf8($page_text)."\n";
	#exit(0);
	$editor->edit($word, $page_text, $summary, 0);
	
	if ($added > 205) {
		print "finished\n";
		last;
	}
	
}

open(DONE,'>done_en.txt');
foreach my $done_word (keys %done) {
	print DONE encode_utf8($done_word)."\n";
}
close(DONE);
