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

use Carp;
use Encode;
use Derbeth::Wikitools;
use Derbeth::Util;
use Derbeth::I18n 0.6.2;

our @ISA = qw/Exporter/;
our @EXPORT = qw/detect_pronounced_word/;
our $VERSION = 0.0.1;

# For a pronunciation file for a non-Latin-script language, tries to guess
# the real word from the file description page.
#
# Paramters:
#   $lang - language code like 'th' or 'ko'
#   $file - name of the file like 'th-farang.ogg'
#
# Returns:
#   detected real word or empty string if the real word cannot be detected
sub detect_pronounced_word {
	my ($lang,$file) = @_;
	return '' unless (_language_supported($lang));

	my $wikicode = get_wikicode('http://commons.wikimedia.org/w/', "File:$file");
	unless ($wikicode && $wikicode =~ /\w/) {
		print encode_utf8("cannot detect word: no description for File:$file\n");
		return '';
	}

	return _detect($lang, $wikicode);
}

sub _language_supported {
	my ($lang) = @_;
	return ($lang =~ /^(bg|he|th|zh)$/);
}

sub _detect {
	my ($lang, $wikicode) = @_;
	my $detected='';

	if ($lang eq 'mk') {
		if ($wikicode =~ /Macedonian pronunciation of ''([^' a-z()"]+)''/) {
			$detected = $1;
		}
	}
	elsif ($lang eq 'bg') {
		if ($wikicode =~ /Pronunciation of the word ([^ (a-z()"]+) \(/) {
			$detected = $1;
		}
	}
	elsif ($lang eq 'he') {
		if ($wikicode =~ /Pronunciation of the Hebrew word "([^a-z"]+)"/) {
			$detected = $1;
		}
	}
	elsif ($lang eq 'ko') {
		if ($wikicode =~ /Pronunciation of [^(]+\(([^ a-z()"]+)\)/) {
			$detected = $1;
		}
	}
	elsif ($lang eq 'th') {
		if ($wikicode =~ /Pronunciation of word " *([^ a-z()"]+) *\(/) {
			$detected = $1;
		}
	}
	elsif ($lang eq 'zh') {
		if ($wikicode =~ /Pronunciation of "[^"]+" \(([^a-z()]+)\) in Chinese/) {
			$detected = $1;
		}
	}

	return $detected;
}

1;
