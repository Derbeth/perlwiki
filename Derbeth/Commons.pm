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
my %editor_cache;

Derbeth::Web::enable_caching(1);

my %regional_fr = ('fr-Paris' => 'Paris', 'FR Paris' => 'Paris', 'fr FR-Paris' => 'Paris',
	'ca-Montréal' => 'ca', 'fr Be' => 'be', 'fr BE' => 'be', 'fr CA' => 'ca');
# normal language code => regexp for matching alternative code
my %code_alias=('de'=>'by|bar', 'el' => 'ell', 'eu' => 'eus', 'fr' => 'qc', 'hy' => 'hyw-hy|hyw',
	'la'=>'lat', 'nb' => 'no', 'roa' => 'jer', 'roh' => 'rm', 'tr'=>'tur', 'yue' => 'zh-yue');

my %lingua_libre_accepted = (
	'af'  => ['Anon1314', 'Iwan.Aucamp', 'Oesjaar'],
	'ary' => ['Anass Sedrati', 'Fenakhay'],
	'az'  => ['Azerbaijani audiorecordings'],
	'be'  => ['Ssvb'],
	'bn'  => ['Galpadattya', 'Titodutta'],
	'ca'  => ['Millars=val', 'Toniher', 'Unjoanqualsevol'],
	'de'  => ['Jeuwre'],
	'en'  => ['AryamanA=us', 'Commander Keane=au', 'Justinrleung=ca', 'Vealhurl=uk', 'Vininn126=us', 'Wodencafe=us'],
	'eo'  => ['Lepticed7'],
	'es'  => ['AdrianAbdulBaha=co', 'Ivanhercaz', 'MiguelAlanCS=pe', 'Millars', 'Rodelar'],
	'eu'  => ['Aioramu', 'Theklan', 'Xabier Cañas'],
	'fa'  => ['Afsham23'],
	'fi'  => ['Anniina (WikiLucas00)', 'Susannaanas'],
	'fr'  => ['Benoît Prieur', 'Darkdadaah', 'DenisdeShawi=ca', 'DSwissK=ch', 'GrandCelinien', 'Helenou66', 'Lepticed7', 'LoquaxFR', 'Lyokoï', 'Mecanautes', 'Opsylac', 'Pamputt', 'Penegal', 'Poslovitch', 'T. Le Berre', 'Touam', 'X-Javier', 'WikiLucas00'],
	'hi'  => ['AryamanA'],
	'hy'  => [
		'Vahagn Petrosyan=east-armenian',
		'Yevgenya Shamshyan (Vahagn Petrosyan)=east-armenian',
	],
	'id'  => ['Dvnfit', 'Xbypass'],
	'it'  => ['Happypheasant', 'LangPao', 'Yiyi'],
	'ja'  => ['Higa4'],
	'ko'  => ['HappyMidnight'],
	'mr'  => ['Neelima64', 'SangeetaRH', 'नंदिनी रानडे'],
	'mt'  => ['GħawdxiVeru'],
	'oc'  => ['Davidgrosclaude'],
	'ro'  => ['KlaudiuMihaila'],
	# Trabkin - native, but microphone issues
	'pl'  => ['Anwar2', 'Czupirek', 'Gower', 'KaMan', 'Jest Spoczko', 'Liskowskyy', 'Olaf', 'Poemat', 'Sobsz', 'Tashi', 'ThineCupOverfloweth'],
	'ru'  => ['Cinemantique', 'Lvova', 'Svetlov Artem', 'Tatiana Kerbush'],
	'sl'  => ['Zupanurska'],
	'sv'  => ['Salgo60'],
	# Bicolino34 - native, but audio quality bad
	'uk'  => ['Tohaomg'],
	'yue' => ['Justinrleung'],
	'zh'  => ['Aa087159', 'Assassas77', 'Jun Da (Yug)', 'KhawaChenpo', 'Liang (MichaelSchoenitzer)', 'Vickylin77amis', 'Wang Cheng (Yug)', '雲角']
);

# marks words with lower priority
my $LOWPR = '&';

my %simplified_to_traditional;
read_hash_loose('audio/simplified.txt', \%simplified_to_traditional) if (-e 'audio/simplified.txt');

