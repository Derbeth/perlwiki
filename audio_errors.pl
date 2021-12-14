#!/usr/bin/perl -w

use strict;
use utf8;
use lib '.';

use Derbeth::Util;
use Derbeth::I18n;
use Derbeth::Wikitools;
use Derbeth::Wiktionary;
use Pod::Usage;
use Getopt::Long;
use Encode;

my $wikt_lang='en';
my $send=0;
my $oneline=0;
my $show_help=0;

GetOptions(
	'w|wikt=s' => \$wikt_lang,
	'oneline' => \$oneline,
	'send' => \$send,
	'help|h' => \$show_help,
) or pod2usage('-verbose'=>1,'-exitval'=>1);
pod2usage('-verbose'=>2,'-noperldoc'=>1) if ($show_help);

my %done;
my %langs;
my $errors_count;

my $buffer;
my $editor;
if ($send) {
	die "not compatible with --oneline" if $oneline;
	die "only de.wikt supported" if $wikt_lang ne 'de';
	$editor = create_wikt_editor($wikt_lang) or die;
	open(BUFFER, '>', \$buffer);
	select(BUFFER);
}

read_hash_loose("done/done_audio_${wikt_lang}.txt", \%done) or die;
while (my ($entry,$result) = each(%done)) {
	my ($lang,$word) = split /-/, $entry;
	if ($result eq 'error') {
		$langs{$lang} ||= [];
		push @{$langs{$lang}}, $word;
		++$errors_count;
	}
}

if ($wikt_lang eq 'de') {
	my %de_done;
	read_hash_loose("done/done_dewikt_de.txt", \%de_done);
	while (my ($entry,$result) = each %de_done) {
		if ($result =~ /^error/) {
			$langs{de} ||= [];
			push @{$langs{de}}, $entry;
			++$errors_count;
		}
	}
}

print "$errors_count errors\n";
exit if $oneline;
foreach my $lang (sort(keys(%langs))) {
	if ($wikt_lang eq 'en' && $lang =~ /^(?:eo|th|yue|zh)$/) {
		next;
	}
	print "== ", encode_utf8(get_language_name($wikt_lang, $lang)), "==\n";
	print "{| class=\"wikitable\"\n";
	my %audio;
	my $audio_file;
	{
		my $filtered = "audio/${wikt_lang}wikt_audio_${lang}.txt";
		my $all = "audio/audio_${lang}.txt";
		$audio_file = (-e $filtered) ? $filtered : $all;
	}
	read_hash_loose($audio_file, \%audio) or die "can't open $audio_file";
	my @words = sort(@{$langs{$lang}});
	foreach my $word(@words) {
		my $pron = $audio{$word};
		unless($pron) {
			print STDERR "no audio ", encode_utf8($word), "($lang)\n";
			next;
		}
		my @decoded = decode_pron($pron);
		my @files;
		for (my $i=0; $i<=$#decoded; $i += 2) {
			push @files, $decoded[$i]; # only file names
		}

		print encode_utf8("|-\n| [[$word]] || ");
		my @formatted;
		foreach my $file (@files) {
			push @formatted, encode_utf8("[[commons:File:$file|$file]]");
		}
		print join(', ', @formatted), "\n";
	}
	print "|}\n\n";
}

if ($send) {
	close(BUFFER);
	select(STDOUT);
	my ($page,$summary) = ('Benutzer:DerbethBot/Nicht verknüpft','aktualisierung');
	my $response = $editor->edit({page=>$page, text=>decode_utf8($buffer), summary=>$summary, bot=>1});
	if ($response) {
		print encode_utf8("Updated $page ($errors_count errors)\n");
	} else {
		die "Failed to update $page";
	}
}

=head1 NAME

audio_errors - generates Wikitext table with errors from audiosetter

=head1 SYNOPSIS

 -w <wikt_lang> (default en)
 --oneline
 --send

=cut
