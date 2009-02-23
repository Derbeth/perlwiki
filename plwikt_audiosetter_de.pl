#!/usr/bin/perl

# MIT License
#
# Copyright (c) 2007 Derbeth
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

use Perlwikipedia;
use Derbeth::Wikitools;
use Derbeth::Wiktionary;
use Derbeth::I18n;
use Derbeth::Inflection;
use Derbeth::Util;
use Encode;

use strict;
use utf8;

# ========== settings

my $debug_mode=0;  # does not write anything to wiki, writes to
				   # $debug_file instead

my $page_limit=50000; # bot won't change more that x number of pages

my $lang_code='de';
#my $language=get_language_name('pl',$lang_code);

my %settings = load_hash('settings.ini');
my $user = $settings{bot_login};
my $pass = $settings{bot_password};

my $donefile = "done/done_plwikt_de.txt";
#`rm -f $donefile`;
my $debug_orig_file='in.txt';
my $debug_file='out.txt';
my $errors_file='errors_plwikt_de.txt';

# ============ end settings

my %done; # langcode-skip_word => 1
my %pronunciation; # 'word' => 'en-file.ogg|en-us-file.ogg<us>'

$SIG{INT} = $SIG{TERM} = $SIG{QUIT} = sub { save_results(); exit; };

read_hash_loose($donefile, \%done);

if ($debug_mode) {
	print "debug mode\n";
}

my $audio_filename='audio/audio_de.txt';
read_hash_strict($audio_filename, \%pronunciation);

my $visited_pages=0;
my $modified_pages=0;
my $added_files=0;

my $local_server = 'http://localhost/~piotr/dewikt/';

my $editor_remote;
if ($debug_mode) {
	$editor_remote=Perlwikipedia->new($user);
	$editor_remote->set_wiki('localhost/~piotr', 'plwikt');
	$editor_remote->login($user, $pass);
} else {

	$editor_remote=Perlwikipedia->new($user);
	$editor_remote->set_wiki('pl.wiktionary.org', 'w');
	$editor_remote->login($user, $pass);
}

if ($debug_mode) {
	open(DEBUG,">$debug_file");
	open(ORIG,">$debug_orig_file");
}

open(ERRORS,">>$errors_file");

# ==== main loop

my $server='http://localhost/~piotr/plwikt/';
my $category='Kategoria:niemiecki (indeks)';

my @entries = get_category_contents($server,$category); # REMOVE 2!!

my $word_count = scalar(@entries);
my $processed_words = 0;

print "$word_count words in category\n";

