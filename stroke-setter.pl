#!/usr/bin/perl -w

use lib '.';
use MediaWiki::Bot 3.3.1;
use Derbeth::Wikitools 0.8.0;
use Derbeth::Wiktionary;
use Derbeth::Util;
use Encode;
use Getopt::Long;
use Term::ANSIColor qw/colored colorstrip/;

use feature qw( switch );
use strict;
use utf8;

my $donefile = 'done/stroke.txt';

my $verbose=0;
my $pause=3;
my $processed_words=0;
my %done;
my %strokes;
my %settings = load_hash('settings.ini');
read_hash_loose($donefile, \%done);
read_hash_strict('audio/stroke.txt', \%strokes);
my $word_count = scalar(%strokes);
my $added_files=0;
my $visited_pages=0;
my $edited_limit=15;
my $edited_pages=0;

my $error_retries=0;
my $max_retries=1;

$SIG{INT} = $SIG{TERM} = $SIG{QUIT} = sub { save_results(); exit 1; };

system("renice -n 19 -p $$");

my $editor = create_wikt_editor("en") or die;

foreach my $sign (sort keys %strokes) {
	++$processed_words;
	if (exists $done{$sign}) {
		print encode_utf8("already done: $sign\n") if ($verbose);
		next;
	}

	sleep $pause if $visited_pages > 0;
	my $page_text = $editor->get_text($sign);
	++$visited_pages;

	if (!defined($page_text)) {
		if ($editor->{error} && $editor->{error}->{code}) {
			print STDERR colored('cannot', 'red'), encode_utf8(" get text of $sign: "), $editor->{error}->{details}, "\n";
			if ($editor->{error} && $editor->{error}->{details} =~ /read-only mode/ && ++$error_retries <= $max_retries) {
				sleep 10 * 60;
				redo; # something went wrong, don't mark as done
			}
			last; # network error
		}
		print encode_utf8($sign),": no entry\n";
		$done{$sign} = 'no_entry';
		next;
	}

	my $initial_summary = initial_cosmetics('en',\$page_text);
	if ($page_text =~ /\{\{stroke order[^}]*\}\}|\{\{han stroke[^}]*/i) {
		print encode_utf8("$sign: has $&\n");
		$done{$sign} = 'has_stroke';
		next;
	}
	if ($page_text =~ /#REDIRECT.*/i) {
		print encode_utf8("$sign:$&\n");
		$done{$sign} = 'redirect';
		next;
	}

	my($before,$section,$after) = split_article_enwikt_direct('Translingual',$page_text);

	if ($section eq '') {
		print encode_utf8("$sign: no Translingual\n");
		$done{$sign} = 'no_section';
		next;
	}

	my ($added, $edit_summary) = add_stroke(\$section, $strokes{$sign});
	$edit_summary .= '; '.$initial_summary if ($initial_summary);
# 	print encode_utf8("$sign $added: $edit_summary\n>>>>\n$section\n");
# 	last;

	if (!$added) {
		$done{$sign} = 'error';
		print colored('CANNOT', 'red'), encode_utf8(" add audio to $sign; $edit_summary\n");
		next;
	}

	$page_text = $before.$section.$after;

	my $response = $editor->edit({page=>$sign, text=>$page_text,
		summary=>$edit_summary, bot=>1});
	if ($response) {
		$done{$sign} = 'added';
		print encode_utf8("$sign " . colored('edited', 'green') . ": $edit_summary\n");
		++$added_files;
		++$edited_pages;
		system("firefox --new-tab 'https://en.wiktionary.org/w/index.php?title=$sign&diff=cur&oldid=prev'");
	} else {
		print STDERR 'edit ', colored('FAILED', 'red'), ' for ',encode_utf8($sign);
		print STDERR " details: $editor->{error}->{details}" if $editor->{error};
		print STDERR "\n";
		if ($editor->{error} && $editor->{error}->{details} =~ /read-only mode/ && ++$error_retries <= $max_retries) {
			sleep 10 * 60;
			redo; # something went wrong, don't mark as done
		}
		last;
	}
} continue {
	print_progress() if ($visited_pages % 200 == 1 && $visited_pages > 1);
# 	last if ($visited_pages > 10);
	if ($edited_pages >= $edited_limit) {
		print "limit ($edited_limit) reached\n";
		last;
	}
}
save_results();

sub add_stroke {
	my ($section_ref, $stroke_info) = @_;
	my $argument;
	$stroke_info =~ /^([^<]+)<([^>]+)>$/ or die "wrong $stroke_info";
	my ($stroke_type, $file) = ($1, $2);
	given ($stroke_type) {
		when('bw') { $argument=''; }
		when('red') { $argument="|[[File:$file|100px]]"; }
		when('animate') { $argument='|type=animate'; }
		default { die "unexpected stroke type $stroke_type"; }
	}
	if ($stroke_type eq 'bw' && $$section_ref =~ /\{\{han char.*sn=(\d+)\|/i) {
		$argument .= "|strokes=$1";
	}

	my $stroke_template = "{{stroke order$argument}}";
	my $edit_summary = ($stroke_type eq 'red') ? "added {{stroke order}} (red)" : $stroke_template;
	my $added = ($$section_ref =~ s/(Translingual\s*==)\n/$1\n$stroke_template\n/);
	return ($added, "added $edit_summary");
}

sub save_results {
	print_progress();
	save_hash_sorted($donefile, \%done);
}

sub print_progress {
	my ($sec,$min,$hour,$day,$mon,$year) = localtime();
	my $status_line = sprintf('%02d:%02d %d/%d', $hour, $min, $processed_words, $word_count)
		. sprintf(colored(' %2.0f%%', 'green'), 100*$processed_words/$word_count);
	$status_line .= " added $added_files files";
	$status_line .= sprintf(' %2.1fh left', ($word_count-$processed_words)*$pause/(60*60))
		. "\n";
	print STDERR $status_line;
}
