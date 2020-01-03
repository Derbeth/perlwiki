#!/usr/bin/perl -w

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

use lib '.';
use MediaWiki::Bot 3.3.1;
use Derbeth::Wikitools 0.8.0;
use Derbeth::Wiktionary;
use Derbeth::I18n;
use Derbeth::Inflection;
use Derbeth::Util;
use Encode;
use Getopt::Long;
use Term::ANSIColor qw/colored colorstrip/;

use strict;
use utf8;

# ========== Settings

my $debug_mode=0;  # does not write anything to wiki, writes to
				   # $debug_file instead
my $filter_mode=0; # only filters data from audio_xy.txt to
                   # enwikt_audio_xy.txt
                   # disables $debug_mode
my $randomize=0;   # process entries in random order
my $verbose=0;
my $clean_cache=0;
my $clean_start=0; # removes all done files etc.
my $page_limit=40000; # bot won't change more that x number of pages
my $save_every=15000;   # bot saves results after modifying x pages

my $wikt_lang='en';   # 'en','de','pl'; other Wiktionaries are not
                      # supported
my $pause=5;          # number of seconds to wait before fetching each page
my $only_words='';    # comma-separated list of words - only they will be processed
my $from_list='';     # path to a file with word-audio list
my $all_langs=0;      # add in all languages
my $except_langs='';

my @langs;

#`rm -f $donefile`;
my $debug_orig_file='in.txt';
my $debug_file='out.txt';
my $errors_file='done/errors_audio.txt';

# ============ Global variables

my %done; # langcode-skip_word => 1
my %pronunciation; # 'word' => 'en-file.ogg|en-us-file.ogg<us>'
my %pronunciation_filtered;
my %forced_words; # only-word => 1

my $lang_code;

my $processed_words;
my $word_count;
my $visited_pages;
my $edited_pages=0;
my $added_files;
my $last_save;

# =========== Reading settings & variables

my $filtered_audio_filename;

{
	my $lang_codes; # 'en,fr,es'
	
	GetOptions('f|filter!' => \$filter_mode, 'd|debug!' => \$debug_mode,
		'l|lang=s' => \$lang_codes, 'w|wikt=s' => \$wikt_lang, 'all|a' => \$all_langs,
		'except=s' => \$except_langs,
		'p|limit=i' => \$page_limit, 'c|cleanstart!' => \$clean_start,
		'cleancache!' => \$clean_cache, 'r|random!' => \$randomize,
		'word=s' => \$only_words,
		'from-list=s' => \$from_list,
		'verbose|v' => \$verbose, 'pause=i' => \$pause) or die;
	
	die "provide -w and -l correctly!" unless($wikt_lang && ($lang_codes || $all_langs));
	die "cannot specify both -a and -l" if ($lang_codes && $all_langs);
	die "list only supports de in de.wikt" if ($from_list && !($wikt_lang eq 'de' && $lang_codes eq 'de'));
	if ($all_langs) {
		my @except_langs = split /,/, $except_langs;
		push @except_langs, 'th' if($wikt_lang eq 'en' && !grep('th', @except_langs));
		@langs = all_languages(@except_langs);
	} else {
		@langs = split /,/, $lang_codes;
	}
}

system("renice -n 19 -p $$");

if ($randomize) {
	srand(time);
	print "Randomized.\n";
}

if ($clean_cache) {
	Derbeth::Web::clear_cache();
}
mkdir 'done' unless(-e 'done');
if ($clean_start) {
	`rm -f audio/${wikt_lang}wikt_audio*`;
	`rm -f done/done_filter_${wikt_lang}.txt done/done_audio_${wikt_lang}.txt`;
	`rm -f done/audio_count_${wikt_lang}wikt.txt`;
	`rm -f $errors_file`;
}

my $donefile= ($filter_mode)
	? "done/done_filter_${wikt_lang}.txt"
	: "done/done_audio_${wikt_lang}.txt";

if ($filter_mode == 1) {
	$debug_mode = 0;
}

if ($only_words) {
	$only_words = decode_utf8($only_words);
	foreach my $w (split (/,/, $only_words)) {
		$forced_words{$w} = 1;
	}
	print 'Will only edit words: ', encode_utf8(join(' ', keys %forced_words)), "\n";
} elsif ($from_list) {
	$donefile = "done/done_from_list_${wikt_lang}.txt";
}

