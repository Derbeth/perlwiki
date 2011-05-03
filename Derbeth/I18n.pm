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

package Derbeth::I18n;
require Exporter;

use utf8;
use strict;

use Carp;

our @ISA = qw/Exporter/;
our @EXPORT = qw/get_regional_name
	get_language_name
	get_regional_frwikt/;
our $VERSION = 0.6.1;

# pl: uk => wymowa brytyjska
# en: uk => (British pronunciation)
my %regional_names = (
	'pl' => {
		'at' => 'austriacka',
		'au' => 'australijska',
		'be' => 'belgijska',
		'bo' => 'boliwijska',
		'br' => 'brazylijska',
		'by' => 'bawarska',
		'ca' => 'kanadyjska',
		'cls' => 'tradycyjna', # łacina
		'ecc' => 'kościelna',
		'east-armenian' => 'ze Wschodniej Armenii',
		'Lewis' => '– wyspa Lewis',
		'mx' => 'meksykańska',
		'nz' => 'nowozelandzka',
		'Paris' => 'paryska',
		'ph' => 'filipińska',
		'sa' => 'południowoafrykańska',
		'sursilvan' => 'Sursilvan',
		'uk' => 'brytyjska',
		'us' => 'amerykańska',
		'us-inlandnorth' => 'amerykańska Inland North',
	},
	'de' => {
		'at' => 'österreichisch',
		'au' => 'australisch',
		'be' => 'belgisch',
		'bo' => 'bolivianisch',
		'br' => 'brasilianisch',
		'by' => 'bairisch',
		'ca' => 'kanadisch',
		'cls' => 'klassisches Latein',
		'ecc' => 'Kirchenlatein',
		'east-armenian' => 'ostarmenisch',
		'Lewis' => 'Lewis Insel',
		'mx' => 'mexikanisch',
		'nz' => 'neuseeländisch',
		'Paris' => 'pariserisch',
		'ph' => 'philippinisch',
		'sa' => 'südafrikanisch',
		'sursilvan' => 'Surselvisch',
		'ph' => 'philippinisch',
		'uk' => 'britisch',
		'us' => 'US-amerikanisch',
		'us-inlandnorth' => 'amerikanisch Inland North',
	},
	'en' => {
		'at' => 'Austria',
		'au' => 'AUS',
		'be' => 'Belgium',
		'bo' => 'BOL',
		'br' => 'BR',
		'by' => 'Bavarian',
		'ca' => 'CAN',
		'cls' => 'classical',
		'east-armenian' => 'East Armenian',
		'ecc' => 'ecclesiastical',
		'Lewis' => 'Isle of Lewis',
		'mx' => 'Mexico',
		'nz' => 'NZ',
		'Paris' => 'Paris',
		'ph' => 'PH',
		'sa' => 'SA',
		'sursilvan' => 'Sursilvan',
		'uk' => 'UK',
		'us' => 'US',
		'us-inlandnorth' => 'US Inland North',
	}
);
$regional_names{'simple'} = $regional_names{'en'};


