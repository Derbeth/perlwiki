#!/usr/bin/perl

use utf8;
use strict;

use Perlwikipedia;
use Encode;
use Derbeth::Wiktionary;

open(IN,'jidysz_rtl.txt');
my @entries = <IN>;

my %settings = load_hash('settings.ini');
my $user = $settings{bot_login};
my $pass = $settings{bot_password};
my $editor=Perlwikipedia->new($user);
#$editor->set_wiki('localhost/~piotr', 'plwikt');
$editor->set_wiki('pl.wiktionary.org','w');
$editor->login($user, $pass);
$editor->{'debug'} = 0;

#@entries = (encode_utf8('אַכציקסט'));

foreach my $entry (@entries) {
	chomp $entry;
	$entry =~ s/^(\n|\r|\f)//g;
	$entry =~ s/(\n|\r|\f)$//g;
	
	$entry = decode_utf8($entry);
	#$entry = URI::Escape::uri_escape_utf8($entry);
	
	my $text = $editor->get_text($entry);
	if ($text eq '') {
		print encode_utf8($entry), ' does not exist',"\n";
		next;
	}
	
	my $inital_summary = initial_cosmetics('pl',\$text);
	unless ($text =~ s/\{\{ *rtl *\|(.*?)}}/$1&rlm;/g) {
		print encode_utf8($entry), " rtl not found\n";
		next;
	}
	my $final_summary = final_cosmetics('pl',\$text);
	
	my $summary = 'zamiana {{rtl}} na &rlm';
	$summary .= '; '.$inital_summary if ($inital_summary);
	$summary .= '; '.$final_summary if ($final_summary);
	
	$editor->edit($entry, $text, encode_utf8($summary), 1);
	
	print encode_utf8($entry), " fixed rtl\n";
}

