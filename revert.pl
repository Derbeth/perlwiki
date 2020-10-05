#!/usr/bin/perl -w

use lib '.';
use Derbeth::Util;
use Derbeth::Wikitools 0.8.0;
use MediaWiki::Bot 3.3.1;
use Encode;
use Getopt::Long;
use Term::ANSIColor qw/colored colorstrip/;

use strict;
use utf8;


my $wikt_lang='en';
my $lang_code;
my $pause=1;
my $page_limit=40000;

GetOptions(
	'l|lang=s' => \$lang_code, 'w|wikt=s' => \$wikt_lang,
	'p|limit=i' => \$page_limit,
) or die;

my $donefile="done/done_revert.txt";

my %settings = load_hash('settings.ini');
my %done;
my $edited_pages=0;

read_hash_loose($donefile, \%done);

my $server = "http://$wikt_lang.wiktionary.org/w/";

my $editor = create_wikt_editor($wikt_lang) or die;

if (! %done) {
	my $added_donefile="done/done_audio_${wikt_lang}.txt";
	my %added_done;
	read_hash_loose($added_donefile, \%added_done);
	while (my ($entry, $status) = each %added_done) {
		if ($entry =~ /^$lang_code-(.*)/ && $status eq 'added') {
			$done{$1} = 'to_do';
		}
	}
}

$SIG{INT} = $SIG{TERM} = $SIG{QUIT} = sub { save_results('finish'); exit 1; };

print scalar(keys %done), " edits to revert in $lang_code in ${wikt_lang}wikt\n";
my @keys = sort keys %done;
my $visited_pages=0;
foreach my $word (@keys) {
	++$visited_pages;
	print_progress() if ($visited_pages % 50 == 1);
	if ($done{$word} ne 'to_do') {
		next;
	}
	sleep $pause;
	my @hist = $editor->get_history($word, 1);
	unless (@hist) {
		die "cannot get history for $word";
	}
	if ($hist[0]->{user} ne $settings{bot_login}) {
		print encode_utf8("$word already reverted by $hist[0]->{user}\n");
		$done{$word} = 'not_last_edit';
	} elsif($hist[0]->{comment} !~ /LL/) {
		print encode_utf8("$word not reverted due to comment '$hist[0]->{comment}'\n");
		$done{$word} = 'wrong_comment';
	} else {
		$editor->undo($word, $hist[0]->{revid}, "Undo own adding of $lang_code audio\n");
		if ($editor->{error}) {
			print STDERR colored('cannot', 'red'), encode_utf8(" get text of $word: "), $editor->{error}->{details}, "\n";
			last;
		}
		print encode_utf8("Reverted $word\n");
		++$edited_pages;
		$done{$word} = 'reverted';
	}
} continue {
	if ($edited_pages >= $page_limit) {
		print "limit ($page_limit) reached\n";
		print_progress();
		last;
	}
}

save_results();

sub save_results {
	save_hash_sorted($donefile, \%done);
}

sub print_progress {
	print $visited_pages, '/', scalar(@keys), "\n";
}
