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
use Encode;
use Getopt::Long;
use utf8;

my $clean_cache=0;
my $clean_start=0; # removes all done files etc.

GetOptions(
	'c|cleanstart!' => \$clean_start,
	'cleancache!' => \$clean_cache,
	'p|perlwikipedia' => \$Derbeth::Wikitools::use_perlwikipedia,
);

if ($clean_start) {
	`rm -f audio/*.txt`;
}
if ($clean_cache) {
	Derbeth::Web::clear_cache();
}

Derbeth::Web::enable_caching(1);

my %categories=(
#  	'Albanian pronunciation' => 'sq',
#  	'Armenian pronunciation'=>'hy',
#  	'Belarusian pronunciation'=>'be',
#  	'Belarusian pronunciation of countries'=>'be',
# 	'Chinese pronunciation' => 'zh',
# 	'Croatian pronunciation'=>'hr',
# 	'Croatian pronunciation of countries'=>'hr',
# 	'Chechen pronunciation'=>'ce',
# 	'Czech pronunciation' => 'cs',
# 	'Czech prepositions' => 'cs',
# 	'Czech pronunciation of cities' => 'cs',
# 	'Czech pronunciation of countries' => 'cs',
# 	'Czech pronunciation of names' => 'cs',
# 	'Czech pronunciation of numbers' => 'cs',
# 	'Czech pronunciation of rivers' => 'cs',
# 	'Danish pronunciation' => 'da',
# 	'Danish pronunciation of countries' => 'da',
# 	'Dutch pronunciation' => 'nl',
# 	'Dutch pronunciation of countries' => 'nl',
# 	'Dutch name pronunciation' => 'nl',
# 	'English pronunciation' => 'en',
# 	'British English pronunciation' => 'en',
# 	'English pronunciation of countries' => 'en',
# 	'English pronunciation of numbers' => 'en', # letter size!
# 	'English pronunciation of rivers' => 'en',
# 	'English pronunciation of states of the United States' => 'en',
# 	'English pronunciation of terms' => 'en',
# 	'Esperanto pronunciation' => 'eo',
# 	'Farsi pronunciation' => 'fa',
# 	'Finnish pronunciation' => 'fi',
# 	'Finnish pronunciation of countries' => 'fi',
# 	'French pronunciation' => 'fr', # letter size
# 	'French pronunciation of animals' => 'fr', # pauses
# 	'French pronunciation of chemical elements' => 'fr',
# 	'French pronunciation of colors' => 'fr',
# 	'French pronunciation of countries' => 'fr', # la, l' un
# 	'French pronunciation of days' => 'fr',
# 	'French pronunciation of fruit' => 'fr',
# 	'French pronunciation of nouns' => 'fr',
# 	'French pronunciation of numbers' => 'fr', # letter size
# 	'French pronunciation of planets' => 'fr',
# 	'French pronunciation of verbs' => 'fr',
# 	'Georgian pronunciation' => 'ka',
# 	'German pronunciation' => 'de',
# 	'Austrian pronunciations' => 'de',
# 	'Bavarian pronunciation' => 'de',
# 	'German pronunciation of cities' => 'de',
# 	'German pronunciation of countries' => 'de',
# 	'German pronunciation of numbers' => 'de',
# 	'Greek pronunciation' => 'el',
# 	'Hungarian pronunciation' => 'hu',
# 	'Hungarian pronunciation of adjectives' => 'hu',
# 	'Hungarian pronunciation of birds' => 'hu',
# 	'Hungarian pronunciation of cities' => 'hu',
# 	'Hungarian pronunciation of countries' => 'hu',
# 	'Hungarian pronunciation of flowers' => 'hu',
# 	'Hungarian pronunciation of fruit' => 'hu',
# 	'Hungarian pronunciation of months' => 'hu',
# 	'Hungarian pronunciation of musical instruments' => 'hu',
# 	'Hungarian pronunciation of names' => 'hu',
# 	'Hungarian pronunciation of nationalities' => 'hu',
# 	'Hungarian pronunciation of numbers' => 'hu',
# 	'Icelandic pronunciation' => 'is', # no prefix, letter size
# 	'Indonesian pronunciation' => 'id',
# 	'Interlingua pronunciation' => 'ia',
# 	'Irish pronunciation' => 'ga',
# 	'Italian pronunciation' => 'it',
# 	'Italian pronunciation of countries' => 'it',
# 	'Jèrriais pronunciation' => 'roa',
# 	'Jèrriais pronunciation of countries' => 'roa',
# 	'Latin pronunciation' => 'la',
# 	'Latvian pronunciation' => 'lv', # wrong naming
# 	'Latvian pronunciation of countries' => 'lv',
# 	'Norwegian pronunciation' => 'nb',
# 	'Norwegian pronunciation of adjectives' => 'nb',
# 	'Norwegian pronunciation of adverbs' => 'nb',
# 	'Norwegian pronunciation of nouns' => 'nb',
# 	'Norwegian pronunciation of verbs' => 'nb',
# 	'Polish pronunciation' => 'pl',
# 	'Polish pronunciation of cities' => 'pl',
# 	'Polish pronunciation of countries' => 'pl',
# 	'Polish pronunciation of islands' => 'pl',
# 	'Portuguese pronunciation' => 'pt',
# 	'Portuguese pronunciation of countries' => 'pt',
# 	'Romanian pronunciation' => 'ro',
# 	'Russian pronunciation' => 'ru',
# 	'Russian pronunciation of cities' => 'ru',
# 	'Russian pronunciation of countries' => 'ru',
# 	'Russian pronunciation of states of the United States' => 'ru',
# 	'Serbian pronunciation' => 'sr', # capitalisation problems
# 	'Serbian pronunciation of adverbs' => 'sr',
# 	'Serbian pronunciation of countries' => 'sr',
# 	'Serbian pronunciation of nouns' => 'sr',
# 	'Serbian pronunciation of numbers' => 'sr',
# 	'Serbian pronunciation of verbs' => 'sr',
# 	'Slovak pronunciation' => 'sk',
# 	'Slovak pronunciation of countries' => 'sk',
#  	'Spanish pronunciation' => 'es', # wrong naming, odd regional
#  	'Spanish pronunciation of countries' => 'es',
# 	'Swedish pronunciation' => 'sv',
# 	'Swedish consonants' => 'sv',
# 	'Swedish vowels' => 'sv',
# 	'Swedish pronunciation of countries' => 'sv',
# 	'Swedish pronunciation of numbers' => 'sv',
	'Tagalog pronunciation' => 'tl',
# 	'Turkish pronunciation' => 'tr',
# 	'Vietnamese pronunciation' => 'vi',
# 	'Ukrainian pronunciation' => 'uk',
# 	'Ukrainian pronunciation of countries' => 'uk',
# 	'Upper Sorbian pronunciation' => 'hsb',
# 	'Welsh pronunciation' => 'cy',
# 	'Wolof pronunciation' => 'wo',
);
#%categories=('Welsh pronunciation' => 'cy','Albanian pronunciation' => 'sq');

