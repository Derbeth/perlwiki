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

package Derbeth::Inflection;
require Exporter;

use strict;
use utf8;

use Encode;

our @ISA = qw/Exporter/;
our @EXPORT = qw/
	extract_de_inflection_dewikt
	extract_en_inflection_dewikt/;
our $VERSION = 0.2.0;

my $NOINFLECTION='1234';

# TODO retain order
sub _uniq_values {
	my %results;
	foreach my $val (@_) {
		$results{$val} = 1;
	}
	return keys %results;
}

# returns singular form plus a list of plural forms
# singular can be empty string if word has no singular
sub extract_de_inflection_dewikt {
	my ($section_ref) = @_;
	my @singular_forms = $$section_ref =~ /Nominativ Singular[^=]*=(.*)/g;
	my @plural_forms = $$section_ref =~ /Nominativ Plural[^=]*=(.*)/g;
	map { s/^ +| +$//g } @singular_forms;
	map { s/^ +| +$//g } @plural_forms;
	map { s/^(der|die|das) // } @singular_forms;
	map { s/^(der|die|das) // } @plural_forms;
	print "sing", @singular_forms, "\n";
	@singular_forms = _uniq_values(@singular_forms);
	@plural_forms = _uniq_values(@plural_forms);
	my $singular = @singular_forms ? $singular_forms[0] : '';
	($singular, @plural_forms);
}

# Returns:
#   plural form or empty string if not found
#   note that "-" means "no plural"
sub _extract_en_inflection {
	my ($word,$section_ref) = @_;
	my $section_copy = $$section_ref;
	
	$section_copy =~ s/<\/?center>//g;
	$section_copy =~ s/—|\{\{fehlend\}\}/-/g;
	
	if ($section_copy =~ /\{\{Englisch Substantiv Übersicht/) {
		if ($section_copy =~ /\|Plural=\s*([^}\n\r\f]+)/) {
			my $plural = $1;
			$plural =~ s/^the //;
			return $plural;
		}
		return '';
	}
	
	$section_copy =~ s/\|(BBreite|(Bild|BBezug|BBeschreibung)\d)=[^\|\}]*//g;
	#print encode_utf8($section_copy);
	
	if ($section_copy =~ /\{\{Englisch Substantiv\s*\}\}|\{\{Englisch Substantiv\|s\s*\}\}/) {
		return "${word}s";
	} elsif ($section_copy =~ /\{\{Englisch Substantiv\|([^|}\n\r\f]+)\s*\}\}/) {
		my $pl = $1;
		$pl =~ s/^ +| +$//g;
		if ($pl eq '-') {
			return '-';
		} else {
			return "${word}$1";
		}
	} else {
		return '';
	}
}

sub _extract_ipa {
	my ($section_ref) = @_;
	my ($ipa_sing, $ipa_pl)=('','');
	
	if ($$section_ref =~ /:\[\[Hilfe:IPA\|IPA]]:\s+{{Lautschrift\|([^}]+)}}/) {
		$ipa_sing = $1;
	}
	if($$section_ref =~ /:\[\[Hilfe:IPA\|IPA]]:.*{{Pl.}}\s+{{Lautschrift\|([^}]+)}}/) {
		$ipa_pl = $1;
	}
	
	if ($ipa_sing =~ /\.\.\./ || $ipa_sing =~ /fehlend/) {
		$ipa_sing = '';
	}
	if ($ipa_pl =~ /\.\.\./ || $ipa_pl =~ /fehlend/) {
		$ipa_pl = '';
	}
	
	return ($ipa_sing,$ipa_pl);
}

# Function: extract_en_inflection_dewikt
# Parameters:
#   $word - article title
#   $section_ref - reference to section text
#
# Returns:
#   $inflection - row for Polish Wiktionary:
#     {{lm}} cats
#   $singular - singular form ('Bus')
#   $plural - plural form ('Busse')
#   $ipa_sing - singular IPA
#   $ipa_pl - plural IPA
sub extract_en_inflection_dewikt {
	my ($word,$section_ref)=@_;
	
	my ($ipa_sing,$ipa_pl) = _extract_ipa($section_ref);
	my $plural = _extract_en_inflection($word,$section_ref);
	
	my $inflection = '';
	if ($plural =~ /\(|\?/) {
			$plural = '';
		}
	if ($plural) {
		$inflection = "{{lp}} $word; ";
		if ($plural eq '-') {
			$inflection .= "{{blm}}";
			$plural = '';
		} else {
			$inflection .= "{{lm}} $plural";
		}
	}
	return ($inflection,$word,$plural,$ipa_sing,$ipa_pl);
}

1;