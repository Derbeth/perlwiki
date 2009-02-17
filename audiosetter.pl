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

# Usage:
#   ./audiosetter.pl --[no]filter --[no]debug --l[anguage] hr
#   --w[ikt] en --limit 40

use Perlwikipedia;
use Derbeth::Wikitools;
use Derbeth::Wiktionary;
use Derbeth::I18n;
use Derbeth::Util;
use Encode;
use Getopt::Long;

use strict;
use utf8;

# ========== Settings

my $debug_mode=0;  # does not write anything to wiki, writes to
				   # $debug_file instead
my $filter_mode=0; # only filters data from audio_xy.txt to
                   # enwikt_audio_xy.txt
                   # disables $debug_mode

my $page_limit=40000; # bot won't change more that x number of pages
my $save_every=15000;   # bot saves results after modifying x pages

my $wikt_lang='en';   # 'en','de','pl'; other Wiktionaries are not
                      # supported

my @langs;

my %settings = load_hash('settings.ini');
my $user = $settings{bot_login}; # for wiki
my $pass = $settings{bot_password};   # for wiki

#`rm -f $donefile`;
my $debug_orig_file='in.txt';
my $debug_file='out.txt';
my $errors_file='errors_audio.txt';

# ============ Global variables

my %done; # langcode-skip_word => 1
my %pronunciation; # 'word' => 'en-file.ogg|en-us-file.ogg<us>'
my %pronunciation_filtered;

my $lang_code;

my $processed_words;
my $visited_pages;
my $edited_pages=0;
my $added_files;
my $last_save;

# =========== Reading settings & variables

my $filtered_audio_filename;

{
	my $lang_codes; # 'en,fr,es'
	
	GetOptions('f|filter!' => \$filter_mode, 'd|debug!' => \$debug_mode,
		'l|lang=s' => \$lang_codes, 'w|wikt=s' => \$wikt_lang,
		'p|limit=i' => \$page_limit);
	
	@langs = split /,/, $lang_codes;
}

my $donefile= ($filter_mode)
	? "done_filter_${wikt_lang}.txt"
	: "done_audio_${wikt_lang}.txt";

if ($filter_mode == 1) {
	$debug_mode = 0;
}

$SIG{INT} = $SIG{TERM} = $SIG{QUIT} = sub { save_results('finish'); exit; };

read_hash_loose($donefile, \%done);

my $server = "http://localhost/~piotr/${wikt_lang}wikt/";
#$server = 'http://en.wiktionary.org/w/' if ($wikt_lang eq 'en');

my $editor=Perlwikipedia->new($user);
#$editor->{debug} = 1;
if ($filter_mode || $debug_mode) {
	$editor->set_wiki('localhost/~piotr', $wikt_lang.'wikt');
} else {
	$editor->set_wiki("$wikt_lang.wiktionary.org",'w');
}
$editor->login($user, $pass);

if ($debug_mode) {
	open(DEBUG,">$debug_file");
	open(ORIG,">$debug_orig_file");
}

open(ERRORS,">>$errors_file");

# ========== Main loop

