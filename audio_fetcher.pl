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

GetOptions(
	'c|cleanstart!' => \$clean_start,
	'cleancache!' => \$clean_cache,
	'p|perlwikipedia' => \$Derbeth::Wikitools::use_perlwikipedia,
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
	'Basque pronunciation' => 'eu',
	'Belarusian pronunciation'=>'be',
	'Belarusian pronunciation of names of countries'=>'be',
	'Bulgarian pronunciation' => 'bg',
	'Chechen pronunciation'=>'ce',
	'Chinese pronunciation' => 'zh',
	'Chinese pronunciation of names of countries' => 'zh',
	'Croatian pronunciation'=>'hr',
	'Croatian pronunciation of names of countries'=>'hr',
	'Czech pronunciation' => 'cs',
	'Czech prepositions' => 'cs',
	'Czech pronunciation of names' => 'cs',
	'Czech pronunciation of names of cities' => 'cs',
	'Czech pronunciation of names of countries' => 'cs',
	'Czech pronunciation of numbers' => 'cs',
	'Czech pronunciation of plants' => 'cs',
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
	'Dutch name pronunciation' => 'nl',
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
	'Esperanto pronunciation' => 'eo',
	'Farsi pronunciation' => 'fa',
	'Farsi pronunciation of names of cities' => 'fa',
	'Farsi pronunciation of names of countries' => 'fa',
	'Finnish pronunciation' => 'fi',
	'Finnish pronunciation of names of countries' => 'fi',
	'French pronunciation' => 'fr', # letter size
	'French pronunciation of chemical elements' => 'fr',
	'French pronunciation of days' => 'fr',
	'French pronunciation of French departments' => 'fr',
	'French pronunciation of fruit' => 'fr',
	'French pronunciation of names of colors' => 'fr',
	'French pronunciation of names of countries' => 'fr', # la, l' un
	'French pronunciation of nouns' => 'fr',
	'French pronunciation of numbers' => 'fr', # letter size
	'French pronunciation of planets' => 'fr',
	'French pronunciation of verbs' => 'fr',
	'French pronunciation of words relating to animals' => 'fr',
	'French pronunciation of words relating to birds' => 'fr',
	'French pronunciation of words relating to fishes' => 'fr',
	'French pronunciation of words relating to mammals' => 'fr',
	'Pronunciation of names of municipalities of France' => 'fr',
	'Frisian pronunciation' => 'fy', # West Frisian
	'Georgian pronunciation' => 'ka',
	'German pronunciation' => 'de',
	'Austrian pronunciations' => 'de',
	'Bavarian pronunciation' => 'de',
	'German pronunciation of names of cities' => 'de',
	'German pronunciation of names of colors' => 'de',
	'German pronunciation of names of countries' => 'de',
	'German pronunciation of numbers' => 'de',
	'Greek pronunciation' => 'el',
	'Hebrew pronunciation' => 'he',
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
	'Japanese pronunciation' => 'ja',
	'Japanese pronunciation of names of countries' => 'ja',
	'Pronunciation of names of places in Japan' => 'ja',
	'Pronunciation of Japanese numbers' => 'ja',
	'Pronunciation of Japanese words' => 'ja',
	'Jèrriais pronunciation' => 'roa',
	'Jèrriais pronunciation of names of colors' => 'roa',
	'Jèrriais pronunciation of names of countries' => 'roa',
	'Kapampangan pronunciation' => 'pam',
	'Korean pronunciation' => 'ko',
	'Latin pronunciation' => 'la',
	'Latvian pronunciation' => 'lv', # wrong naming
	'Latvian pronunciation of names of countries' => 'lv',
	'Limburgish pronunciation' => 'li',
	'Mapudungun pronunciation' => 'arn',
	'Norwegian pronunciation' => 'nb',
	'Norwegian pronunciation of adjectives' => 'nb',
	'Norwegian pronunciation of adverbs' => 'nb',
	'Norwegian pronunciation of nouns' => 'nb',
	'Norwegian pronunciation of verbs' => 'nb',
	'Polish pronunciation' => 'pl',
	'Polish pronunciation of islands' => 'pl',
	'Polish pronunciation of names of cities' => 'pl',
	'Polish pronunciation of names of countries' => 'pl',
	'Polish pronunciation of nationalities' => 'pl',
	'Portuguese pronunciation' => 'pt',
	'Portuguese pronunciation of names of countries' => 'pt',
	'Romanian pronunciation' => 'ro',
	'Romanian pronunciation of names of cities' => 'ro',
	'Romanian pronunciation of names of countries' => 'ro',
	'Romansh pronunciation' => 'roh',
	'Russian pronunciation' => 'ru',
	'Russian pronunciation of names of cities' => 'ru',
	'Russian pronunciation of names of colors' => 'ru',
	'Russian pronunciation of names of countries' => 'ru',
	'Russian pronunciation of states of the United States' => 'ru',
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
	'Slovenian pronunciation' => 'sl',
	'Slovenian pronunciation of cities' => 'sl',
	'Slovenian pronunciation of names of countries' => 'sl',
	'Spanish pronunciation' => 'es', # wrong naming, odd regional
	'Spanish pronunciation of names of countries' => 'es',
	'Mexican Spanish pronunciation' => 'es',
	'Swedish pronunciation' => 'sv',
	'Swedish consonants' => 'sv',
	'Swedish vowels' => 'sv',
	'Swedish pronunciation of names of cities' => 'sv',
	'Swedish pronunciation of names of countries' => 'sv',
	'Swedish pronunciation of numbers' => 'sv',
	'Tagalog pronunciation' => 'tl',
	'Thai pronunciation' => 'th',
	'Turkish pronunciation' => 'tr',
	'Twi pronunciation' => 'twi',
	'Ukrainian pronunciation' => 'uk',
	'Ukranian pronunciation of names of cities' => 'uk',
	'Ukrainian pronunciation of names of countries' => 'uk',
	'Upper Sorbian pronunciation' => 'hsb',
	'Vietnamese pronunciation' => 'vi',
	'Welsh pronunciation' => 'cy',
	'Wolof pronunciation' => 'wo',
);
#%categories=('Welsh pronunciation' => 'cy','Albanian pronunciation' => 'sq');