foreach my $word (@entries) {
	++$processed_words;
	print STDERR "$processed_words/$word_count\n" if ($processed_words % 200 == 0);
		
	if (is_done($word) && !$debug_mode) {
		print encode_utf8($word),": already done\n";
		next;
	}

	if (!exists($pronunciation{$word})) {
		#print encode_utf8("no pronunciation: $word\n");
		mark_done($word, 'no_pronunciation');
		next;
	}

	my $pron=$pronunciation{$word};
	my $pron_pl='';
	my ($inflection,$singular,$plural,$ipa_sing,$ipa_pl);
	
	{
		my $page_text_local = get_wikicode($local_server,$word);
		if ($page_text_local !~ /\w/) {
			print "entry does not exist: ",encode_utf8($word),"\n";
			mark_done($word, 'entry_does_not_exist');
			next;
		}
		
		initial_cosmetics('de',\$page_text_local);
		my($before_l,$section_l,$after_l) = split_article_wikt('de','Deutsch',$page_text_local);
		
		if ($section_l eq '') {
			print encode_utf8("no język niemiecki section: $word\n");
			mark_done($word,'no_lang_section');
			next;
		}
		
		# ===== check =======
		
		($inflection,$singular,$plural,$ipa_sing,$ipa_pl)
			= extract_de_inflection_dewikt(\$section_l);
		
		if ($plural ne '' && exists($pronunciation{$plural})) {
			$pron_pl = $pronunciation{$plural};
		}
		if ($singular eq '' && $plural ne '') {
			$pron = '';
		}
		if ($plural eq $singular) {
			$pron_pl = '';
		}
		
		my ($result_l) #check-only
			= add_audio_plwikt(\$section_l,$pron,'Deutsch',1,$pron_pl,$plural,$ipa_sing,$ipa_pl);
		
		if ($result_l == 1) {
			#print encode_utf8($word),": has audio\n";
			mark_done($word,'has_audio');
			next;
		}
	}
	
	if (!$debug_mode) {
		sleep 2;
	}
	
	# ===== section processing =======
	
	++$visited_pages;
	
	my $page_text_remote = $editor_remote->get_text($word);
	my $original_page_text = $page_text_remote;
	if ($page_text_remote !~ /\w/) {
		print "entry does not exist: ",encode_utf8($word),"\n";
		mark_done($word,'entry_not_existing');
		next;
	}
	
	my $initial_summary = initial_cosmetics('pl',\$page_text_remote);
	my ($before,$section,$after) = split_article_wikt('pl','język niemiecki',$page_text_remote);
	
	my($audio_result,$audios_count,$edit_summary) #adding
		= add_audio_plwikt(\$section,$pron,'język niemiecki',0,$pron_pl,$plural,$ipa_sing,$ipa_pl);
	my($inf_result,$inf_summary) = add_inflection_plwikt(\$section,$inflection,$word);
	
	if ($audio_result == 1 && $inf_result == 0) {
		print encode_utf8($word),": already has all\n";
		mark_done($word, 'has_all');
		next;
	}
	
	if ($debug_mode) {
		print ORIG encode_utf8($original_page_text),"\n";
	}
	
	if ($audio_result == 2) {
		unmark_done($word);
		if ($debug_mode) {
			print DEBUG encode_utf8($page_text_remote),"\n";
		}
		print encode_utf8($word),': CANNOT add audio; ';
		print encode_utf8($edit_summary), "\n";
		print ERRORS encode_utf8($word),': CANNOT add audio; ';
		print ERRORS encode_utf8($edit_summary), "\n";
		next;
	}
	
	$added_files += $audios_count;
	
	# === end section processing
	
	$page_text_remote = $before.$section.$after;
	
	my $final_summary = final_cosmetics('pl', \$page_text_remote);
	$edit_summary .= '; '.$initial_summary if ($initial_summary);
	$edit_summary .= '; '.$final_summary if ($final_summary);
	$edit_summary .= '; '.$inf_summary if ($inf_summary);
	
	print encode_utf8($word),': ',encode_utf8($edit_summary),"\n";

	++$modified_pages;
	
	if ($debug_mode) {
		print DEBUG encode_utf8($page_text_remote),"\n";
	} else {
	
		# was: encode_utf8($edit_summary)
		my $response = $editor_remote->edit($word, $page_text_remote, $edit_summary, 1);
		if ($response) {
			mark_done($word,'added_audio');
		} else {
			print STDERR 'CANNOT edit ',encode_utf8($word),"\n";
		}
	}
	
} continue {
	if ($visited_pages >= $page_limit) {
		print "interrupted\n";
		last;
	}
}

save_results();


sub save_results {
	print "added $added_files files, modified $modified_pages pages\n";
	if ($debug_mode) { close DEBUG; exit(0); }
	
	add_audio_count('audio_count_plwikt.txt', 'de', $added_files);
	
	save_hash($donefile, \%done);
}

sub mark_done {
	my ($word,$msg) = @_;
	$msg = 1 unless(defined($msg));
	
	$done{$lang_code.'-'.$word} = $msg;
}

sub is_done {
	my $word = shift;
	return exists($done{$lang_code.'-'.$word});
}

sub unmark_done {
	my $word = shift;
	
	my $key = $lang_code.'-'.$word;
	if (exists($done{$key})) {
		delete($done{$key});
	}
}
