#!/usr/bin/perl

use Perlwikipedia;
use Derbeth::Wikitools;
use Encode;

use strict;
use utf8;

my $language; 
$language = 'Deutsch';
my $donefile='done_de.txt';

my @words;

my %done; # skip_word => 1
my %ipa; # word => IPA without brackets

open(DONE,$donefile);

while(<DONE>) {
	chomp;
	$done{decode_utf8($_)} =1;
}

close(DONE);

open(IPA,'dewikt_ipa_de.txt');

while(my $line=<IPA>) {
	chomp $line;
	$line=decode_utf8($line);
	
	if ($line=~/([^=]+)=(.+)/) {
		$ipa{$1} = $2;
	} else {
		#print "no match '".encode_utf8($line)."'!\n";
	}
}

my $added=0;

my %settings = load_hash('settings.ini');
my $user = $settings{bot_login};
my $pass = $settings{bot_password};
my $editor=Perlwikipedia->new($user);
#$editor->{debug} = 1;
$editor->set_wiki('de.wiktionary.org','w');
$editor->login($user, $pass);

while (my($word,$pron) = each(%ipa)) {
	#print "'$word' => '$pron'\n";
	
	if (exists $done{$word}) {
		print encode_utf8($word).": already done\n";
		next;
	}
	$done{$word} = 1;
	
	sleep 5;
	
	my $page_text = $editor->get_text($word);
	if ($page_text !~ /\w/) {
		print "entry does not exist: ".encode_utf8($word)."\n";
		next;
	}
	
	my($before,$section,$after) = split_article_dewikt($language,$page_text);
	
	if ($section eq '') {
		print "no $language section: ".encode_utf8($word)."\n";
		next;
	}
	
	# ===== section processing =======
	
	if ($section =~ /{{Lautschrift\|[^.]/) {
		print encode_utf8($word).": has IPA\n";
		next;
	}
	
	++$added;
	
	if ($section !~ /{{Aussprache}}/) {
		print encode_utf8($word).": no pronunciation section\n";
		$section =~ s/{{Bedeutungen}}/{{Aussprache}}
:[[Hilfe:IPA|IPA]]: {{Lautschrift|...}}, {{Pl.}} {{Lautschrift|...}}
:[[Hilfe:Hörbeispiele|Hörbeispiele]]: {{fehlend}}, {{Pl.}} {{fehlend}}\n\n{{Bedeutungen}}/x;
	}
	if ($section !~ /:\[\[Hilfe:IPA\|IPA\]\]: {{Lautschrift/) {
		$section =~ s/{{Aussprache}}/{{Aussprache}}
:[[Hilfe:IPA|IPA]]: {{Lautschrift|...}}, {{Pl.}} {{Lautschrift|...}}/x;
	}
	if ($section =~ s/IPA\]\]: {{Lautschrift\|...}}/IPA]]: {{Lautschrift|$pron}}/) {
		print "added pronunciation: ".encode_utf8($word)." => "
			.encode_utf8($pron)."\n";
	} else {
		print "cannot add pronunciation to ".encode_utf8($word)."\n";
	}
	
	$page_text = $before.$section.$after;
	
	my $summary='IPA aus [[:en:Transwiki:German language/Swadesh list]]';
	#print "page text:".encode_utf8($page_text)."\n";
	#exit(0);
	$editor->edit($word, $page_text, $summary, 1);
	
	if ($added > 15) {
		print "finished\n";
		last;
	}
	
}

open(DONE,'>$donefile');
foreach my $done_word (keys %done) {
	print DONE encode_utf8($done_word)."\n";
}
close(DONE);