# 'en' => 'cat' => 'en-us-cat.ogg<us>|en-gb-cat.ogg<uk>
# 'de' => 'Katze' => 'de-Katze.ogg'
my %audio;

my %regional_fr = ('fr-Paris' => 'Paris', 'fr FR-Paris' => 'Paris',
	'ca-Montréal' => 'ca', 'fr BE' => 'be', 'fr CA' => 'ca');
# normal language code => regexp for matching alternative code
my %code_alias=('tr'=>'tur','la'=>'lat', 'de'=>'by', 'el' => 'ell', 'nb' => 'no',
	'roa' => 'jer');

# Parameters:
#   $lang - 'en', 'de', 'tur'
#   $key - 'cat', 'Warsaw', 'scharf'
#   $file - 'en-us-cat.ogg'
#   $regional - 'us' (optional)
sub save_pron {
	
	my ($lang,$key,$file,$regional)=@_;
	die "undefined: $lang $key" unless($lang && $key);
	if ($regional eq 'gb') { $regional = 'uk'; }
	
	if ($lang =~ /^(be|el|fa|ka|mk|ru|uk)$/ && $key =~ /[a-zA-Z]/) {
		print "$lang-",encode_utf8($key)," contains latin chars; won't be added\n";
		return;
	}
	
	if (!exists($audio{$lang})) {
		$audio{$lang} = {};
	}
	
	if (!exists($audio{$lang}{$key})) {
		$audio{$lang}{$key} = $file;
		return;
	}
	
	my $entry;
	
	if(defined($regional) && $regional ne '') {
		if( index($audio{$lang}{$key}, "<$regional>") != -1) {
			return; # already has
		}
		
		$entry = "$file<$regional>";

	} else {
		my @current_audio = split /\|/, $audio{$lang}{$key};
		foreach my $entry_part (@current_audio) {
			if (index($entry_part, '<') == -1) {
				return; # already has non-regional pronunciation
			}
		}
		
		$entry = $file;
	}
	
	$audio{$lang}{$key} .= '|'.$entry;
}

my $server='http://commons.wikimedia.org/w/';