if ($only_words && $debug_mode) {
	Derbeth::Web::enable_caching(1);
}

my %settings = load_hash('settings.ini');
read_hash_loose($donefile, \%done);

my $server = "http://$wikt_lang.wiktionary.org/w/";
#$server = 'http://en.wiktionary.org/w/' if ($wikt_lang eq 'en');

my $editor = create_wikt_editor($wikt_lang) or die;

if ($debug_mode) {
	srand();
	open(DEBUG,">$debug_file");
	open(ORIG,">$debug_orig_file");
	print "debug mode, will write to $debug_orig_file and $debug_file\n";
}

open(ERRORS,">>$errors_file");

$SIG{INT} = $SIG{TERM} = $SIG{QUIT} = sub { save_results('finish'); close ERRORS; exit 1; };

# ========== Main loop

LANGUAGES: foreach my $l (@langs) {
	if ($wikt_lang eq 'de' && $l eq 'de' && !$from_list) {
		print "Skipping de, run ./dewikt_audiosetter_de.pl\n";
		next;
	}
	$lang_code = $l;
	
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
	print STDERR encode_utf8(get_language_name('en',$lang_code)), " on ${wikt_lang}wikt\n";
	
	read_audio_files_into(\%pronunciation);
	
	if (!$debug_mode && !$filter_mode) {
		print scalar(keys(%pronunciation)), " audios to add\n";
	}
	
	my @keys = keys(%pronunciation);
	unless($randomize) {
		@keys = sort(@keys);
	} else {
		@keys = sort { return int(rand(3)) -1; } @keys;
	}
	$word_count=scalar(@keys);
	my $small_count = $word_count < 400;
	foreach my $word (@keys) {
		next if ($only_words && ! exists $forced_words{$word});

		++$processed_words;

		if (is_done($word) && !$debug_mode) {
			print encode_utf8("already done: $word\n") if ($visited_pages > 0 && ($verbose || $small_count));
			next;
		}

		if ($filter_mode && exists($pronunciation_filtered{$word})) {
			print encode_utf8("already filtered: $word\n");
			next;
		}

		if (!$debug_mode && !$filter_mode) {
			sleep $pause;
		}

		++$visited_pages;
		print_progress() if ($visited_pages % 200 == 1);

		my $page_text;
		if ($filter_mode || $debug_mode) {
			$page_text = get_wikicode($server,$word);
		} else {
			$page_text = $editor->get_text($word);
		}

		my $original_page_text = $page_text;
		if (!defined($page_text)) {
			if ($editor->{error} && $editor->{error}->{code}) {
				print STDERR colored('cannot', 'red'), encode_utf8(" get text of $word: "), $editor->{error}->{details}, "\n";
				last; # network error
			}
			print "entry does not exist: ",encode_utf8($word),"\n" if ($verbose || $small_count);
			mark_done($word,'no_entry');
			next;
		}
		if ($page_text !~ /[a-zA-Z]/) {
			print "warning: page has empty text: ",encode_utf8($word),"\n";
		}
		
		my $initial_summary = initial_cosmetics($wikt_lang,\$page_text);
		
		my($before,$section,$after) = split_article_wikt($wikt_lang,$lang_code,$page_text,1);
		
		if ($section eq '') {
			print encode_utf8("no $lang_code section: $word\n");
			mark_done($word,'no_section');
			next;
		}
		
		# ===== section processing =======
		
		my ($pron,$pron_pl,$sing,$plural) = find_pronunciation_files($wikt_lang,$lang_code,$word,\$section,\%pronunciation);
		if (!$pron && !$pron_pl && !$sing && !$plural) {
			save_results('finish');
			close ERRORS;
			die "error finding audios for ".encode_utf8($word);
		}
		my ($result,$audios_count,$edit_summary)
			= add_audio($wikt_lang,\$section,$pron,$lang_code,$filter_mode,$word,$pron_pl,$plural);
		
		if ($result == 1) {
			print encode_utf8("has audio: $word\n");
			mark_done($word,'has_audio');
			next;
		}
		if ($result == 3) {
			mark_done($word,'error-many-speech-parts');
			print encode_utf8("more than 1 speech part: $word; $edit_summary\n");
			next;
		}
		
		if ($debug_mode) {
			print ORIG encode_utf8($original_page_text),"\n";
		}
		
		if ($result == 2) {
			mark_done($word,'error');
			if ($debug_mode) {
				print DEBUG encode_utf8($page_text),"\n";
			}
			print colored('CANNOT', 'red'), encode_utf8(" add audio to $word; $edit_summary\n");
			print ERRORS encode_utf8($word),"($wikt_lang,$lang_code): CANNOT add audio; ";
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
		
		my $final_cosm_summary = final_cosmetics($wikt_lang, \$page_text, $word, $plural);
		$edit_summary .= '; '.$initial_summary if ($initial_summary);
		$edit_summary .= '; '.$final_cosm_summary if ($final_cosm_summary);

		if ($debug_mode) {
			print DEBUG encode_utf8($page_text),"\n";
			$added_files += $audios_count;
			++$edited_pages;
		} else {
			my $response = $editor->edit({page=>$word, text=>$page_text,
				summary=>$edit_summary, bot=>1});
			if ($response) {
				mark_done($word,'added');
				print encode_utf8("edited $word: $edit_summary\n");
				$added_files += $audios_count;
				++$edited_pages;
			} else {
				print STDERR 'edit ', colored('FAILED', 'red'), ' for ',encode_utf8($word);
				print STDERR " details: $editor->{error}->{details}" if $editor->{error};
				print STDERR "\n";
				if ($editor->{error} && $editor->{error}->{details} =~ /read-only mode/) {
					sleep 10 * 60;
					redo; # something went wrong, don't mark as done
				}
				last;
			}
		}

	} continue {
		if ($edited_pages >= $page_limit) {
			print "limit ($page_limit) reached\n";
			save_results('finish');
			last LANGUAGES;
		}
		if ($visited_pages - $last_save > $save_every) {
			$last_save = $visited_pages;
			save_results();
		}
	}
	
	save_results('finish');
} # foreach language
close ERRORS;

sub read_audio_files_into {
	my ($hash_ref) = @_;
	if ($from_list) {
		read_jeuwre_list($from_list, $hash_ref);
		return;
	}

	my $audio_filename='audio_'.$lang_code.'.txt';
	$filtered_audio_filename=$wikt_lang.'wikt_'.$audio_filename;

	$audio_filename = 'audio/'.$audio_filename;
	$filtered_audio_filename = 'audio/'.$filtered_audio_filename;

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
	}

	read_hash_strict($audio_filename, $hash_ref);
}

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
		print_progress();
		if ($debug_mode && $finish) {close DEBUG; exit(0); }

		add_audio_count('done/audio_count_'.$wikt_lang.'wikt.txt', $lang_code, $added_files);
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