foreach my $l (@langs) {
	$lang_code = $l;
	my $language=get_language_name($wikt_lang,$lang_code);
	
	$processed_words=0;
	$visited_pages=0;
	$added_files=0;
	$last_save=0;
	
	%pronunciation_filtered = ();
	%pronunciation = ();
	
	print STDERR "debug mode\n" if ($debug_mode);
	if ($filter_mode) {
		print STDERR 'filtering audio for ';
	} else {
		print STDERR 'adding audio for ';
	}
	print STDERR get_language_name('en',$lang_code), " on ${wikt_lang}wikt\n";
	
	my $audio_filename='audio_'.$lang_code.'.txt';
	$filtered_audio_filename=$wikt_lang.'wikt_'.$audio_filename;
	
	if ($filter_mode) {
		read_hash_strict($filtered_audio_filename, \%pronunciation_filtered);
		
	} else {
		if (-e $filtered_audio_filename) {
			print "using filtered audios\n";
			$audio_filename = $filtered_audio_filename;
		}
	}
	
	unless (-e $audio_filename) {
		print "no audio for $lang_code\n";
		next;
	}
	
	read_hash_strict($audio_filename, \%pronunciation);
	
	if (!$debug_mode && !$filter_mode) {
		print scalar(keys(%pronunciation)), " audios to add\n";
	}
	
	my @sorted_keys = sort(keys(%pronunciation));
	my $word_count=scalar(@sorted_keys);
	foreach my $word (@sorted_keys) {
		my $pron = $pronunciation{$word};
		++$processed_words;
		print STDERR "$processed_words/$word_count\n" if ($processed_words % 200 == 0);
		
		if (is_done($word) && !$debug_mode) {
			print encode_utf8($word),": already done\n";
			next;
		}
	
		if ($filter_mode && exists($pronunciation_filtered{$word})) {
			print encode_utf8($word),": already filtered\n";
			next;
		}
		
		if (!$debug_mode && !$filter_mode) {
			sleep 1;
		}
		
		my $page_text;
		if ($filter_mode || $debug_mode) {
			$page_text = get_wikicode($server,$word);
		} else {
			$page_text = $editor->get_text($word);
		}
		
		my $original_page_text = $page_text;
		if ($page_text !~ /\w/) {
			print "entry does not exist: ",encode_utf8($word),"\n";
			mark_done($word,'no_entry');
			next;
		}
		
		my $initial_summary = initial_cosmetics($wikt_lang,\$page_text);
		
		my($before,$section,$after) = split_article_wikt($wikt_lang,$language,$page_text);
		
		if ($section eq '') {
			#print encode_utf8("$wikt_lang - $language\n");
			print encode_utf8("no $language section: $word\n");
			mark_done($word,'no_section');
			next;
		}
		
		# ===== section processing =======
		
		my ($result,$audios_count,$edit_summary)
			= add_audio($wikt_lang,\$section,$pron,$language,$filter_mode);
		
		if ($result == 1) {
			print encode_utf8($word),": has audio\n";
			mark_done($word,'has_audio');
			next;
		}
		++$visited_pages;
		
		if ($debug_mode) {
			print ORIG encode_utf8($original_page_text),"\n";
		}
		
		if ($result == 2) {
			unmark_done($word);
			if ($debug_mode) {
				print DEBUG encode_utf8($page_text),"\n";
			}
			print encode_utf8($word),': CANNOT add audio; ';
			print encode_utf8($edit_summary), "\n";
			print ERRORS encode_utf8($word),"($lang_code): CANNOT add audio; ";
			print ERRORS encode_utf8($edit_summary), "\n";
			next;
		}
		
		if ($filter_mode) {
			$pronunciation_filtered{$word} = $pron;
			print encode_utf8("$word: to add audio\n");
			mark_done($word,'to_add');
			next;
		}
		
		
		
		# === end section processing
		
		$page_text = $before.$section.$after;
		
		my $final_cosm_summary = final_cosmetics($wikt_lang, \$page_text);
		$edit_summary .= '; '.$initial_summary if ($initial_summary);
		$edit_summary .= '; '.$final_cosm_summary if ($final_cosm_summary);
		
		
		
		if ($debug_mode) {
			print DEBUG encode_utf8($page_text),"\n";
			$added_files += $audios_count;
			++$edited_pages;
		} else {
		
			# was: encode_utf8($edit_summary)
			my $response = $editor->edit($word, $page_text, $edit_summary, 1);
			if ($response) {
				print encode_utf8($word),': ',encode_utf8($edit_summary),"\n";
				$added_files += $audios_count;
				++$edited_pages;
			} else {
				print STDERR 'CANNOT edit ',encode_utf8($word),"\n";
				next; # something went wrong, don't mark as done
			}
		}
		mark_done($word,'added');
		
		
	} continue {
		if ($edited_pages >= $page_limit) {
			print "limit ($page_limit) reached\n";
			save_results('finish');
			exit;
		}
		if ($visited_pages - $last_save > $save_every) {
			$last_save = $visited_pages;
			save_results();
		}
	}
	
	save_results('finish');
} # foreach language

sub save_results {
	my $finish = shift;
	
	if ($filter_mode) {
		print STDERR 'saved ', scalar(keys(%pronunciation_filtered));
		print STDERR ' words out of ', scalar(keys(%pronunciation));
		print STDERR ', processed ',$processed_words,"\n";
		#print STDERR 'processed ',$processed_words,' of ';
		#print STDERR scalar(keys(%pronunciation)),"\n";
		save_hash_sorted($filtered_audio_filename,\%pronunciation_filtered);
		
	} else {
		print STDERR "added $added_files files for ";
		print STDERR encode_utf8(get_language_name($wikt_lang,$lang_code));
		print STDERR ' at ',$wikt_lang,"wikt\n";
		if ($debug_mode && $finish) {close DEBUG; exit(0); }
		
		add_audio_count('audio_count_'.$wikt_lang.'wikt.txt', $lang_code, $added_files);
		$added_files = 0;
	}
	
	save_hash_sorted($donefile, \%done);
}

sub mark_done {
	my ($word,$msg) = @_;
	$msg = 1 unless(defined($msg));
	
	$done{$lang_code.'-'.$word} = $msg;
}

sub unmark_done {
	my $word = shift;
	
	my $key = $lang_code.'-'.$word;
	if (exists($done{$key})) {
		delete($done{$key});
	}
}

sub is_done {
	my $word = shift;
	return exists($done{$lang_code.'-'.$word});
}