# for titles of language sections
my %language_names = (
	'pl' => {
		'ar'  => 'język arabski',
		'be'  => 'język białoruski',
		'bg'  => 'język bułgarski',
		'ce'  => 'język czeczeński',
		'cs'  => 'język czeski',
		'cy'  => 'język walijski',
		'da'  => 'język duński',
		'de'  => 'język niemiecki',
		'dsb' => 'język dolnołużycki',
		'el'  => 'język grecki',
		'en'  => 'język angielski',
		'eo'  => 'esperanto',
		'es'  => 'język hiszpański',
		'eu'  => 'język baskijski',
		'fa'  => 'język perski',
		'fi'  => 'język fiński',
		'fr'  => 'język francuski',
		'fy'  => 'język fryzyjski',
		'ga'  => 'język irlandzki',
		'gd'  => 'język szkocki gaelicki',
		'he'  => 'język hebrajski',
		'hi'  => 'hindi',
		'hr'  => 'język chorwacki',
		'hsb' => 'język górnołużycki',
		'hu'  => 'język węgierski',
		'hy'  => 'język ormiański',
		'ia'  => 'interlingua',
		'id'  => 'język indonezyjski',
		'is'  => 'język islandzki',
		'it'  => 'język włoski',
		'ka'  => 'język gruziński',
		'ko'  => 'język koreański',
		'la'  => 'język łaciński',
		'li'  => 'język limburski',
		'lv'  => 'język łotewski',
		'mk'  => 'język macedoński',
		'nb'  => 'język norweski (bokmål)',
		'nl'  => 'język holenderski',
		'pam' => 'język pampango',
		'pl'  => 'język polski',
		'pol' => 'język staropolski',
		'pt'  => 'język portugalski',
		'ro'  => 'język rumuński',
		'roa' => 'Jèrriais',
		'roh' => 'język romansz',
		'ru'  => 'język rosyjski',
		'sk'  => 'język słowacki',
		'sl'  => 'język słoweński',
		'sq'  => 'język albański',
		'sr'  => 'język serbski',
		'sv'  => 'język szwedzki',
		'th'  => 'język tajski',
		'tl'  => 'język tagalski',
		'tr'  => 'język turecki',
		'twi' => 'język twi',
		'uk'  => 'język ukraiński',
		'vi'  => 'język wietnamski',
		'wo'  => 'język wolof',
		'yi'  => 'jidysz',
		'zh'  => 'język chiński' #  (uproszczony) ?
	},
	'de' => {
		'ar'  => 'Arabisch',
		'be'  => 'Weißrussisch',
		'bg'  => 'Bulgarisch',
		'ce'  => 'Tschetschenisch',
		'cs'  => 'Tschechisch',
		'cy'  => 'Walisisch',
		'da'  => 'Dänisch',
		'de'  => 'Deutsch',
		'dsb' => 'Niedersorbisch',
		'el'  => 'Griechisch',
		'en'  => 'Englisch',
		'eo'  => 'Esperanto',
		'es'  => 'Spanisch',
		'eu' => 'Baskisch',
		'fa'  => 'Persisch',
		'fi'  => 'Finnisch',
		'fr'  => 'Französisch',
		'fy'  => 'Friesisch',
		'ga'  => 'Irisch',
		'gd'  => 'Schottisch-Gälisch',
		'he'  => 'Hebräisch',
		'hi'  => 'Hindi',
		'hr'  => 'Kroatisch',
		'hsb' => 'Obersorbisch',
		'hu'  => 'Ungarisch',
		'hy'  => 'Armenisch',
		'ia'  => 'Interlingua',
		'id'  => 'Indonesisch',
		'is'  => 'Isländisch',
		'it'  => 'Italienisch',
		'ka'  => 'Georgisch',
		'ko'  => 'Koreanisch',
		'la'  => 'Lateinisch',
		'li'  => 'Limburgisch',
		'lv'  => 'Lettisch',
		'mk'  => 'Mazedonisch',
		'nb'  => 'Norwegisch',
		'nl'  => 'Niederländisch',
		'pam' => 'Kapampangan',
		'pl'  => 'Polnisch',
		'pol' => 'Altpolnisch',
		'pt'  => 'Portugiesisch',
		'ro'  => 'Rumänisch',
		'roa' => 'Jèrriais',
		'roh' => 'Rätoromanisch',
		'ru'  => 'Russisch',
		'sk'  => 'Slowakisch',
		'sl'  => 'Slowenisch',
		'sq'  => 'Albanisch',
		'sr'  => 'Serbisch',
		'sv'  => 'Schwedisch',
		'th'  => 'Thai',
		'tl'  => 'Tagalog',
		'tr'  => 'Türkisch',
		'twi' => 'Twi',
		'uk'  => 'Ukrainisch',
		'vi'  => 'Vietnamesisch',
		'wo'  => 'Wolof',
		'yi'  => 'Jiddisch',		
		'zh'  => 'Chinesisch'
	},
	'en' => {
		'ar'  => 'Arabic',
		'be'  => 'Belarusian',
		'bg'  => 'Bulgarian',
		'ce'  => 'Chechen',
		'cs'  => 'Czech',
		'cy'  => 'Welsh',
		'da'  => 'Danish',
		'de'  => 'German',
		'dsb' => 'Lower Sorbian',
		'el'  => 'Greek',
		'en'  => 'English',
		'eo'  => 'Esperanto',
		'es'  => 'Spanish',
		'eu'  => 'Basque',
		'fa'  => 'Persian',
		'fi'  => 'Finnish',
		'fr'  => 'French',
		'fy'  => 'West Frisian',
		'ga'  => 'Irish',
		'gd'  => 'Scottish Gaelic',
		'he'  => 'Hebrew',
		'hi'  => 'Hindi',
		'hr'  => 'Croatian',
		'hsb' => 'Upper Sorbian',
		'hu'  => 'Hungarian',
		'hy'  => 'Armenian',
		'ia'  => 'Interlingua',
		'id'  => 'Indonesian',
		'is'  => 'Icelandic',
		'it'  => 'Italian',
		'ka'  => 'Georgian',
		'ko'  => 'Korean',
		'la'  => 'Latin',
		'li'  => 'Limburgish',
		'lv'  => 'Latvian',
		'mk'  => 'Macedonian',
		'nb'  => 'Norwegian',
		'nl'  => 'Dutch',
		'pam' => 'Kapampangan',
		'pl'  => 'Polish',
		'pol' => 'Old Polish',
		'pt'  => 'Portuguese',
		'ro'  => 'Romanian',
		'roa' => 'Jèrriais',
		'roh' => 'Romansh',
		'ru'  => 'Russian',
		'sk'  => 'Slovak',
		'sl'  => 'Slovene',
		'sq'  => 'Albanian',
		'sr'  => 'Serbian',
		'sv'  => 'Swedish',
		'tl'  => 'Tagalog',
		'th'  => 'Thai',
		'tr'  => 'Turkish',
		'twi' => 'Twi',
		'uk'  => 'Ukrainian',
		'vi'  => 'Vietnamese',
		'wo'  => 'Wolof',
		'yi'  => 'Yiddish',
		'zh'  => 'Mandarin'
	}
);
$language_names{'simple'} = $language_names{'en'};

