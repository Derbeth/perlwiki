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

# Fetches names of files from Commons Category:X pronunciation and
# saves it to audio_xy.txt file

use strict;
use English;
use utf8;
use lib '.';

use Derbeth::Wikitools;
use Derbeth::Commons;
use Encode;
use Getopt::Long;
use Carp;

my $clean_cache=0;
my $clean_start=0; # removes all done files etc.
my $refresh_lang;

GetOptions(
	'c|cleanstart!' => \$clean_start,
	'cleancache!' => \$clean_cache,
	'r|refresh=s' => \$refresh_lang,
	'v|verbose!' => \$Derbeth::Commons::verbose,
) or die;

if ($clean_start) {
	`rm -f audio/*.txt`;
}
if ($clean_cache) {
	Derbeth::Web::clear_cache();
}

Derbeth::Web::enable_caching(1);

my %categories = (
	ar => {
		include => ['Arabic pronunciation'],
	},
	arn => {
		include => ['Mapudungun pronunciation'],
	},
	ba => {
		include => ['Bashkir pronunciation'],
	},
	be => {
		include => ['Belarusian pronunciation'],
	},
	bg => {
		include => ['Bulgarian pronunciation'],
	},
	ce => {
		include => ['Chechen pronunciation'],
	},
	cs => {
		include => ['Czech pronunciation'],
		exclude => ['Spoken Wikinews - Czech'],
	},
	cy => {
		include => ['Welsh pronunciation'],
	},
	da => {
		include => ['Danish pronunciation'],
	},
	de => {
		single => ['Bavarian pronunciation'],
		include => ['German pronunciation'],
		exclude => ['German pronunciation of names of people'],
		reinclude => ['German pronunciation of given names'],
	},
	ee => {
		include => ['Ewe pronunciation'],
	},
	el => {
		include => ['Greek pronunciation'],
		exclude => ['Spoken Wikipedia - Greek'],
	},
	en => {
		single => ['English pronunciation of numbers'],
		include => ['English pronunciation'],
		exclude => ['Spoken Wikipedia - English'],
	},
	eo => {
		include => ['Esperanto pronunciation'],
	},
	es => {
		include => ['Spanish pronunciation'],
		exclude => ['Spanish audiobooks', 'Spanish pronunciation of names of people'],
	},
	eu => {
		include => ['Basque pronunciation'],
	},
	fa => {
		include => ['Persian pronunciation'],
	},
	fi => {
		include => ['Finnish pronunciation'],
	},
	fr => {
		single => ['Quebec French pronunciation'],
		include => ['French pronunciation'],
		exclude => ['Ogg sound files of spoken French', 'French pronunciation of names of people'],
		reinclude => ['French pronunciation of given names'],
	},
	fy => {
		include => ['Frisian pronunciation'],
	},
	ga => {
		include => ['Irish pronunciation'],
		exclude => ['L\'accent dans le gaëlique du Munster'],
	},
	gd => {
		include => ['Scottish Gaelic pronunciation'],
	},
	gl => {
		include => ['Galician pronunciation'],
	},
	he => {
		include => ['Hebrew pronunciation'],
	},
	hi => {
		include => ['Hindi pronunciation'],
		exclude => ['Spoken Wikipedia - Hindi'],
	},
	hr => {
		include => ['Croatian pronunciation'],
	},
	hsb => {
		include => ['Upper Sorbian pronunciation'],
	},
	hu => {
		include => ['Hungarian pronunciation'],
	},
	hy => {
		include => ['Armenian pronunciation'],
	},
	ia => {
		include => ['Interlingua pronunciation'],
	},
	id => {
		include => ['Indonesian pronunciation'],
	},
	is => {
		include => ['Icelandic pronunciation'],
		exclude => ['Icelandic pronunciation of Icelandic literature'],
	},
	it => {
		include => ['Italian pronunciation'],
		exclude => ['Ogg sound files of spoken Italian', 'Italian pronunciation of titles of classical music works',
			'Italian pronunciation of names of people',
			'Spoken Wikinews - Italian', 'Spoken Wikipedia - Italian'],
	},
	ja => {
		include => ['Japanese pronunciation'],
		exclude => ['Japanese pitch accents', 'Japanese audio files from Wikibooks'],
	},
	ka => {
		include => ['Georgian pronunciation'],
	},
	km => {
		include => ['Khmer pronunciation'],
	},
	ko => {
		include => ['Korean pronunciation'],
	},
	la => {
		include => ['Latin pronunciation'],
		exclude => ['Recitations in Latin'],
	},
	li => {
		include => ['Limburgish pronunciation'],
	},
	lv => {
		include => ['Latvian pronunciation'],
	},
	mg => {
		include => ['Malagasy pronunciation'],
	},
	nb => {
		include => ['Norwegian pronunciation'],
	},
	'ne' => {
		include => ['Nepali pronunciation'],
	},
	nl => {
		include => ['Dutch pronunciation'],
		exclude => ['Dutch pronunciation of buildings and places in Brussels',
			'Dutch dialect pronunciation','Dutch pronunciation of names of municipalities',
			'Dutch pronunciation of names of people',
			'Dutch pronunciation (wikibooks)'],
	},
	nv => {
		include => ['Navajo pronunciation'],
	},
	'or' => {
		include => ['Odia pronunciation'],
	},
	pam => {
		include	=> ['Kapampangan pronunciation'],
	},
	pl => {
		include => ['Polish pronunciation'],
		exclude	=> ['Spoken Wikipedia - Polish', 'Polish pronunciation of names of people'],
	},
	pt => {
		include => ['Portuguese pronunciation'],
	},
	roa => {
		single => ['Jèrriais pronunciation of names of countries'], # no capitalization hack here
		include => ['Jèrriais pronunciation'],
	},
	ro => {
		include => ['Romanian pronunciation'],
	},
	roh => {
		include => ['Romansh pronunciation'],
	},
	ru => {
		include	=> ['Russian pronunciation'],
	},
	sk => {
		include	=> ['Slovak pronunciation'],
	},
	sl => {
		include	=> ['Slovene pronunciation'],
		exclude	=> ['Audiobooks in Slovenian', 'Spoken Wikisource - Slovenian'],
	},
	sr => {
		include => ['Serbian pronunciation'],
		exclude => ['Serbian pronunciation of placenames', 'Spoken Wikipedia Serbian', 'Serbian pronunciation of names of people'],
	},
	sq => {
		include => ['Albanian pronunciation'],
		exclude => ['Ogg sound files of spoken Albanian'],
	},
	sv => {
		include => ['Swedish pronunciation'],
		exclude => ['Swedish pronunciation of names of people'],
	},
	ta => {
		include => ['Tamil pronunciation'],
		exclude => ['Tamil audio songs', 'Tamil audio articles', 'Tamil stories', 'Machine pronunciations'],
	},
	te => {
		include => ['Telugu pronunciation'],
	},
	th => {
		include => ['Thai pronunciation'],
	},
	tl => {
		include => ['Tagalog pronunciation'],
	},
	'tr' => {
		include => ['Turkish pronunciation'],
	},
	twi => {
		include => ['Twi pronunciation'],
	},
	uk => {
		include => ['Ukrainian pronunciation'],
		exclude => ['Spoken Wikipedia - Ukrainian'],
	},
	uz => {
		include => ['Uzbek pronunciation'],
	},
	yue => {
		include => ['Cantonese pronunciation'],
	},
	vi => {
		include => ['Vietnamese pronunciation'],
	},
	wo => {
		include => ['Wolof pronunciation'],
	},
	wym => {
		include => ['Vilamovian pronunciation'],
	},
	zh => {
		include => ['Chinese pronunciation'],
		exclude => ['Cantonese pronunciation','Shanghai dialect','Taiwanese pronunciation'],
	},
);
if ($refresh_lang) {
	my %filtered_categories;
	my @requested_langs = split /,/, $refresh_lang;
	my $all = $refresh_lang eq 'all';
	while (my ($lang, $keys) = each(%categories)) {
		if ($all || grep {$_ eq $lang} @requested_langs) {
			$filtered_categories{$lang} = $keys;
		}
	}
	%categories = %filtered_categories;
	die "no categories for lang code $refresh_lang" unless keys %categories;
	print STDERR "Refreshing $refresh_lang\n";
}

