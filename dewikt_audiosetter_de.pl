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

use MediaWiki::Bot 3.3.1;
use Derbeth::Wikitools;
use Derbeth::Wiktionary;
use Derbeth::I18n;
use Derbeth::Inflection;
use Derbeth::Util;
use Encode;
use Getopt::Long;
use Term::ANSIColor;

use strict;
use utf8;

# ========== settings

my $debug_mode=0;  # does not write anything to wiki, writes to
				   # $debug_file instead

my $edited_pages_limit=80000; # bot won't change more that x number of pages

my $wikt_lang='de';   # 'en','de','pl'; other Wiktionaries are not supported
my $lang_code='de';
my $language=get_language_name('de',$lang_code);
my $pause=2;          # number of seconds to wait before fetching each page
my $randomize=0; # edit pages in random order
my $verbose=0;

my %settings = load_hash('settings.ini');

my $donefile = "done/done_dewikt_de.txt";
#`rm -f $donefile`;
my $debug_orig_file='in.txt';
my $debug_file='out.txt';
my $errors_file='done/errors_dewikt_de.txt';
Derbeth::Web::enable_caching(1);

# ============ end settings

GetOptions('p|limit=i' => \$edited_pages_limit, 'r|random!' => \$randomize, 'v|verbose!' => \$verbose,
	'pause=i' => \$pause) or die;

my %done; # langcode-skip_word => 1
my %pronunciation; # 'word' => 'en-file.ogg|en-us-file.ogg<us>'

mkdir 'done' unless(-e 'done');
$SIG{INT} = $SIG{TERM} = $SIG{QUIT} = sub { save_results(); exit 1; };

read_hash_loose($donefile, \%done);

if ($debug_mode) {
	print "debug mode\n";
}

my $audio_filename='audio/audio_de.txt';
read_hash_strict($audio_filename, \%pronunciation);

my $visited_pages=0;
my $edited_pages=0;
my $added_files=0;

my $editor;
{
	my $debug = 1;
	my $host = "de.wiktionary.org";
	$editor = MediaWiki::Bot->new({
		host => $host,
		debug => $debug,
		login_data => {'username' => $settings{bot_login}, 'password' => $settings{bot_password}},
		operator => $settings{bot_operator},
		assert => 'bot',
	});
	die unless $editor;
	die if ($editor->{error} && $editor->{error}->{code});
}

if ($debug_mode) {
	open(DEBUG,">$debug_file");
	open(ORIG,">$debug_orig_file");
}

open(ERRORS,">>$errors_file");

# ==== main loop

my $server='http://de.wiktionary.org/w/';
my $category='Kategorie:Deutsch';

my @entries = Derbeth::Wikitools::get_category_contents_perlwikipedia($editor,$category,undef,{main=>1});
# my @entries = ('Abteilung');

my $word_count = scalar(@entries);
my $processed_words = 0;

print "$word_count words in category\n";

if ($randomize) {
	srand(time);
	@entries = sort { return int(rand(3)) -1; } @entries;
	print "Randomized.\n";
}

foreach my $word (@entries) {
	++$processed_words;
	if (is_done($word) && !$debug_mode) {
		print encode_utf8($word),": already done\n" if ($visited_pages > 0 && $verbose);
		next;
	}

	if (!exists($pronunciation{$word})) {
		#print encode_utf8("no pronunciation: $word\n");
		mark_done($word,'no_pronunciation');
		next;
	}

	if (!$debug_mode) {
		sleep $pause;
	}

	++$visited_pages;
	print_progress() if ($visited_pages % 200 == 1);

	my $page_text = $editor->get_text($word);
	my $original_page_text = $page_text;
	if (!defined($page_text)) {
		if ($editor->{error} && $editor->{error}->{code}) {
			last; # network error
		}
		print "entry does not exist: ",encode_utf8($word),"\n";
		mark_done($word,'no_entry');
		next;
	}
	if ($page_text !~ /[a-zA-Z]/) {
		print "warning: page has empty text: ",encode_utf8($word),"\n";
	}

	my $initial_summary = initial_cosmetics('de',\$page_text);
	my ($before,$section,$after) = split_article_wikt('de',$lang_code,$page_text,1);

	if ($section eq '') {
		print encode_utf8("no $language section: $word\n");
		print ERRORS encode_utf8("no $language section: $word\n");
		mark_done($word, 'no_section');
		next;
	}

	# ===== section processing =======

	my ($pron, $pron_pl, $sing, $plural) = find_pronunciation_files('de', 'de', $word, \$section, \%pronunciation);
	if (!$pron && !$pron_pl && !$sing && !$plural) {
		save_results();
		die "error finding audios for ".encode_utf8($word);
	}
	my ($result,$audios_count,$edit_summary)
		= add_audio('de',\$section,$pron,$lang_code,0,$word,$pron_pl,$plural);

	if ($debug_mode) {
		print ORIG encode_utf8($original_page_text),"\n";
	}

	if ($result == 1) {
		print encode_utf8($word),": already has audio\n";
		mark_done($word, 'has_audio');
		next;
	}
	if ($result == 2) {
		mark_done($word,'error');
		if ($debug_mode) {
			print DEBUG encode_utf8($page_text),"\n";
		}
		print encode_utf8($word),': ', colored('CANNOT', 'red'), ' add audio; ';
		print encode_utf8($edit_summary), "\n";
		print ERRORS encode_utf8($word),': CANNOT add audio; ';
		print ERRORS encode_utf8($edit_summary), "\n";
		next;
	}

	# === end section processing

	$page_text = $before.$section.$after;

	my $final_summary = final_cosmetics($wikt_lang, \$page_text, $word, $plural);
	$edit_summary .= '; '.$initial_summary if ($initial_summary);
	$edit_summary .= '; '.$final_summary if ($final_summary);

	print encode_utf8($word),': ',encode_utf8($edit_summary),"\n";

	++$edited_pages;
	if ($debug_mode) {
		print DEBUG encode_utf8($page_text),"\n";
	} else {

		my $response = $editor->edit({page=>$word, text=>$page_text,
			summary=>$edit_summary, bot=>1});
		if ($response) {
			mark_done($word, 'added_audio');
			$added_files += $audios_count;
		} else {
			print STDERR 'edit ', colored('FAILED', 'red'), ' for ',encode_utf8($word);
			print STDERR " details: $editor->{error}->{details}" if $editor->{error};
			print STDERR "\n";
			mark_done($word,'error');
		}
	}

} continue {
	if ($edited_pages >= $edited_pages_limit) {
		print "interrupted\n";
		last;
	}
}

save_results();


sub save_results {
	print_progress();
	close ERRORS;
	if ($debug_mode) { close DEBUG; exit(0); }
	
	add_audio_count('done/audio_count_dewikt.txt', 'de', $added_files);
	
	save_hash_sorted($donefile, \%done);
	$added_files = 0;
}

sub mark_done {
	my ($word,$msg) = @_;
	$msg = 1 unless(defined($msg));
	
	$done{$word} = $msg;
}

sub unmark_done {
	my $word = shift;
	
	my $key = $word;
	if (exists($done{$key})) {
		delete($done{$key});
	}
}

sub is_done {
	my $word = shift;
	return exists($done{$word});
}

sub print_progress {
	print STDERR "$processed_words/$word_count";
	printf STDERR colored(' %2.0f%%', 'green'), 100*$processed_words/$word_count;
	print STDERR " added $added_files files\n";
}