# 'en' => 'cat' => 'en-us-cat.ogg<us>|en-gb-cat.ogg<uk>
# 'de' => 'Katze' => 'de-Katze.ogg'
my %audio;

# each element contains data for one file with low priority
my @lp_audio;

# Parameters:
#   $lang - 'en', 'de', 'tur'
#   $key - 'cat', 'Warsaw', 'scharf'
#   $file - 'en-us-cat.ogg'
#   $regional - 'us' (optional)
#   $low_priority - if true, word should never replace word with the same key and regional
sub save_pron {
	my ($lang,$key,$file,$regional,$low_priority)=@_;
	confess "undefined: $lang $key" unless(defined($lang) && defined($key));
	if ($regional && $regional eq 'gb') { $regional = 'uk'; }

	my @keys = ($key);

	if ($key =~ /[a-zA-Z]/) {
		my @detected = detect_pronounced_word($lang, $file);
		if ($#detected != -1) {
			print "$lang-$key: detected words are '", encode_utf8(join(' ', @detected)), "'\n";
			@keys = @detected;
			$key = $detected[0];
		} elsif ($lang =~ /^(ar|be|el|fa|he|ja|ka|ko|mk|ru|th|uk)$/) {
			print "$lang-",encode_utf8($key)," contains latin chars; won't be added\n";
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

my $server='http://commons.wikimedia.org/w/';

foreach my $cat (sort(keys(%categories))) {
	my $code = $categories{$cat};
	my @pages=get_category_contents($server,'Category:'.$cat);
	print 'Category: ',encode_utf8($cat),' pages: ';
	print scalar(@pages), "\n";

	foreach my $page (@pages) {
		$page =~ s/&#039;/'/g;

		my ($file, @words) = word_pronounced_in_file($page, $code);
		foreach my $word (@words) {
			my $regional='';
			my $low_priority=0;
			if ($word =~ /<([^>]+)>$/) {
				$word = $`;
				$regional = $1;
			}
			$low_priority = 1 if $word =~ s/&$//;

			save_pron($code, $word, $file, $regional, $low_priority);
		}
	}
}

apply_low_priority();

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