# 'en' => 'cat' => 'en-us-cat.ogg<us>|en-gb-cat.ogg<uk>
# 'de' => 'Katze' => 'de-Katze.ogg'
my %audio;

# each element contains data for one file with low priority
my @lp_audio;

my $NO_REGIONAL = '!';
my %many_vers;

# Parameters:
#   $lang - 'en', 'de', 'tur'
#   $key - 'cat', 'Warsaw', 'scharf'
#   $file - 'en-us-cat.ogg'
#   $regional - 'us' (optional)
#   $low_priority - if true, word should never replace word with the same key and regional
sub save_pron {
	my ($editor,$lang,$key,$file,$regional,$low_priority)=@_;
	confess "undefined: $lang $key" unless(defined($lang) && defined($key));
	if ($regional && $regional eq 'gb') { $regional = 'uk'; }

	my @keys = ($key);

	if ($key =~ /[a-zA-Z]+/) {
		my $latin = $&;
		my @detected = detect_pronounced_word($lang, $file, $editor);
		if ($#detected != -1) {
			print "$lang-", encode_utf8($key), ": detected words are '", encode_utf8(join(' ', @detected)), "'\n" if $Derbeth::Commons::verbose;
			@keys = @detected;
			$key = $detected[0];
		} elsif (latin_chars_disallowed($lang)) {
			print "$lang-",encode_utf8($key)," contains latin chars ($latin); won't be added\n" if $Derbeth::Commons::verbose;
			return;
		}
	}

	foreach my $k (@keys) {
		my @params = ($lang, $k, $file, $regional);
		if ($low_priority) {
			push @lp_audio, join('&', @params);
		} else {
			_save_pron_validated(@params);
		}
		_save_other_vers(@params);
	}
}

