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
our $VERSION = 0.1.0;

my $NOINFLECTION='1234';

# Parameters:
#   $section_ref - ref to text of German section
#   $singular - whether to extract singular or plural inflection
#
# Remarks:
#  returns empty array when there are two versions of singular
#  or plural
#
# Returns:
#   array (Nominativ, Genitiv, Dativ, Akkusativ)
sub _extract_de_inflection {
	my ($section_ref,$singular) = @_;
	my @retval;
	
	if (($singular && $$section_ref =~ /\(Einzahl 1\)/)
	|| (!$singular && $$section_ref =~ /\(Mehrzahl 1\)/)
	|| ($$section_ref =~ /Substantiv-Tabelle/ && $$section_ref =~ /Deutsch Substantiv/)) {
		# cannot handle this
		return ($NOINFLECTION,'','','');
	}
	
	if ($$section_ref =~ /Deutsch Substantiv f (stark|schwach)/) {
		my $stark = ($1 eq 'stark');
		my $number = $singular ? 'SINGULAR' : 'PLURAL';
		
		if ($$section_ref !~ /$number\s*=\s*(.*)/) {
			return ('','','','');
		}
		@retval=($1,$1,$1,$1);
		if ($stark && !$singular) {
			$retval[2] .= 'n';
		}
		
	} elsif ($$section_ref =~ /Deutsch Substantiv m schwach 1/) {
		my $sing_form = '';
		my $pl_form = '';
		if ($$section_ref =~ /SINGULAR\s*=\s*(.*)/) {
			$sing_form = $1;
		}
		if ($$section_ref =~ /PLURAL\s*=\s*(.*)/) {
			$pl_form = $1;
		}
		
		if (!$sing_form || !$pl_form || $$section_ref =~ /GENITIV-E/) {
			return ('','','','');
		}
		
		@retval = ($pl_form,$pl_form,$pl_form,$pl_form);
		if ($singular) {
			$retval[0] = $sing_form;
		}
	} else {
	
		my $number = $singular ? 'Einzahl' : 'Mehrzahl';
		
		my @cases=('Wer oder was', 'Wessen', 'Wem', 'Wen');
		for (my $i=0; $i<=$#cases; ++$i) {
			#my $pattern = "$cases[$i]\?\s+\($number\)\s*=\s*(.*)";
			#my $pattern = "Wer oder was\? \(Einzahl\)\s*=\s*(.*)";
			if ($$section_ref !~ /${cases[$i]}\? \($number\)\s*=\s*(.*)/) {
			#if ($$section_ref !~ /$pattern/) {
				return ('','','','');
			}
			$retval[$i] = $1;
		}
	}
	
	#print "noooo: '",@retval,"'\n";
	
	for (my $i=0; $i<=$#retval; ++$i) {
		$retval[$i] =~ s/\s+$//;
		$retval[$i] =~ s/^.*( |&nbsp;)//g;
		
		if ($retval[$i] =~ /{{fehlend}}|^(<center>)?-(<\/center>)?$/) {
			$retval[$i] = '';
		}
	}
	
	#print "noooo: '",@retval,"'\n";
	
	return @retval;
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

# changes Wort, Wort(e)s, Wort(e), Wort, Wörter, Wörter, Wörtern, Wörtern
# to Wort, Wortes/Worts, ~/Worte, ~, Wörter, Wörter, Wörtern, Wörtern
sub _expand_inflection {
	my @inflection = @_;
	
	for(my $i=0; $i<=$#inflection; ++$i) {
		if ($inflection[$i] =~ /\(.+\)/) {
			my $copy = $inflection[$i];
			$inflection[$i] =~ s/\(.+\)//g;
			$copy =~ s/[()]//g;
			$inflection[$i] .= '/' . $copy;
		}
	}
	
	my $base=$inflection[0];
	for(my $i=1; $i<=$#inflection; ++$i) {
		$inflection[$i] =~ s/(^|\/)$base($|\/)/$1~$2/g;
	}
	
	return @inflection;
}
		
# Returns:
#    der/die/das
sub _extract_gender {
	my ($section_ref) = @_;
	
	if ($$section_ref !~ /{{Wortart\|Substantiv(\|Deutsch)?}},\s+{{(\w)}}/) {
		return '';
	}
	if ($2 eq 'm') {
		return 'der';
	} elsif ($2 eq 'f') {
		return 'die';
	} elsif ($2 eq 'n') {
		return 'das';
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

# Function: extract_de_inflection_dewikt
# Parameters:
#   $section_ref - reference to section text
#
# Returns:
#   $inflection - row for Polish Wiktionary:
#     {{lp}} der Bus, Busses, ~, ~; {{lm}} Busse, Busse, Bussen, Busse
#   $singular - singular form ('Bus')
#   $plural - plural form ('Busse')
#   $ipa_sing - singular IPA
#   $ipa_pl - plural IPA
sub extract_de_inflection_dewikt {
	my ($section_ref)=@_;
	
	my ($ipa_sing,$ipa_pl) = _extract_ipa($section_ref);
	my @inf_sing = _extract_de_inflection($section_ref,1);
	my @inf_pl = _extract_de_inflection($section_ref,0);
	
	my $singular = $inf_sing[0];
	$singular = '' if ($singular eq $NOINFLECTION);
	my $plural = $inf_pl[0];
	$plural = '' if ($plural eq $NOINFLECTION);
	
	($inf_sing[0],$inf_sing[1],$inf_sing[2],$inf_sing[3],@inf_pl)
		= _expand_inflection(@inf_sing,@inf_pl);
	
	if ($inf_sing[0] eq '' || $inf_sing[0] eq $NOINFLECTION) {
		return ('',$singular,$plural,$ipa_sing,$ipa_pl);
	}
	
	my $gender = _extract_gender($section_ref);
	if ($gender eq '') {
		return ('',$singular,$plural,$ipa_sing,$ipa_pl);
	}
	
	my $retval="{{lp}} $gender ";
	for (my $i=0; $i<=$#inf_sing; ++$i) {
		$retval .= $inf_sing[$i];
		$retval .= ', ' if ($i != $#inf_sing);
	}
	
	if ($inf_pl[0] eq '') {
		return ($retval.'; {{blm}}',$singular,'',$ipa_sing,$ipa_pl);
	}
	if ($inf_pl[0] eq $NOINFLECTION) {
		return ($retval, $singular,'',$ipa_sing,$ipa_pl);
	}
	
	$retval .= '; {{lm}} ';
	for (my $i=0; $i<=$#inf_pl; ++$i) {
		$retval .= $inf_pl[$i];
		$retval .= ', ' if ($i != $#inf_pl);
	}
	
	return ($retval,$singular,$plural,$ipa_sing,$ipa_pl);
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