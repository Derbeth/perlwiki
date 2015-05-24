# MIT License
#
# Copyright (c) 2011 Derbeth
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

package Derbeth::Commons;
require Exporter;

use strict;
use utf8;
use English;

use Carp;
use Encode;
use Derbeth::Wikitools;
use Derbeth::Util;
use Derbeth::I18n 0.6.4;

our @ISA = qw/Exporter/;
our @EXPORT = qw/detect_pronounced_word
	latin_chars_disallowed
	word_pronounced_in_file/;
our $VERSION = 0.3.0;
use vars qw($verbose);

$verbose=0;

Derbeth::Web::enable_caching(1);

my %regional_fr = ('fr-Paris' => 'Paris', 'FR Paris' => 'Paris', 'fr FR-Paris' => 'Paris',
	'ca-Montréal' => 'ca', 'fr Be' => 'be', 'fr BE' => 'be', 'fr CA' => 'ca');
# normal language code => regexp for matching alternative code
my %code_alias=('tr'=>'tur','la'=>'lat', 'de'=>'by|bar', 'el' => 'ell', 'fr' => 'qc', 'nb' => 'no',
	'roa' => 'jer');

# marks words with lower priority
my $LOWPR = '&';

sub latin_chars_disallowed {
	my ($lang) = @_;
	return $lang =~ /^(ar|be|el|fa|he|hi|ja|ka|ko|mk|or|ru|th|uk)$/;
}

# For a pronunciation file for a non-Latin-script language, tries to guess
# the real word from the file description page.
#
# Paramters:
#   $lang - language code like 'th' or 'ko'
#   $file - name of the file like 'th-farang.ogg'
#
# Returns:
#   array of detected real words or empty array if the real word cannot be detected
sub detect_pronounced_word {
	my ($lang,$file,$editor) = @_;
	return () unless (_detect_language_supported($lang));

	my $wikicode = Derbeth::Wikitools::get_wikicode_perlwikipedia($editor, "File:$file");
	unless ($wikicode && $wikicode =~ /\w/) {
		print encode_utf8("cannot detect word: no description for File:$file\n");
		return ();
	}

	return _detect($lang, $wikicode);
}

sub _detect_language_supported {
	my ($lang) = @_;
	return ($lang =~ /^(bg|he|ja|or|th|zh)$/);
}