my %countries_fr = (
	'be' => 'Belgique',
	'ca' => 'Canada',
);

# Function: get_regional_name
# Parameters:
#  $lang - wiktionary language ('en')
#  $code - regional code ('us', 'Paris')
sub get_regional_name {
	my ($lang, $code) = @_;
	if (!exists($regional_names{$lang}{$code})) {
		confess "no code '$code' for lang $lang";
# 		return $code;
	}
	return $regional_names{$lang}{$code};
}

# Function: get_language_name
# Parameters:
#  $lang - wiktionary language ('en')
#  $code - language code ('hsb', 'nb')
sub get_language_name {
	my ($lang, $code) = @_;
	if (!exists($language_names{$lang}{$code})) {
		confess "no code '$code' for lang $lang";
# 		return $code;
	}
	return $language_names{$lang}{$code};
}

sub get_regional_frwikt {
	my ($lang_code,$regional,$file) = @_;
	confess "not implemented" unless ($lang_code eq 'fr');
	my $result;
	if ($regional && exists $countries_fr{$regional}) {
		$result = $countries_fr{$regional};
	} else {
		$result = 'France';
		if ($regional) {
			if ($regional ne 'Paris') {
				confess "unknown regional: '$regional'";
			}
			$result .= " ($regional)";
		} elsif ($file =~ /fr-ouest/) {
			$result .= ' (Ouest)';
		}
	}
	return $result;
}

1;

