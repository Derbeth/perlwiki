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

our @ISA = qw/Exporter/;
our @EXPORT = qw/get_regional_name
	get_language_name/;
our $VERSION = 0.4.0;

# pl: uk => wymowa brytyjska
# en: uk => (British pronunciation)
my %regional_names = (
	'pl' => {
		'at' => 'austriacka',
		'br' => 'brazylijska',
		'by' => 'bawarska',
		'uk' => 'brytyjska',
		'us' => 'amerykańska',
		'us-inlandnorth' => 'amerykańska Inland North',
		'nz' => 'nowozelandzka',
		'au' => 'australijska',
		'ca' => 'kanadyjska',
		'bo' => 'boliwijska',
		'Paris' => 'paryska',
		'be' => 'belgijska',
		'cls' => 'tradycyjna', # łacina
		'ecc' => 'kościelna'
	},
	'de' => {
		'at' => 'österreichisch',
		'br' => 'brasilianisch',
		'by' => 'bairisch',
		'uk' => 'britisch',
		'us' => 'US-amerikanisch',
		'us-inlandnorth' => 'amerikanisch Inland North',
		'nz' => 'neuseeländisch',
		'au' => 'australisch',
		'ca' => 'kanadisch',
		'bo' => 'bolivianisch',
		'Paris' => 'pariserisch',
		'be' => 'belgisch',
		'cls' => 'klassisches Latein',
		'ecc' => 'Kirchenlatein'
	},
	'en' => {
		'at' => 'Austria',
		'br' => 'BR',
		'by' => 'Bavarian',
		'uk' => 'UK',
		'us' => 'US',
		'us-inlandnorth' => 'US Inland North',
		'nz' => 'NZ',
		'au' => 'AUS',
		'ca' => 'CAN',
		'bo' => 'BOL',
		'Paris' => 'Paris',
		'be' => 'Belgium',
		'cls' => 'classical',
		'ecc' => 'ecclesiastical'
	}
);


# for titles of language sections
my %language_names = (
	'pl' => {
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
		'fa'  => 'język perski',
		'fi'  => 'język fiński',
		'fr'  => 'język francuski',
		'ga'  => 'język irlandzki',
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
		'la'  => 'język łaciński',
		'lv'  => 'język łotewski',
		'mk'  => 'język macedoński',
		'nb'  => 'język norweski (bokmål)',
		'nl'  => 'język holenderski',
		'pl'  => 'język polski',
		'pol' => 'język staropolski',
		'pt'  => 'język portugalski',
		'ro'  => 'język rumuński',
		'roa' => 'Jèrriais',
		'ru'  => 'język rosyjski',
		'sk'  => 'język słowacki',
		'sq'  => 'język albański',
		'sr'  => 'język serbski',
		'sv'  => 'język szwedzki',
		'tr'  => 'język turecki',
		'uk'  => 'język ukraiński',
		'vi'  => 'język wietnamski',
		'wo'  => 'język wolof',
		'yi'  => 'jidysz',
		'zh'  => 'język chiński' #  (uproszczony) ?
	},
	'de' => {
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
		'fa'  => 'Persisch',
		'fi'  => 'Finnisch',
		'fr'  => 'Französisch',
		'ga'  => 'Irisch',
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
		'la'  => 'Lateinisch',
		'lv'  => 'Lettisch',
		'mk'  => 'Mazedonisch',
		'nb'  => 'Norwegisch',
		'nl'  => 'Niederländisch',
		'pl'  => 'Polnisch',
		'pol' => 'Altpolnisch',
		'pt'  => 'Portugiesisch',
		'ro'  => 'Rumänisch',
		'roa' => 'Jèrriais',
		'ru'  => 'Russisch',
		'sk'  => 'Slowakisch',
		'sq'  => 'Albanisch',
		'sr'  => 'Serbisch',
		'sv'  => 'Schwedisch',
		'tr'  => 'Türkisch',
		'uk'  => 'Ukrainisch',
		'vi'  => 'Vietnamesisch',
		'wo'  => 'Wolof',
		'yi'  => 'Jiddisch',		
		'zh'  => 'Chinesisch'
	},
	'en' => {
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
		'fa'  => 'Persian',
		'fi'  => 'Finnish',
		'fr'  => 'French',
		'ga'  => 'Irish',
		'he'  => 'Hebrew',
		'hi'  => 'Hindi',
		'hr'  => 'Croatian',
		'hu'  => 'Hungarian',
		'hy'  => 'Armenian',
		'ia'  => 'Interlingua',
		'id'  => 'Indonesian',
		'is'  => 'Icelandic',
		'it'  => 'Italian',
		'ka'  => 'Georgian',
		'la'  => 'Latin',
		'lv'  => 'Latvian',
		'mk'  => 'Macedonian',
		'nb'  => 'Norwegian',
		'nl'  => 'Dutch',
		'pl'  => 'Polish',
		'pol' => 'Old Polish',
		'pt'  => 'Portuguese',
		'ro'  => 'Romanian',
		'roa' => 'Jèrriais',
		'ru'  => 'Russian',
		'sk'  => 'Slovak',
		'sq'  => 'Albanian',
		'sr'  => 'Serbian',
		'sv'  => 'Swedish',
		'tr'  => 'Turkish',
		'uk'  => 'Ukrainian',
		'vi'  => 'Vietnamese',
		'wo'  => 'Wolof',
		'yi'  => 'Yiddish',
		'zh'  => 'Mandarin'
	}
);

sub get_regional_name {
	my ($lang, $code) = @_;
	if (!exists($regional_names{$lang}{$code})) {
		return $code;
	}
	return $regional_names{$lang}{$code};
}

sub get_language_name {
	my ($lang, $code) = @_;
	if (!exists($language_names{$lang}{$code})) {
		return $code;
	}
	return $language_names{$lang}{$code};
}

1;