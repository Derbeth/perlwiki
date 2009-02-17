#!/usr/bin/perl

use strict;
use Encode;
use Derbeth::Wikitools;
use Perlwikipedia;

use utf8;

my $infile='ipa_el.txt';
my $outfile='enwikt_'.$infile;

my $language='Greek';

my %ipa;

open(IPA,$infile);

while(my $line=<IPA>) {
	chomp $line;
	$line=decode_utf8($line);
	
	if ($line=~/([^=]+)=(.+)/) {
		$ipa{$1} = $2;
	} else {
		#print "no match '".encode_utf8($line)."'!\n";
	}
}

close(IPA);

my %ipa_copy=%ipa;


my $user = ''; my $pass = '';
my $editor=Perlwikipedia->new($user);
#$editor->{debug} = 1;
$editor->set_wiki('localhost/~piotr','enwikt');
$editor->login($user, $pass);

while (my($word,$pron) = each(%ipa_copy)) {
	
	my $page_text = $editor->get_text($word);
	if ($page_text !~ /\w/) {
		print "entry does not exist: ".encode_utf8($word)."\n";
		delete $ipa{$word};
		next;
	}
	my($before,$section,$after) = split_article_enwikt($language,$page_text);
	
	if ($section eq '') {
		print "no language section: ".encode_utf8($word)."\n";
		delete $ipa{$word};
		next;
	}
	if ($section =~ /IPA/) {
		print encode_utf8($word).": has IPA\n";
		delete $ipa{$word};
		next;
	}
	print encode_utf8($word).": to add IPA\n";
}
close(IN);

open(OUT,">$outfile") or die "cannot write to file";

while (my($word,$pron) = each(%ipa)) {
	print OUT encode_utf8($word).'='.encode_utf8($pron)."\n";
}

close(OUT);
