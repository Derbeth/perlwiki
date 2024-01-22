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
our $VERSION = 0.8.7;
our %regional_names;
our %regional_params_dewikt;
our %text_to_regional_param_dewikt;

# pl: uk => wymowa brytyjska
# en: uk => (British pronunciation)
%regional_names = (
	'pl' => {
		'am-lat' => 'w Ameryce Łacińskiej',
		'ar' => 'argentyńska',
		'at' => 'austriacka',
		'au' => 'australijska',
		'be' => 'belgijska',
		'bo' => 'boliwijska',
		'br' => 'brazylijska',
		'by' => 'bawarska',
		'ca' => 'kanadyjska',
		'chile' => 'chilijska',
		'cls' => 'tradycyjna', # łacina
		'ecc' => 'kościelna',
		'east-armenian' => 'wschodnioormiańska',
		'west-armenian' => 'zachodnioormiańska',
		'Lewis' => '– wyspa Lewis',
		'mx' => 'meksykańska',
		'nz' => 'nowozelandzka',
		'Paris' => 'paryska',
		'ph' => 'filipińska',
		'putèr' => 'Putèr',
		'rom' => 'Rzymska',
		'sa' => 'południowoafrykańska',
		'sursilvan' => 'Sursilvan',
		'uk' => 'brytyjska',
		'us' => 'amerykańska',
		'us-inlandnorth' => 'amerykańska Inland North',
		'us-ncalif' => 'amerykańska z Północnej Kalifornii',
		'vallader' => 'Vallader',
	},
	'de' => {
		'am-lat' => 'lateinamerikanisch',
		'ar' => 'argentinisch',
		'at' => 'österreichisch',
		'au' => 'australisch',
		'be' => 'belgisch',
		'bo' => 'bolivianisch',
		'br' => 'brasilianisch',
		'by' => 'bairisch',
		'ca' => 'kanadisch',
		'ch' => 'schweizerisch',
		'chili' => 'chilenisch',
		'cls' => 'klassisches Latein',
		'co' => 'kolumbianisch',
		'ecc' => 'Kirchenlatein',
		'east-armenian' => 'ostarmenisch',
		'west-armenian' => 'westarmenisch',
		'gas' => 'gaskognisch',
		'lan' => 'languedokisch',
		'Lewis' => 'Lewis Insel',
		'mx' => 'mexikanisch',
		'nz' => 'neuseeländisch',
		'Paris' => 'pariserisch',
		'pe' => 'Peru',
		'ph' => 'philippinisch',
		'putèr' => 'Putèr',
		'rom' => 'römisch',
		'sa' => 'südafrikanisch',
		'sursilvan' => 'Surselvisch',
		'ph' => 'philippinisch',
		'uk' => 'britisch',
		'us' => 'US-amerikanisch',
		'us-inlandnorth' => 'amerikanisch Inland North',
		'us-ncalif' => 'amerikanisch Nordkalifornien',
		'val' => 'valencianisch',
		'vallader' => 'Vallader',
	},
	# [[Module:etymology_languages/data]]
	'en' => {
		'am-lat' => 'Latin America',
		'ar' => 'Argentina',
		'at' => 'Austria',
		'au' => 'AUS',
		'be' => 'Belgium',
		'bo' => 'BOL',
		'br' => 'BR',
		'by' => 'Bavarian',
		'ca' => 'CAN',
		'ch' => 'Switzerland',
		'chile' => 'Chile',
		'cls' => 'classical',
		'co' => 'Colombia',
		'ecc' => 'ecclesiastical',
		'east-armenian' => 'Eastern Armenian',
		'west-armenian' => 'Western Armenian',
		'gas' => 'Gascon',
		'ke'  => 'Kenya',
		'lan' => 'Languedocien',
		'Lewis' => 'Isle of Lewis',
		'mx' => 'Mexico',
		'nz' => 'NZ',
		'Paris' => 'Paris',
		'pe' => 'Peru',
		'ph' => 'PH',
		'putèr' => 'Putèr',
		'rom' => 'Roman',
		'sa' => 'SA',
		'sursilvan' => 'Sursilvan',
		'uk' => 'UK',
		'us' => 'US',
		'us-inlandnorth' => 'US Inland North',
		'us-ncalif' => 'Northern California, US',
		'val' => 'Valencian',
		'vallader' => 'vallader',
	}
);
$regional_names{'simple'} = $regional_names{'en'};