while (my($cat,$code) = each(%categories)) {
	my @pages=get_category_contents($server,'Category:'.$cat);
	print 'Category: ',encode_utf8($cat),' pages: ';
	print scalar(@pages), "\n";
	
	foreach my $page (@pages) {
		$page =~ s/&#039;/'/g;

		next if ($page !~ /(?:File|Image):(.+)\.(ogg|OGG)/);
		$page = $1.'.'.$2;
		my $main_text = $1;
		
		my $skip_key_extraction=0;
		my $key;
		my $regional='';
		
		# === Non-standard naming goes here
		if ($cat =~ /^Latvian pronunciation/) {
			if ($main_text =~ /^Latvian pronunciation (.*)$/) {
				save_pron($code,$1,$page);
				next;
			}
		}
		elsif ($code eq 'cy' && $main_text !~ /cy-/i) {
			save_pron($code,$main_text,$page);
			save_pron($code,lcfirst($main_text),$page);
			next;
		}
		elsif ($cat =~ /^Bavarian /) {
			$regional = 'by';
		}
		elsif ($code eq 'de') {
			if ($main_text =~ /^CPIDL German - /) {
				save_pron($code,lcfirst($POSTMATCH),$page);
				next;
			}
		}
		elsif ($code eq 'en') {
			if ($main_text =~ /^Ca-en-/i) {
				save_pron($code,$POSTMATCH,$page);
				next;
			}
		}
		elsif ($code eq 'es') {
			if ($main_text =~ /^Es-/i) {
				# ok
			} elsif ($main_text =~ /^Spanish /) {
				save_pron($code,$POSTMATCH,$page);
				next;
			} else {
				next;
			}
		}
		elsif ($code eq 'it') {
			if ($main_text =~ /^Italian /) {
				save_pron($code,$POSTMATCH,$page);
				next;
			}
		}
		elsif ($code eq 'is') {
			save_pron($code,$main_text,$page);
			save_pron($code,lcfirst($main_text),$page);
			next;
		}
		elsif ($code eq 'sq') {
			if ($main_text =~ /^Albanian /) {
				save_pron($code,$POSTMATCH,$page);
				next;
			}
		}
		elsif ($code eq 'vi') {
			if ($main_text =~ /^Vi-hanoi-m-/) {
				save_pron($code,$POSTMATCH,$page);
				next;
			}
		}
		
		# === end non-standard naming
		
		unless ($skip_key_extraction) {
			my $lang_code;
			if (exists($code_alias{$code})) {
				$lang_code = "($code|$code_alias{$code})";
			} else {
				$lang_code=$code;
			}
			if ($main_text !~ /^$lang_code[ -]/i) { # case-insensitive
				print 'not a pronunciation file: ',encode_utf8($page),"\n";
				next;
			}
			$key = $POSTMATCH;
		}
		
		# === Regional parts stripping goes here
		if ($code eq 'la') {
			if ($key =~ /^(ecc|cls)-/) {
				$regional = $1;
				$key = $POSTMATCH;
			}
		}
		elsif ($code eq 'en') {
			if ($key =~ /^(us-inlandnorth|us|uk|ca|nz|gb|au)-/i) {
				$regional = lc($1);
				$key = $POSTMATCH;
			}
		}
		elsif ($code eq 'pt') {
			if ($key =~ /^(br|pt)-/) {
				$regional = $1 if ($1 ne 'pt');
				$key = $POSTMATCH;
			}
		}
		elsif ($code eq 'es') {
			if ($key =~ /-bo-La Paz$/) {
				$regional = 'bo';
				$key = $PREMATCH;
			}
		}
		elsif ($code eq 'fr') {
			$key =~ s/^fr-//i;
			if ($key =~ s/^Paris-{1,2}(.)/$1/) {
				$regional = 'Paris';
			}
			$key =~ s/^(une|un|les|le|la)[ -]//gi;
			$key =~ s/^l'//gi;
			if ($key =~ /-(fr-ouest|fr-Paris|fr FR-Paris|ca-Montréal|fr BE|fr CA|fr)$/i) {
				if (exists($regional_fr{$1})) {
					$regional = $regional_fr{$1};
				}
				$key = $PREMATCH;
			}
		}
		elsif ($code eq 'sv') {
			$key =~ s/^en //g;
		}
		elsif ($code eq 'de') {
			$key =~ s/-pronunciation$//;
			if ($key =~ /^(at)-/) {
				$regional = $1;
				$key = $POSTMATCH;
			}
		}
		elsif ($code eq 'tl') {
			if ($key =~ /^ph-/i) {
				# all Tagalog is spoken in Phillipines; it's not regional, so ignore
				$key = $POSTMATCH;
			}
		}
		# == end regional
		
		save_pron($code,$key,$page,$regional);
		
		# === Letter size problems go here
		if ($cat eq 'English pronunciation of numbers'
		#||  $cat eq 'French pronunciation'
		||  $cat eq 'Finnish pronunciation'
		||  $cat eq 'French pronunciation of numbers'
		||  $cat eq 'Jèrriais pronunciation'
		||  $code eq 'sr'
		) {
		
			save_pron($code,lcfirst($key),$page,$regional);
		}
	}
}

while (my ($lang_code, $audio_hash) = each(%audio)) {
	open(OUT, '>audio/audio_'.$lang_code.'.txt');
	
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