sub latin_chars_disallowed {
	my ($lang) = @_;
	return $lang =~ /^(ar|ary|be|el|fa|he|hi|hy|ja|ka|ko|mar|mk|ne|or|ru|te|th|uk|yue|zh)$/;
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

	if (_detect_by_content_supported($lang)) {
		my $wikicode = Derbeth::Wikitools::get_wikicode_perlwikipedia($editor, "File:$file");
		unless ($wikicode && $wikicode =~ /\w/) {
			print encode_utf8("cannot detect word: no description for File:$file\n");
			return ();
		}
		return _detect_by_content($lang, $wikicode, \%simplified_to_traditional);
	}
	if (_detect_by_usages_supported($lang)) {
		return _detect_by_usages($lang,$file);
	}
	return ();
}

sub _detect_by_content_supported {
	my ($lang) = @_;
	return ($lang =~ /^(bg|he|ja|ka|or|th|zh)$/);
}

sub _detect_by_usages_supported {
	my ($lang) = @_;
	return ($lang =~ /^(te)$/);
}

sub _detect_by_content {
	my ($lang, $wikicode, $simplified_to_traditional_ref) = @_;
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
	elsif ($lang eq 'ka') {
		if ($wikicode =~ /წარმოთქმა „([^“]+)“. მამაკაცის/) {
			push @detected, $1;
		}
	}
	elsif ($lang eq 'ko') {
		if ($wikicode =~ /Pronunciation of [^(]+\(([^ a-z()"]+)\)/) {
			push @detected, $1;
		}
	}
	elsif ($lang eq 'ja') {
		if ($wikicode =~ /Pronunciation of the Japanese(?: word)? \{\{lang\|ja\|「([^」a-z]+)」}}/) {
			push @detected, $1;
		}
		if ($wikicode =~ /Pronunciation of the Japanese word[^(]+\(\{\{lang\|ja\|([^,()a-z]+),/) {
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
		} elsif ($wikicode =~ /Pronunciation of "?\w+"? \(([^\)\/ ]+) ?(?:or|and|\/) ?([^\) ]+); +([^\)]+)\)/) {
			push @detected, $1, $2, $3;
		}  elsif ($wikicode =~ /Pronunciation of "?\w+"? \(([^\)\/ ]+); +([^\) ]+)\)/) {
			push @detected, $1, $2;
		} elsif ($wikicode =~ /Pronunciation of "?(\w+)"? \(([^\)\/ ]+) ?(?:or|and|\/) ?([^\) ]+)\)/) {
			push @detected, $1, $2, $3;
		}
		my @originally_detected = @detected;
		foreach my $sign (@originally_detected) {
			if (exists $simplified_to_traditional_ref->{$sign}) {
				push @detected, $simplified_to_traditional_ref->{$sign};
			}
		}
	}

	return @detected;
}

sub _detect_by_usages {
	my ($lang,$file) = @_;
	my $local_editor = $editor_cache{$lang} || Derbeth::Wikitools::create_editor("http://$lang.wiktionary.org/w/");
	my $query = {action=>'query',iutitle=>"File:$file",list=>'imageusage',fuprop=>'title',
		fushow=>'!redirect',fulimit=>2};
	my $result_ref = $local_editor->{api}->list($query, {max=>1});
	unless ($result_ref) {
		print encode_utf8("cannot detect word in $file: ").$local_editor->{api}->{error}->{code}
			. ': ' . $local_editor->{api}->{error}->{details}."\n";
		return ();
	}
	my @usages = @{$result_ref};
	if ($#usages == -1) {
		return ();
	}
	if ($#usages > 0) {
		print encode_utf8("more than 1 usage of $file\n");
		return ();
	}
	return ($usages[0]->{title});
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

	if ($page !~ /(?:File|Image):(.+)\.(flac|ogg|oga|opus|wav)/i) {
		print "skipping because of extension ", encode_utf8($page), "\n" if $verbose;
		return ();
	}
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
	# from Lingua Libre
	if ($main_text =~ /^LL-[^-]+-[^-]+-(.+)$/) {
		$main_text = $1;
		$main_text =~ s/^ +//;
		# only allow languages from whitelist as Lingua Libre quality is very bad
		my $regional = _lingua_libre_accepted($code, $file);
		if (!(defined $regional)) {
			print "skipping: not on LL whitelist ", encode_utf8($page), "\n" if $verbose;
			return ();
		}
		if ($code eq 'oc') {
			if ($page =~ /Q35735/) { $regional = 'gas'; }
			elsif ($page =~ /Q942602/) { $regional = 'lan'; }
		}
		if ($code eq 'de') {
			$main_text =~ s/ \([^)]+\)$//;
		}
		return ($file, _with_regional($main_text, $regional, $LOWPR));
	}
	if ($main_text =~ /^LL/) {
		print STDERR encode_utf8("skipping wrong Lingua Libre '$page'\n");
		return ();
	}

	if ($cat =~ /^Latvian pronunciation/) {
		if ($main_text =~ /^Latvian pronunciation (.*)$/) {
			return ($file, $1);
		}
	}
	elsif ($code eq 'ar') {
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
		if ($main_text !~ /^Eus-/) {
			return ($file, $main_text, lcfirst($main_text));
		}
	}
	elsif ($code eq 'fr') {
		if ($main_text =~ /^([^-]+)-FR$/) {
			return ($file, lcfirst($1));
		}
		if ($main_text =~ /Qc-/i) {
			$regional = 'ca';
		}
	}
	elsif ($code eq 'hy') {
		if ($main_text =~ /^HyW-/i) {
			$regional = 'west-armenian';
		} elsif ($main_text =~ / WA$/) {
			$regional = 'west-armenian';
			$main_text = $`;
		} elsif ($main_text =~ /^Hy-/) {
			$regional = 'east-armenian';
		} elsif ($main_text !~ /-/) {
			$skip_key_extraction = 1;
			$word = $main_text;
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
	elsif ($code eq 'nb') {
		if ($main_text =~ /^NB - Pronunciation of Norwegian Bokmål «([^»]+)»/) {
			return ($file, "$1&");
		}
	}
	elsif ($code eq 'ne') {
		if ($main_text !~ /-/) {
			$skip_key_extraction = 1;
			$word = $main_text;
		}
	}
	elsif ($code eq 'or') {
		if ($main_text =~ /^Pronunciation of Odia word "([^"]+)"/) {
			return ($file, $1);
		}
		if ($main_text !~ /-/) {
			$skip_key_extraction = 1;
			$word = $main_text;
		}
	}
	elsif ($code eq 'sq') {
		if ($main_text =~ /^Albanian /) {
			return ($file, $POSTMATCH);
		}
	}
	elsif ($code eq 'ta') {
		if ($main_text =~ /^([^-]+)- Pronunciation in Tamil$/) {
			return ($file, $1);
		}
	}
	elsif ($code eq 'te') {
		if ($main_text =~ / ?- ?te$/i) {
			$skip_key_extraction = 1;
			$word = $`;
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
	if ($code eq 'az') {
		if ($word =~ /^az-/i) {
			$word = $POSTMATCH; # remove
		}
	}
	elsif ($code eq 'bg') {
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
		if ($word =~ /^(?:sursilv|sursilvan( \(Breil\))?)-/i) {
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
	elsif ($code eq 'sw') {
		if ($word =~ /^(ke)-/) {
			$regional = $1;
			$word = $POSTMATCH;
		}
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
	elsif ($code eq 'zh') {
		if ($word =~ /^cmn-/) {
			$word = $POSTMATCH;
		}
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
	
	if ($art_rem || $force_low_pr || $page =~ /\.(oga|wav)$/i) {
		$priority = $LOWPR;
	}

	my @result = ($file, _with_regional($word, $regional, $priority));

	# === Letter size problems go here
	if (($cat eq 'English pronunciation of numbers'
	||  $cat eq 'Jèrriais pronunciation'
	||  $code eq 'sr'
	) && lcfirst($word) ne $word) {
		push @result, _with_regional(lcfirst($word), $regional);
	}
	if ($code eq 'en') {
		if ($word =~ /^(a|an|the|to) (.+)$/) {
			push @result, _with_regional($2, $regional, $LOWPR);
		}
	} elsif ($code eq 'hy') {
		my %identical = ('և' => 'եւ', 'եւ' => 'և');
		while (my ($from, $to) = each %identical) {
			my $changed = $word;
			if ($changed =~ s/$from/$to/g) {
				push @result, _with_regional($changed, $regional, $LOWPR);
			}
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

sub _lingua_libre_accepted {
	my ($lang, $file) = @_;
	if (exists $lingua_libre_accepted{$lang}) {
		foreach my $user_entry (@{$lingua_libre_accepted{$lang}}) {
			my ($username, $regional);
			if ($user_entry =~ /(.+)=(.+)/) {
				($username, $regional) = ($1, $2);
			} else {
				($username, $regional) = ($user_entry, '');
			}
			if (index($file, "-$username-") != -1) {
				return $regional;
			}
		}
	}
	return undef;
}

1;