sub apply_low_priority {
	foreach my $row (@lp_audio) {
		my ($lang, $k, $file, $regional) = split(/&/, $row);
		_save_pron_validated($lang, $k, $file, $regional);
	}
}

# saved already validated file
# Parameters are the same as in save_pron().
sub _save_pron_validated {
	my ($lang,$key,$file,$regional)=@_;

	if (!exists($audio{$lang})) {
		$audio{$lang} = {};
	}

	my $entry;

	if(defined($regional) && $regional ne '') {
		if(exists($audio{$lang}{$key})
		&& index($audio{$lang}{$key}, "<$regional>") != -1) {
			return; # already has
		}

		$entry = "$file<$regional>";

	} else {
		if(exists($audio{$lang}{$key})) {
			my @current_audio = split /\|/, $audio{$lang}{$key};
			foreach my $entry_part (@current_audio) {
				if (index($entry_part, '<') == -1) {
					return; # already has non-regional pronunciation
				}
			}
		}

		$entry = $file;
	}

	if (!exists($audio{$lang}{$key})) {
		$audio{$lang}{$key} = $entry;
	} else {
		$audio{$lang}{$key} .= '|'.$entry;
	}
}

sub _save_other_vers {
	my ($lang, $key, $file, $regional) = @_;
	$regional ||= $NO_REGIONAL;
	$many_vers{$lang} ||= {};
	$many_vers{$lang}{$key} ||= {};
	$many_vers{$lang}{$key}{$regional} ||= [];
	unless (grep { $_ eq $file} @{$many_vers{$lang}{$key}{$regional}}) {
		push @{$many_vers{$lang}{$key}{$regional}}, $file;
	}
}