sub print_progress {
	my ($sec,$min,$hour,$day,$mon,$year) = localtime();
	my $status_line = sprintf('%02d:%02d %d/%d', $hour, $min, $processed_words, $word_count)
		. sprintf(colored(' %2.0f%%', 'green'), 100*$processed_words/$word_count);
	unless($filter_mode) {
		$status_line .= " added $added_files files for $lang_code at ${wikt_lang}wikt";
	}
	$status_line .= sprintf(' %2.1fh left', ($word_count-$processed_words)*$pause/(60*60))
		. "\n";
	print STDERR $status_line;
	if ($settings{audiosetter_status_file}) {
		my $fh;
		unless(open($fh, '>', $settings{audiosetter_status_file})) {
			print STDERR "Cannot write status to $settings{audiosetter_status_file}\n";
			return;
		}
		print $fh sprintf('%d-%02d-%02d ', $year+1900, $mon+1, $day).colorstrip($status_line);
		close($fh);
	}
}

sub all_languages {
	my @except_langs = @_;
	opendir(DIR, 'audio') or die "cannot open audio/ dir";
	my @files = readdir(DIR);
	closedir(DIR);
	return sort (grep { my $lang = $_; $_ && ! grep { $_ eq $lang} @except_langs } (map { /^audio_([^.]+)\.txt$/ && $1 } @files));
}