# internal regional code => code used by [[wikt:de:Vorlage:Audio]]
%regional_params_dewikt = (
	'ar' => 'ar',
	'at' => 'at',
	'be' => 'be',
	'bo' => 'bo',
	'br' => 'br',
	'by' => 'by',
	'ca' => 'ca',
	'chile' => 'chile',
	'cls' => 'cls',
	'ecc' => 'ecc',
	'east-armenian' => 'east-armenian',
	'ke'  => 'ke',
	'Lewis' => 'Lewis',
	'mx' => 'mx',
	'Paris' => 'Paris',
	'ph' => 'ph',
	'rom' => 'rom',
	'sa' => 'sa',
	'sursilvan' => 'sursilvan',
	'uk' => 'uk',
	'us' => 'us',
	'us-inlandnorth' => 'us-inlandnorth',
	'us-ncalif' => 'us-ncalif',
);

# regional name => code used by [[wikt:de:Vorlage:Audio]]
while (my ($code,$text) = each(%{$regional_names{'de'}})) {
	my $template_param = $regional_params_dewikt{$code};
	next unless $template_param;
	$text_to_regional_param_dewikt{$text} = $template_param;
}
# manually add old mappings
$text_to_regional_param_dewikt{'amerikanisch'} = 'us';

# for titles of language sections
my %language_names = (
	'pl' => {
		'ar'  => 'język arabski',
		'arn' => 'język mapudungun',
		'ba'  => 'język baszkirski',
		'be'  => 'język białoruski',
		'bg'  => 'język bułgarski',
		'ce'  => 'język czeczeński',
		'cs'  => 'język czeski',
		'cy'  => 'język walijski',
		'da'  => 'język duński',
		'de'  => 'język niemiecki',
		'dsb' => 'język dolnołużycki',
		'ee'  => 'ewe',
		'el'  => 'język nowogrecki',
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
		'gl'   => 'język galicyjski',
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
		'ja'  => 'język japoński',
		'ka'  => 'język gruziński',
		'km'  => 'język khmerski',
		'ko'  => 'język koreański',
		'la'  => 'język łaciński',
		'li'  => 'język limburski',
		'lv'  => 'język łotewski',
		'mg'  => 'język malgaski',
		'mk'  => 'język macedoński',
		'mt'  => 'język maltański',
		'nb'  => 'język norweski (bokmål)',
		'ne'  => 'język nepalski',
		'nl'  => 'język holenderski',
		'nv'  => 'język nawaho',
		'or'  => 'orija',
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
		'ta'  => 'język tamilski',
		'te'  => 'język telugu',
		'th'  => 'język tajski',
		'tl'  => 'język tagalski',
		'tr'  => 'język turecki',
		'twi' => 'język twi',
		'uk'  => 'język ukraiński',
		'uz'  => 'język uzbecki',
		'vi'  => 'język wietnamski',
		'wo'  => 'język wolof',
		'wym' => 'język wilamowski',
		'yi'  => 'jidysz',
		'yue' => 'język kantoński',
		'zh'  => 'język chiński standardowy'
	},
	'de' => {
		'af' => 'Afrikaans',
		'ar'  => 'Arabisch',
		'arn' => 'Mapudungun',
		'ary' => 'Marokkanisch-Arabisch',
		'az'  => 'Aserbaidschanisch',
		'ba'  => 'Baschkirisch',
		'be'  => 'Weißrussisch',
		'bg'  => 'Bulgarisch',
		'bn'  => 'Bengalisch',
		'ca'  => 'Katalanisch',
		'ce'  => 'Tschetschenisch',
		'cs'  => 'Tschechisch',
		'cy'  => 'Walisisch',
		'da'  => 'Dänisch',
		'de'  => 'Deutsch',
		'dsb' => 'Niedersorbisch',
		'ee'  => 'Ewe',
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
		'gl'  => 'Galicisch',
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
		'ja'  => 'Japanisch',
		'ka'  => 'Georgisch',
		'km'  => 'Kambodschanisch',
		'ko'  => 'Koreanisch',
		'ku'  => 'Kurdisch',
		'la'  => 'Lateinisch',
		'li'  => 'Limburgisch',
		'lt'  => 'Litauisch',
		'lv'  => 'Lettisch',
		'mg'  => 'Malagasy',
		'mk'  => 'Mazedonisch',
		'mr'  => 'Marathi',
		'mt'  => 'Maltesisch',
		'nb'  => 'Norwegisch',
		'ne'  => 'Nepali',
		'nl'  => 'Niederländisch',
		'nv'  => 'Navajo',
		'oc'  => 'Okzitanisch',
		'or'  => 'Oriya',
		'pa'  => 'Pandschabi',
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
		'sw'  => 'Suaheli',
		'ta'  => 'Tamil',
		'te'  => 'Telugu',
		'th'  => 'Thai',
		'tl'  => 'Tagalog',
		'tr'  => 'Türkisch',
		'twi' => 'Twi',
		'uk'  => 'Ukrainisch',
		'uz'  => 'Usbekisch',
		'vi'  => 'Vietnamesisch',
		'wo'  => 'Wolof',
		'wym' => 'Wilmesaurisch', # cat does not exist yet
		'yi'  => 'Jiddisch',
		'yue' => 'Kantonesisch',
		'zh'  => 'Chinesisch'
	},
	# [[Module:languages]]
	'en' => {
		'af' => 'Afrikaans',
		'ar'  => 'Arabic',
		'arn' => 'Mapudungun',
		'ary' => 'Moroccan Arabic',
		'az'  => 'Azerbaijani',
		'ba'  => 'Bashkir',
		'be'  => 'Belarusian',
		'bg'  => 'Bulgarian',
		'bn'  => 'Bengali',
		'ca'  => 'Catalan',
		'ce'  => 'Chechen',
		'cs'  => 'Czech',
		'cy'  => 'Welsh',
		'da'  => 'Danish',
		'de'  => 'German',
		'dsb' => 'Lower Sorbian',
		'ee'  => 'Ewe',
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
		'gl'  => 'Galician',
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
		'ja'  => 'Japanese',
		'ka'  => 'Georgian',
		'km'  => 'Khmer',
		'ko'  => 'Korean',
		'ku'  => 'Kurdish',
		'la'  => 'Latin',
		'li'  => 'Limburgish',
		'lt'  => 'Lithuanian',
		'lv'  => 'Latvian',
		'mg'  => 'Malagasy',
		'mk'  => 'Macedonian',
		'mr'  => 'Marathi',
		'mt'  => 'Maltese',
		'nb'  => 'Norwegian Bokmål',
		'ne'  => 'Nepali',
		'nl'  => 'Dutch',
		'nv'  => 'Navajo',
		'oc'  => 'Occitan',
		'or'  => 'Odia',
		'pa'  => 'Punjabi',
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
		'sw'  => 'Swahili',
		'ta'  => 'Tamil',
		'te'  => 'Telugu',
		'tl'  => 'Tagalog',
		'th'  => 'Thai',
		'tr'  => 'Turkish',
		'twi' => 'Twi',
		'uk'  => 'Ukrainian',
		'uz'  => 'Uzbek',
		'vi'  => 'Vietnamese',
		'wo'  => 'Wolof',
		'wym' => 'Vilamovian',
		'yi'  => 'Yiddish',
		'yue' => 'Chinese',
		'zh'  => 'Chinese'
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