sub process_page {
	my ($page, $code, $cat, $editor) = @_;
	my ($file, @words) = word_pronounced_in_file($page, $code, $cat);
	foreach my $word (@words) {
		my $regional='';
		my $low_priority=0;
		$low_priority = 1 if $word =~ s/&$//;
		if ($word =~ /<([^>]+)>$/) {
			$word = $`;
			$regional = $1;
		}

		save_pron($editor, $code, $word, $file, $regional, $low_priority);
	}
}

my $server='http://commons.wikimedia.org/w/';
my $editor = Derbeth::Wikitools::create_editor($server);

foreach my $lang (sort keys %categories) {
	my $lang_conf = $categories{$lang};

	if (!$lang_conf->{single} && !$lang_conf->{include}) {
		print "$lang: no categories to include!\n";
		next;
	}

	if ($lang_conf->{single}) {
		foreach my $cat (sort @{$lang_conf->{single}}) {
			my @pages=Derbeth::Wikitools::get_category_contents_perlwikipedia($editor,'Category:'.$cat,undef,{file=>1},$refresh_lang);
			print "$lang: ", scalar(@pages), " pages in ", encode_utf8($cat), "\n";
			foreach my $page (sort @pages) {
				process_page($page, $lang, $cat, $editor);
			}
		}
	}

	if ($lang_conf->{include}) {
		my @excluded;
		push @excluded, @{$lang_conf->{exclude}} if $lang_conf->{exclude};
		push @excluded, @{$lang_conf->{single}} if $lang_conf->{single};
		my @pages = Derbeth::Wikitools::get_contents_include_exclude($editor,
			$lang_conf->{include} || [],
			\@excluded,
			$lang_conf->{reinclude} || [],
			{file=>1},
			$refresh_lang);
		print "$lang: ", scalar(@pages), " pages in all of ", encode_utf8(join ' ',@{$lang_conf->{include}}), "\n";

		my $main_included = $lang_conf->{include}->[0];
		die unless $main_included; # TODO remove me
		foreach my $page (sort @pages) {
			process_page($page, $lang, $main_included, $editor);
		}
	}
}

apply_low_priority();

system("mkdir audio") unless (-e 'audio');

foreach my $lang_code (sort(keys(%audio))) {
	my $audio_hash = $audio{$lang_code};
	open(OUT, '>audio/audio_'.$lang_code.'.txt') or die "cannot write $lang_code";

	print "filename: ",'audio/audio_',$lang_code,".txt: ", scalar(keys(%$audio_hash)), "\n";

	my @sorted_keys = sort(keys(%$audio_hash));
	foreach my $key (@sorted_keys) {
		my $files = $$audio_hash{$key};
	#while (my ($key,$files) = each(%$audio_hash)) {
		next if ($files eq '');
		#print "save\n";
		print OUT encode_utf8($key),'=',encode_utf8($files),"\n";
	}

	close(OUT);
}

unless($refresh_lang) {
	my $many_vers_saved = 0;
	open(OUT, '>audio/many_vers.txt') or die "cannot write many_vers: $!";
	foreach my $lang_code (sort keys %many_vers) {
		foreach my $key (sort keys %{$many_vers{$lang_code}}) {
			foreach my $regional (sort keys %{$many_vers{$lang_code}{$key}}) {
				my @files = @{$many_vers{$lang_code}{$key}{$regional}};
				if (scalar(@files) > 1) {
					print OUT encode_utf8("$lang_code|$key|$regional"), '=', encode_utf8(join('|', sort @files)), "\n";
					++$many_vers_saved;
				}
			}
		}
	}
	close(OUT);
	print "Saved $many_vers_saved words with many versions\n";
}