sub _detect {
	my ($lang, $wikicode) = @_;
	my @detected;

	if ($lang eq 'mk') {
		if ($wikicode =~ /Macedonian pronunciation of ''([^' a-z()"]+)''/) {
			push @detected, $1;
		}
	}
	elsif ($lang eq 'bg') {
		if ($wikicode =~ /Pronunciation of the word ([^ (a-z()"]+) \(/) {
			push @detected, $1;
		}
	}
	elsif ($lang eq 'he') {
		if ($wikicode =~ /Pronunciation of the Hebrew word "([^a-z"]+)"/) {
			push @detected, $1;
		}
	}
	elsif ($lang eq 'ko') {
		if ($wikicode =~ /Pronunciation of [^(]+\(([^ a-z()"]+)\)/) {
			push @detected, $1;
		}
	}
	elsif ($lang eq 'ja') {
		if ($wikicode =~ /Pronunciation of the Japanese(?: word)? {{lang\|ja\|「([^」a-z]+)」}}/) {
			push @detected, $1;
		}
		if ($wikicode =~ /Pronunciation of the Japanese word[^(]+\({{lang\|ja\|([^,()a-z]+),/) {
			push @detected, $1;
		}
	}
	elsif ($lang eq 'or') {
		if ($wikicode =~ /or[^"]+"([^"]+)"ର ଉଚ୍ଚାରଣ/) {
			push @detected, $1;
		}
	}
	elsif ($lang eq 'th') {
		if ($wikicode =~ /Pronunciation of word " *([^ a-z()"]+) *\(/) {
			push @detected, $1;
		}
	}
	elsif ($lang eq 'zh') {
		if ($wikicode =~ /Pronunciation of "[^"]+" \(([^a-z()]+)\) in Chinese/) {
			push @detected, $1;
		}
	}

	return @detected;
}

# Returns word pronounced in given file.
#
# Parameters:
#   $page - like 'File:en-uk-ear.ogg'
#   $code - like 'en', 'hsb'
#   $cat  - category the page belongs to, like 'Latvian pronunciation'
#
# Returns:
#   empty array - when no word can be identified
#   ($file, $word1, $word2) - name of the file (like 'en-uk-ear.ogg') and
#                             at least one guess of the word (like
#                             'ear<uk>' or 'ear' when regional cannot be identified)
#                             'ear&' or 'ear<uk>&' means that the word should have
#                             lower priority than the same word without '&'
#                             (for example because it contains the article)
sub word_pronounced_in_file {
	my ($page, $code, $cat) = @_;
	$cat = '' unless(defined($cat));

	return () if ($page !~ /(?:File|Image):(.+)\.(ogg|OGG|oga|OGA)/);
	my $file = $1.'.'.$2;
	my $main_text = $1;

	if ($main_text =~ / \(etymology | \((adj|noun|verb)\)$/) {
		print "skipping alternative variant ", encode_utf8($page), "\n" if $verbose;
		return ();
	}
	if ($main_text =~ /-synth-/) {
		print "skipping synthesized ", encode_utf8($page), "\n" if $verbose;
		return;
	}
	if ($main_text =~ /Voice of America/) {
		return ();
	}

	my $skip_key_extraction=0;
	my $word;
	my $regional='';
	my $art_rem = 0; # true if article has been removed
	my $priority = '';
	my $force_low_pr = 0;

	if ($code ne 'nv') {
		$main_text =~ s/\x{301}// and $priority = $LOWPR; # remove accent
	}
	$main_text =~ s/ \(alternative pronunciation\)$// and $priority = $LOWPR;

	# === Non-standard naming goes here
	if ($cat =~ /^Latvian pronunciation/) {
		if ($main_text =~ /^Latvian pronunciation (.*)$/) {
			return ($file, $1);
		}
	}
	elsif ($code eq 'ar' || $code eq 'or') {
		if ($main_text !~ /-/) {
			$skip_key_extraction = 1;
			$word = $main_text;
		}
	}
	elsif ($code eq 'cy' && $main_text !~ /cy-/i) {
		return ($file, $main_text, lcfirst($main_text));
	}
	elsif ($cat =~ /^Bavarian /) {
		$regional = 'by';
	}
	elsif ($code eq 'de') {
		if ($main_text =~ /^CPIDL German - /) {
			return ($file, lcfirst($POSTMATCH));
		}
		$main_text =~ s/ fcm$//;
	}
	elsif ($code eq 'en') {
		if ($main_text =~ /^Ca-en-/i) {
			return ($file, $POSTMATCH);
		}
	}
	elsif ($code eq 'es') {
		if ($main_text =~ /^Es-/i) {
			# ok
		} elsif ($main_text =~ /^Spanish /) {
			return ($file, $POSTMATCH);
		} else {
			return ();
		}
	}
	elsif ($code eq 'eu') {
		return ($file, $main_text, lcfirst($main_text));
	}
	elsif ($code eq 'fr') {
		if ($main_text =~ /^([^-]+)-FR$/) {
			return ($file, lcfirst($1));
		}
		if ($main_text =~ /Qc-/i) {
			$regional = 'ca';
		}
	}
	elsif ($code eq 'is') {
		if ($main_text !~ /^Is-/i) {
			return ($file, $main_text, lcfirst($main_text));
		}
	}
	elsif ($code eq 'it') {
		$main_text =~ s/ \.\.\.//;
		if ($main_text =~ /^Italian /) {
			return ($file, $POSTMATCH);
		}
	}
	elsif ($code eq 'sq') {
		if ($main_text =~ /^Albanian /) {
			return ($file, $POSTMATCH);
		}
	}
	elsif ($code eq 'tr') {
		$main_text =~ s/^Tr tr /Tur-/;
		if ($main_text !~ /^(tur|tr)-/i) {
			return ($file, lcfirst($main_text));
		}
	}
	elsif ($code eq 'vi') {
		if ($main_text =~ /^Vi-hanoi-m-/) {
			return ($file, $POSTMATCH);
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
		if ($main_text !~ /^$lang_code(- | |-)/i) { # case-insensitive
			print 'not a pronunciation file: ',encode_utf8($page),"\n" if $verbose;
			return ();
		}
		$word = $POSTMATCH;
	}

	# === Regional parts stripping goes here
	if ($code eq 'bg') {
		if ($word =~ /^bg-/i) {
			$word = $POSTMATCH; # remove
		}
	}
	elsif ($code eq 'da') {
		if ($word =~ /^cph-/i) {
			$word = $POSTMATCH; # remove
		}
	}
	elsif ($code eq 'de') {
		$word =~ s/-pronunciation$//;
		if ($word =~ /^(at)-/) {
			$regional = $1;
			$word = $POSTMATCH;
		}
	}
	elsif ($code eq 'en') {
		if ($word =~ /^(us-ncalif|us-inlandnorth|us|uk|ca|nz|gb|au|sa)-/i) {
			$regional = lc($1);
			$word = $POSTMATCH;
		}
	}
	elsif ($code eq 'es') {
		if ($word =~ /-bo-La Paz$/) {
			$regional = 'bo';
			$word = $PREMATCH;
		} elsif ($word =~ /-Ar-Rosario$/) {
			$regional = 'ar';
			$word = $PREMATCH;
		} elsif ($word =~ /^(chile|mx|us|am-lat)-/) {
			$regional = lc($1);
			$word = $POSTMATCH;
		}
	}
	elsif ($code eq 'fa') {
		if ($word =~ /^f-/i) {
			$word = $POSTMATCH; # remove
		}
	}
	elsif ($code eq 'fr') {
		$word =~ s/^fr-//i;
		if ($word =~ s/^-?Paris-{1,3}(.)/$1/i) {
			$regional = 'Paris';
		} elsif ($word =~ s/^(Belgique-BW|BE-BW|BE)-+//) {
			$regional = 'be';
		} elsif ($word =~ s/ \(Avignon\)$//) {
			$force_low_pr = 1; # ignore this regional
		}

		$art_rem = 1 if $word =~ s/^(une|un|les|le|la)[ -]//gi;
		$art_rem = 1 if $word =~ s/^l'//gi;

		if ($word =~ /-(fr-ouest|fr-Paris|FR Paris|fr FR-Paris|fr-CA-Quebec-(Lac-Saint-Jean)|ca-Montréal|fr BE|fr CA|fr)$/i) {
			if (exists($regional_fr{$1})) {
				$regional = $regional_fr{$1};
			}
			$word = $PREMATCH;
		}
		if ($cat eq 'Quebec French pronunciation') {
			$regional ||= 'ca';
		}
	}
	elsif ($code eq 'gd') {
		if ($word =~ /^(Lewis)-/) {
			$regional = $1;
			$word = $POSTMATCH;
		}
	}
	elsif ($code eq 'he') {
		if ($word =~ /^il-/i) {
			# all Hebrew is spoken in Israel; it's not regional, so ignore
			$word = $POSTMATCH;
		}
	}
	elsif ($code eq 'hy') {
		if ($word =~ /^(ea|EA|E)-/) {
			$regional = 'east-armenian';
			$word = $POSTMATCH;
		}
	}
	elsif ($code eq 'la') {
		if ($word =~ /^(ecc|cls|rom)-/) {
			$regional = $1;
			$word = $POSTMATCH;
		}
	}
	elsif ($code eq 'li') {
		if ($word =~ /^vb-/i) {
			$word = $POSTMATCH; # remove regional
		}
	}
	elsif ($code eq 'lv') {
		if ($word =~ /^riga-/i) {
			$word = $POSTMATCH; # remove regional
		}
	}
	elsif ($code eq 'nl') {
		if ($word =~ / \(Belgium\)$/) {
			$regional = 'be';
			$word = $PREMATCH;
		} elsif ($word =~ / \(Netherlands\)$/) {
			$word = $PREMATCH;
		}
	}
	elsif ($code eq 'nb') {
		if ($word =~ /^nor-/i) {
			$word = $POSTMATCH; # remove regional, because this means Standard East Norwegian, so Bokmal
		}
	}
	elsif ($code eq 'pam') {
		if ($word =~ /^ph-/i) {
			$word = $POSTMATCH; # remove regional
		}
	}
	elsif ($code eq 'pt') {
		if ($word =~ /^(br|pt)[- ]/) {
			$regional = $1 if ($1 ne 'pt');
			$word = $POSTMATCH;
		}
	}
	if ($code eq 'roh') {
		if ($word =~ /^(sursilvan( \(Breil\))?)-/i) {
			$regional = 'sursilvan';
			$word = $POSTMATCH;
		} elsif ($word =~ /^(putèr|vallader)-/i) {
			$regional = $1;
			$word = $POSTMATCH;
		}
	}
	elsif ($code eq 'sv') {
		$word =~ s/^en //g;
	}
	elsif ($code eq 'tl') {
		if ($word =~ /^ph-/i) {
			# all Tagalog is spoken in Phillipines; it's not regional, so ignore
			$word = $POSTMATCH;
		}
	}
	elsif ($code eq 'wym') {
		$word =~ s/ \(wersja Józefa Gary\)$//;
	}
	# == end regional, now stripping articles

	if ($code eq 'it' && $word !~ /^(un po')$/) {
		$art_rem = 1 if $word =~ s/^(un|l)'//;
		$art_rem = 1 if $word =~ s/^(un|una|uno|il|la|lo|i|le|gli) // ;
	}
	elsif ($code eq 'fr') {
		$art_rem = 1 if $word =~ s/ \((:?un|une|l[’']|la|le|du|des|les)\)$//;
	}
	elsif ($code eq 'sv') {
		$art_rem = 1 if $word =~ s/^(?:ett) //;
	}

	# == saving
	
	if ($art_rem || $force_low_pr || $page =~ /\.oga$/i) {
		$priority = $LOWPR;
	}

	my @result = ($file, _with_regional($word, $regional, $priority));

	# === Letter size problems go here
	if ($cat eq 'English pronunciation of numbers'
	||  $cat eq 'Jèrriais pronunciation'
	||  $code eq 'sr'
	) {
		push @result, _with_regional(lcfirst($word), $regional);
	}
	if ($code eq 'en') {
		if ($word =~ /^(a|an|the|to) (.+)$/) {
			push @result, _with_regional($2, $regional, $LOWPR);
		}
	}
	# === Handling 'second pronunciation variant'
	if ($code =~ /^(ce|is|ta|zh)$/) {
		# don't even try
	} elsif ($word =~ / \(\d\)$|[- ]+[1-6]$/) {
		@result = ($file, _with_regional($`, $regional, $LOWPR));
	} elsif ($word =~ /([^0-9A-Z])[123]$/) {
		push @result, _with_regional($`.$1, $regional, $LOWPR);
	}

	return @result;
}

# returns either $word<$regional> or $word if regional is empty
# priority is added at the end
sub _with_regional {
	my ($word, $regional, $priority) = @_;
	$priority = '' unless(defined($priority));
	return $regional ? "$word<$regional>$priority" : "$word$priority";
}

1;
