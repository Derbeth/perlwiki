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

use Derbeth::Wikitools;
use Derbeth::Commons;
use Encode;
use Getopt::Long;
use Carp;
use utf8;

my $clean_cache=0;
my $clean_start=0; # removes all done files etc.
my $refresh_lang;

GetOptions(
	'c|cleanstart!' => \$clean_start,
	'cleancache!' => \$clean_cache,
	'r|refresh=s' => \$refresh_lang,
) or die;

if ($clean_start) {
	`rm -f audio/*.txt`;
}
if ($clean_cache) {
	Derbeth::Web::clear_cache();
}

Derbeth::Web::enable_caching(1);

my %categories=(
	'Albanian pronunciation' => 'sq',
	'Arabic pronunciation' => 'ar',
	'Armenian pronunciation'=>'hy',
	'Bashkir pronunciation' => 'ba',
	'Basque pronunciation' => 'eu',
	'Belarusian pronunciation'=>'be',
	'Belarusian pronunciation of names of countries'=>'be',
	'Bulgarian pronunciation' => 'bg',
	'Cantonese pronunciation' => 'yue',
	'Chechen pronunciation'=>'ce',
	'Chinese pronunciation' => 'zh',
	'Chinese pronunciation of names of countries' => 'zh',
	'Mandarin pronunciation' => 'zh',
	'Croatian pronunciation'=>'hr',
	'Croatian pronunciation of names of countries'=>'hr',
	'Czech pronunciation' => 'cs',
	'Czech prepositions' => 'cs',
	'Czech pronunciation of names' => 'cs',
	'Czech pronunciation of names of cities' => 'cs',
	'Czech pronunciation of names of countries' => 'cs',
	'Czech pronunciation of names of people' => 'cs',
	'Czech pronunciation of nationalities' => 'cs',
	'Czech pronunciation of numbers' => 'cs',
	'Czech pronunciation of planets' => 'cs',
	'Czech pronunciation of proverbs' => 'cs',
	'Adjectives in Czech pronunciation' => 'cs',
	'Nouns in Czech pronunciation' => 'cs',
	'Pronunciation of names of rivers in the Czech Republic' => 'cs',
	'Danish pronunciation' => 'da',
	'Danish pronunciation of names of countries' => 'da',
	'Dutch pronunciation' => 'nl',
	'Dutch pronunciation of geographical entities' => 'nl',
	'Dutch pronunciation of names of countries' => 'nl',
	'Dutch pronunciation of numbers' => 'nl',
	'Dutch pronunciation of phrases' => 'nl',
	'English pronunciation' => 'en',
	'Australian English pronunciation' => 'en',
	'British English pronunciation' => 'en',
	'Canadian English pronunciation' => 'en',
	'English pronunciation of names' => 'en',
	'English pronunciation of names of cities' => 'en',
	'English pronunciation of names of countries' => 'en',
	'English pronunciation of names of rivers' => 'en',
	'English pronunciation of numbers' => 'en', # letter size!
	'English pronunciation of states of the United States' => 'en',
	'English pronunciation of terms' => 'en',
	'New Zealand English pronunciation' => 'en',
	'U.S. English pronunciation' => 'en',
	'Esperanto pronunciation' => 'eo',
	'Esperanto pronunciation of names of cities' => 'eo',
	'Esperanto pronunciation of names of countries' => 'eo',
	'Ewe pronunciation' => 'ee',
	'Farsi pronunciation' => 'fa',
	'Farsi pronunciation of names of cities' => 'fa',
	'Farsi pronunciation of names of countries' => 'fa',
	'Finnish pronunciation' => 'fi',
	'Finnish pronunciation of names of countries' => 'fi',
	'French pronunciation' => 'fr', # letter size
	'French pronunciation of chemical compounds' => 'fr',
	'French pronunciation of chemical elements' => 'fr',
	'French pronunciation of common nouns' => 'fr',
	'French pronunciation of currency' => 'fr',
	'French pronunciation of days' => 'fr',
	'French pronunciation of expressions' => 'fr',
	'French pronunciation of French departments' => 'fr',
	'French pronunciation of fruit' => 'fr',
	'French pronunciation of kinship' => 'fr',
	'French pronunciation of months' => 'fr',
	'French pronunciation of names of colors' => 'fr',
	'French pronunciation of names of countries' => 'fr', # la, l' un
	'French pronunciation of the names of planets' => 'fr',
	'French pronunciation of nouns' => 'fr',
	'French pronunciation of numbers' => 'fr', # letter size
	'French pronunciation of plants' => 'fr',
	'French pronunciation of subatomic particles' => 'fr',
	'French pronunciation of units of measure' => 'fr',
	'French pronunciation of verbs' => 'fr',
	'French pronunciation of words relating to animals' => 'fr',
	'French pronunciation of words relating to birds' => 'fr',
	'French pronunciation of words relating to fishes' => 'fr',
	'French pronunciation of words relating to mammals' => 'fr',
	'Quebec French pronunciation' => 'fr',
	'Frisian pronunciation' => 'fy', # West Frisian
	'Galician pronunciation' => 'gl',
	'Georgian pronunciation' => 'ka',
	'German pronunciation' => 'de',
	'Austrian pronunciations' => 'de',
	'Bavarian pronunciation' => 'de',
	'German pronunciation of names of cities' => 'de',
	'German pronunciation of names of colors' => 'de',
	'German pronunciation of names of countries' => 'de',
	'German pronunciation of numbers' => 'de',
	'German pronunciation of planets' => 'de',
	'Greek pronunciation' => 'el',
	'Hebrew pronunciation' => 'he',
	'Hindi pronunciation' => 'hi',
	'Hungarian pronunciation' => 'hu',
	'Hungarian pronunciation of birds' => 'hu',
	'Hungarian pronunciation of flowers' => 'hu',
	'Hungarian pronunciation of fruit' => 'hu',
	'Hungarian pronunciation of months' => 'hu',
	'Hungarian pronunciation of musical instruments' => 'hu',
	'Hungarian pronunciation of names' => 'hu',
	'Hungarian pronunciation of names of cities' => 'hu',
	'Hungarian pronunciation of names of colors' => 'hu',
	'Hungarian pronunciation of names of countries' => 'hu',
	'Hungarian pronunciation of nationalities' => 'hu',
	'Hungarian pronunciation of numbers' => 'hu',
	'Icelandic pronunciation' => 'is', # no prefix, letter size
	'Indonesian pronunciation' => 'id',
	'Interlingua pronunciation' => 'ia',
	'Irish pronunciation' => 'ga',
	'Italian pronunciation' => 'it',
	'Italian pronunciation of names of cities' => 'it',
	'Italian pronunciation of names of countries' => 'it',
	'Italian pronunciation of the names of planets' => 'it',
	'Japanese pronunciation' => 'ja',
	'Japanese pronunciation of names of countries' => 'ja',
	'Pronunciation of names of places in Japan' => 'ja',
	'Pronunciation of Japanese numbers' => 'ja',
	'Pronunciation of Japanese words' => 'ja',
	'Jèrriais pronunciation' => 'roa',
	'Jèrriais pronunciation of adjectives' => 'roa',
	'Jèrriais pronunciation of adverbs' => 'roa',
	'Jèrriais pronunciation of names' => 'roa',
	'Jèrriais pronunciation of names of colors' => 'roa',
	'Jèrriais pronunciation of names of countries' => 'roa',
	'Jèrriais pronunciation of numbers' => 'roa',
	'Jèrriais pronunciation of verbs' => 'roa',
	'Kapampangan pronunciation' => 'pam',
	'Korean pronunciation' => 'ko',
	'Latin pronunciation' => 'la',
	'Latvian pronunciation' => 'lv', # wrong naming
	'Latvian pronunciation of names of countries' => 'lv',
	'Limburgish pronunciation' => 'li',
	'Malagasy pronunciation' => 'mg',
	'Mapudungun pronunciation' => 'arn',
	'Navajo pronunciation' => 'nv',
	'Norwegian pronunciation' => 'nb',
	'Norwegian pronunciation of adjectives' => 'nb',
	'Norwegian pronunciation of adverbs' => 'nb',
	'Norwegian pronunciation of nouns' => 'nb',
	'Norwegian pronunciation of verbs' => 'nb',
	'Odia pronunciation' => 'or',
	'Polish pronunciation' => 'pl',
	'Polish pronunciation of islands' => 'pl',
	'Polish pronunciation of names of cities' => 'pl',
	'Polish pronunciation of names of countries' => 'pl',
	'Polish pronunciation of nationalities' => 'pl',
	'Polish pronunciation of numbers' => 'pl',
	'Portuguese pronunciation' => 'pt',
	'Portuguese pronunciation of names of countries' => 'pt',
	'Romanian pronunciation' => 'ro',
	'Romanian pronunciation of names of cities' => 'ro',
	'Romanian pronunciation of names of countries' => 'ro',
	'Romansh pronunciation' => 'roh',
	'Sursilvan pronunciation' => 'roh',
	'Russian pronunciation' => 'ru',
	'Russian pronunciation of names of cities' => 'ru',
	'Russian pronunciation of names of colors' => 'ru',
	'Russian pronunciation of names of countries' => 'ru',
	'Russian pronunciation of states of the United States' => 'ru',
	'Russian words' => 'ru',
	'Scottish Gaelic pronunciation' => 'gd',
	'Serbian pronunciation' => 'sr', # capitalisation problems
	'Serbian pronunciation of adverbs' => 'sr',
	'Serbian pronunciation of names of countries' => 'sr',
	'Serbian pronunciation of nouns' => 'sr',
	'Serbian pronunciation of numbers' => 'sr',
	'Serbian pronunciation of verbs' => 'sr',
	'Slovak pronunciation' => 'sk',
	'Slovak pronunciation of names of cities' => 'sk',
	'Slovak pronunciation of names of countries' => 'sk',
	'Slovene pronunciation' => 'sl',
	'Slovenian pronunciation of cities' => 'sl',
	'Slovenian pronunciation of names of countries' => 'sl',
	'Spanish pronunciation' => 'es', # wrong naming, odd regional
	'Spanish pronunciation of names of countries' => 'es',
	'Andean Spanish pronunciation' => 'es',
	'Mexican Spanish pronunciation' => 'es',
	'Peruvian Coast Spanish pronunciation' => 'es',
	'Swedish pronunciation' => 'sv',
	'Swedish consonants' => 'sv',
	'Swedish vowels' => 'sv',
	'Swedish pronunciation of names of cities' => 'sv',
	'Swedish pronunciation of names of countries' => 'sv',
	'Swedish pronunciation of numbers' => 'sv',
	'Tagalog pronunciation' => 'tl',
	'Tamil pronunciation' => 'ta',
	'Thai pronunciation' => 'th',
	'Turkish pronunciation' => 'tr',
	'Twi pronunciation' => 'twi',
	'Ukrainian pronunciation' => 'uk',
	'Ukranian pronunciation of names of cities' => 'uk',
	'Ukrainian pronunciation of names of countries' => 'uk',
	'Upper Sorbian pronunciation' => 'hsb',
	'Vietnamese pronunciation' => 'vi',
	'Wymysorys pronunciation (Józef Gara\'s version)' => 'wym',
	'Welsh pronunciation' => 'cy',
	'Welsh pronunciation of adjectives' => 'cy',
	'Welsh pronunciation of names of colors' => 'cy',
	'Welsh pronunciation of days' => 'cy',
	'Welsh pronunciation of given names' => 'cy',
	'Welsh pronunciation of names of countries' => 'cy',
	'Welsh pronunciation of names of languages' => 'cy',
	'Welsh pronunciation of months' => 'cy',
	'Welsh pronunciation of nouns' => 'cy',
	'Welsh pronunciation of numbers' => 'cy',
	'Welsh pronunciation of verbs' => 'cy',
	'Welsh pronunciation of words relating to animals' => 'cy',
	'Wolof pronunciation' => 'wo',
);
if ($refresh_lang) {
	my %filtered_categories;
	while (my ($cat, $lang) = each(%categories)) {
		if ($refresh_lang eq 'all' || $lang eq $refresh_lang) {
			$filtered_categories{$cat} = $lang;
		}
	}
	%categories = %filtered_categories;
	die "no categories for lang code $refresh_lang" unless keys %categories;
	print STDERR "Refreshing ", scalar(keys %categories), " categories for $refresh_lang\n";
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
			print "$lang-", encode_utf8($key), ": detected words are '", encode_utf8(join(' ', @detected)), "'\n";
			@keys = @detected;
			$key = $detected[0];
		} elsif (latin_chars_disallowed($lang)) {
			print "$lang-",encode_utf8($key)," contains latin chars ($latin); won't be added\n";
			return;
		}
	}
	if ($file =~ /-synth-/) {
		print encode_utf8($file), " ignored because is synthesized\n";
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

my $server='http://commons.wikimedia.org/w/';
my $editor = Derbeth::Wikitools::create_editor($server);

foreach my $cat (sort(keys(%categories))) {
	my $code = $categories{$cat};
	my @pages=Derbeth::Wikitools::get_category_contents_perlwikipedia($editor,'Category:'.$cat,undef,{file=>1},$refresh_lang);
	print 'Category: ',encode_utf8($cat),' pages: ';
	print scalar(@pages), "\n";

	foreach my $page (sort @pages) {
		$page =~ s/&#039;/'/g;

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
