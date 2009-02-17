#!/usr/bin/perl

# dsb,hsb,ru,be,is,el,bg,fr,en,fi,nb,de,yi,hr,it,da,es,hi

use strict;
use utf8;

use Encode;
use Derbeth::Wikitools;
use Derbeth::Wiktionary;
use Derbeth::Util;
use Derbeth::I18n;
use Perlwikipedia;
use Getopt::Long;

my $langs='de,dsb';

GetOptions('l|lang=s'=>\$langs);

my @lang_codes = split /,/, $langs;

my %done;
my %polish_entries;

my $server='http://localhost/~piotr/plwikt/';
my $donefile='done_nottranslated.txt';

read_hash_loose($donefile,\%done);

$SIG{INT} = $SIG{TERM} = $SIG{QUIT} = sub { save_results(); exit; };

{
	my @polish = get_category_contents($server,'Kategoria:polski (indeks)');
	print scalar(@polish), " Polish entries\n";
	foreach my $pol (@polish) {
		$polish_entries{$pol} = 1;
	}
}

my $ONLY_MAIN_NS=1;

#my $user=''; my $pass='';
#my $editor=Perlwikipedia->new($user);
#$editor->set_wiki('localhost/~piotr', 'plwikt');
#$editor->login($user, $pass);

foreach my $lang_code (@lang_codes) {
	
	my $language = get_language_name('pl', $lang_code);
	$language =~ s/język //g;
	
	my @other_lang = get_category_contents($server,"Kategoria:$language (indeks)");
	print scalar (@other_lang), encode_utf8(" entries in $language\n");
	
	my $counter=0;
	foreach my $other_entry (@other_lang) {
		if (++$counter % 100 == 0) { print $counter,"\n"; }
		
		if (is_done($lang_code,$other_entry)) {
			next;
		}
		
		# entry has Polish and other part
		if (exists($polish_entries{$other_entry})) {
			if (links_to($other_entry, $language)) {
				mark_done($lang_code, $other_entry, 'linked');
				next;
			}
		}
		
		my @linking = get_linking_to($server, $other_entry, $ONLY_MAIN_NS);
		
		if ($#linking == -1) {
			mark_done($lang_code, $other_entry, 'not_linked');
			next;
		}
		
		my $any_polish=0;
		foreach my $link (@linking) {
			if (exists($polish_entries{$link})) {
				$any_polish=1;
				
				if (links_to($link, $language)) {
					mark_done($lang_code, $other_entry, 'linked');
					last;
				}
			}
		}
		
		if (is_done($lang_code, $other_entry)) {
			next;
		}
		
		if ($#linking >= 0 && $any_polish) {
			mark_done($lang_code, $other_entry,
				'not_linked_to_this_language');
		}
		
		if (is_done($lang_code, $other_entry)) {
			next;
		}
		
		mark_done($lang_code, $other_entry, 'not_linked_from_Polish');
		
		#sleep 0.3;
	}
	
	save_results();
}

sub links_to() {
	my ($entry, $lang) = @_;
	my $polish_text = get_wikicode($server,$entry);
	if ($polish_text !~ /\w/) {
		print encode_utf8("$entry: fatal error!\n");
	}
	
	return ($polish_text =~ /\*\s*$lang\s*:/
	|| index($polish_text,$lang.':') != -1)
}

sub mark_done() {
	my ($lang_code,$word,$comment) = @_;
	$comment = 1 unless(defined($comment));
	
	$done{$lang_code.'-'.$word} = $comment;
}

sub is_done() {
	my ($lang_code,$word)=@_;
	return exists($done{$lang_code.'-'.$word});
}

sub save_results() {
	save_hash($donefile,\%done);
}
