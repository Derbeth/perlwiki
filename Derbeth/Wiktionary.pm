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

package Derbeth::Wiktionary;
require Exporter;

use utf8;
use strict;
use English;

use Derbeth::I18n 0.8.0;
use Derbeth::Wikitools;
use Encode;
use URI::Escape;
use Carp;

our @ISA = qw/Exporter/;
our @EXPORT = qw/add_audio
	add_audio_plwikt
	add_audio_dewikt
	decode_pron
	initial_cosmetics
	final_cosmetics
	add_inflection_plwikt
	should_not_be_in_category_plwikt/;
our $VERSION = 0.12.0;

# Function: create_audio_entries_enwikt
# Parameters:
#   %files - hash (file=>region) eg. 'en-us-solder.ogg' => 'us',
#            'en-solder.ogg' => ''
#
# Returns:
#   $audios - '* {{audio|en-us-solder.ogg|audio (US)}}\n* {{audio...}}'
#   $edit_summary - list of added files
#                   en-us-solder.ogg, en-solder.ogg, en-au-solder.ogg
sub create_audio_entries_enwikt {
	my ($lang_code,$pron,$section_ref,$singular,$plural) = @_;

	my @audios;
	my @summary;
	my @decoded_pron = decode_pron($pron, $section_ref, $singular);
	while (@decoded_pron) {
		my $file = shift @decoded_pron;
		my $region = shift @decoded_pron;

		my $regional_name = '';
		my $text = '* {{audio|'.$file.'|';
		$text .= $plural ? $plural : 'Audio';
		my $edit_summary = $file;
		if ($region ne '') {
			$regional_name = get_regional_name('en',$region);
			$text .= " ($regional_name)";
		}
		$text .= "|lang=$lang_code";
		$text .= '}}';

		push @audios, $text;
		push @summary, $edit_summary;
	}
	return (join("\n", @audios), scalar(@audios), join(', ', @summary));
}

sub create_audio_entries_simplewikt {
	my ($text, $count, $summary) = create_audio_entries_enwikt(@_);
	$text =~ s/\|lang=[^}]+//g;
	return ($text, $count, $summary);
}

# Function: create_audio_entries_frwikt
# Parameters:
#   $pron - 'en-us-solder.ogg<us>|en-solder.ogg|en-au-solder.ogg<au>'
#
# Returns:
#   $audios - '* {{pron-reg|en-us-solder.ogg|audio (US)}}\n* {{pron-reg...}}'
#   $edit_summary - list of added files
#                   en-us-solder.ogg, en-solder.ogg, en-au-solder.ogg
sub create_audio_entries_frwikt {
	my ($lang_code,$pron,$section_ref,$singular,$plural) = @_;

	my @audios;
	my @summary;

	my @all_audios;
	while ($$section_ref =~ /audio= *([^.}|]+\.(?:\w{3,4}))/igc) {
		push @all_audios, $1;
	}

	my @decoded_pron = decode_pron($pron, $section_ref, $singular);
	while (@decoded_pron) {
		my $file = shift @decoded_pron;
		my $region = shift @decoded_pron;

		if ($region && $region ne 'Paris') {
			next if (grep(/\b$region\b/i, @all_audios));
		} else {
			next if (grep(!/\b(be|ca)\b/i, @all_audios));
		}

		my $edit_summary = $file;
		my $text = ' {{pron-rég|';
		$text .= get_regional_frwikt($lang_code,$region,$file);
		$text .= '|'; # no IPA
		if ($file =~ /fr-((l'|(un|une|le|la|des|les) )[^-.(]+)\.(?:\w{3,4})/i) {
			$text .= "|titre=$1";
			$edit_summary .= " as '$1'";
		} elsif ($file =~ /Fr-Paris--([^-.(]+) \((un|une|le|la|des|les|du)\)\.(?:\w{3,4})/i) {
			my $new_word = "$2 $1";
			$text .= "|titre=$new_word";
			$edit_summary .= " as '$new_word'";
		} elsif ($file =~ /Fr-Paris--([^-.(]+) \((l’)\)\.(?:\w{3,4})/i) {
			my $new_word = "l'$1";
			$text .= "|titre=$new_word";
			$edit_summary .= " as '$new_word'";
		}
		$text .= "|audio=$file";
		$text .= '}}';

		push @audios, $text;
		push @summary, $edit_summary;
		push @all_audios, $file;
	}
	return (join("\n*", @audios), scalar(@audios), join(', ', @summary));
}


sub create_audio_entries_dewikt {
	my ($lang_code,$pron,$section_ref,$singular,$plural) = @_;

	my @audios;
	my @summary;
	my @decoded_pron = decode_pron($pron, $section_ref, $singular);
	while (@decoded_pron) {
		my $file = shift @decoded_pron;
		my $region = shift @decoded_pron;

		my $text = '{{Audio|'.$file.'|';
		my $edit_summary = $file;
		my $visual_label='';

		if ($plural) {
			$visual_label = $plural;
		} elsif ($region ne '') {
			$visual_label = $singular;
		}

		if ($region ne '') {
			if (exists $Derbeth::I18n::regional_params_dewikt{$region}) {
				if ($plural) {
					$visual_label .= '|';
				} else {
					$visual_label = '';
				}
				$visual_label .= 'spr=' . $Derbeth::I18n::regional_params_dewikt{$region};
			} else {
				$visual_label .= ' ('.get_regional_name('de',$region).')';
			}
		}

		$text .= $visual_label.'}}';
		$text =~ s/\| /|/g;
		$text =~ s/\|}}/}}/g;

		push @audios, $text;
		push @summary, $edit_summary;
	}
	return (join(' ', @audios), scalar(@audios), join(', ', @summary));
}

sub create_audio_entries_plwikt {
	my ($lang_code,$pron,$section_ref,$singular,$plural) = @_;

	my @audios;
	my @summary;
	my @decoded_pron = decode_pron($pron, $section_ref, $singular);
	while (@decoded_pron) {
		my $file = shift @decoded_pron;
		my $region = shift @decoded_pron;

		my $text = '{{audio|'.$file;
		my $edit_summary = $file;
		if ($region ne '') {
			$text .= '|wymowa '.get_regional_name('pl',$region);
		}
		$text .= '}}';

		push @audios, $text;
		push @summary, $edit_summary;
	}
	return (join(' ', @audios), scalar(@audios), join(', ', @summary));
}

# Funcion: create_audio_entries
# Parameters:
#   $pron - 'en-us-solder.ogg<us>|en-solder.ogg|en-au-solder.ogg<au>'
#   $section - reference to section where pronuciation should be
#              added (read-only)
#   $singular - singular form of the word
#   $plural - plural form of the word (optional)
#
# Returns:
#   $audios - '{{audio|en-us-solder.ogg|audio (US)}}, {{audio...}}'
#   $audios_count - 3
#   $edit_summary - list of added files
#                   en-us-solder.ogg, en-solder.ogg, en-au-solder.ogg
sub create_audio_entries {
	my ($wikt_lang,$lang_code,$pron,$section,$singular,$plural) = @_;

	my @args = ($lang_code,$pron,$section,$singular,$plural);
	my @retval;
	if ($wikt_lang eq 'de') {
		@retval = create_audio_entries_dewikt(@args);
	} elsif ($wikt_lang eq 'en') {
		@retval = create_audio_entries_enwikt(@args);
	} elsif ($wikt_lang eq 'pl') {
		@retval = create_audio_entries_plwikt(@args);
	} elsif ($wikt_lang eq 'fr') {
		@retval = create_audio_entries_frwikt(@args);
	} elsif ($wikt_lang eq 'simple') {
		@retval = create_audio_entries_simplewikt(@args);
	} else {
		croak "Wiktionary $wikt_lang not supported";
	}

	return @retval;
}

# Function: decode_pron
#   returns pronunciation files without regional part, sorting and removing audios already present in the article
# Parameters:
#   $pron - 'en-us-solder.ogg<us>|en-solder.ogg|en-au-solder.ogg<au>'
#   $section - a ref to a scalar holding article section text
#   $page_name - name of the edited page
#
# Returns:
#   array ('en-us-solder.ogg', 'uk', 'solder', '', 'en-au-solder.ogg', 'au')
sub decode_pron {
	my ($pron, $section, $page_name) = @_;

	my @prons = split /\|/, $pron;
	@prons = sort { (($a =~ /<([^>]+)>/)[0] || '') cmp (($b=~ /<([^>]+)>/)[0] || '') } @prons;

	my $section_unescaped;
	if ($section) {
		$section_unescaped = $$section;
		$section_unescaped =~ s/\{\{PAGENAME\}\}/$page_name/;
	}

	my @result;
	foreach my $a_pron (@prons) {
		$a_pron =~ /(.*\.(?:\w{3,4}))(<(.*)>)?/i;
		my $file=$1;
		my $region = $3 ? $3 : '';

		if ($section_unescaped) {
			my $file_escaped = $file;
			$file_escaped =~ s/([()[\]\^\$*+.])/\\$1/g;
			my $file_no_spaces = $file_escaped;
			$file_no_spaces =~ s/ /_/g;
			#print stderr "$file_escaped|$file_no_spaces\n";
			next if ($section_unescaped =~ /$file_escaped/i || $section_unescaped =~ /$file_no_spaces/i);
		}
		push @result, $file, $region;
	}

	return @result;
}

# Function: add_audio_enwikt
# Returns:
#   $result - 0 when ok, 1 when section already has all audio,
#             2 when cannot add audio
#   $added_audios - how many audio files have been added
#   $edit_summary - edit summary text
sub add_audio_enwikt {
	my ($section,$pron,$lang_code,$check_only,$singular,$pron_pl,$plural) = @_;
	my $language = get_language_name('en',$lang_code);
	($pron_pl,$plural) = ('',''); # turned off

	my ($audios,$audios_count,$edit_summary)
		= create_audio_entries('en',$lang_code,$pron,$section,$singular);
	my ($audios_pl,$audios_count_pl,$edit_summary_pl)
		= create_audio_entries('en',$lang_code,$pron_pl,$section,$singular,$plural);

	if ($audios eq '' && $audios_pl eq '') {
		return (1,'','');
	}
	if ($check_only) {
		return (0,'','');
	}

	$audios_count += $audios_count_pl;

	$edit_summary = 'added audio '.$edit_summary;
	$edit_summary .= ' plural ' . $edit_summary_pl if ($edit_summary_pl ne '');

	if ($audios_pl ne '') {
		if ($audios eq '') {
			$audios = $audios_pl;
		} else {
			$audios .= ', '.$audios_pl;
		}
	}

	#my ($before_etym,$etym,$after_etym);
	#if ($$section =~ /===\s*Etymology([^=]*)={3,}/) {
	#	($before_etym,$etym,$after_etym) = ($PREMATCH,$MATCH,$POSTMATCH);
	#}

	# TODO

	my $audio_marker = ">>HEREAUDIO<<";

	if ($$section =~ /\{\{:/) {
		$edit_summary .= '; handling page transclusion not supported';
		return (2,0,$edit_summary);
	} elsif ($$section =~ /= *Etymology +1 *=/
	|| ($$section =~ /= *Etymology/i && $POSTMATCH =~ /= *Etymology/i)) {
		$edit_summary .= '; handling multiple etymologies not supported';
		return (2,0,$edit_summary);
	} elsif ($$section =~ /= *Pronunciation/i && $POSTMATCH =~ /= *Pronunciation/i) {
		$edit_summary .= '; handling multiple pronunciation sections not supported';
		return (2,0,$edit_summary);
	} elsif ($$section !~ /=== *Pronunciation *===/) {
		$edit_summary .= '; added missing pron. section';

		if ($$section =~ /===\s*Etymology\s*={3,}(.|\n|\r|\f)*?==/) {
			unless ($$section =~ s/(=== *Etymology *={3,}(.|\n|\r|\f)*?)(==)/$1===Pronunciation===\n$audio_marker\n\n$3/) {
				$edit_summary .= '; cannot add pron. after etymology';
				return (2,0,$edit_summary)
			}
		} elsif ($$section =~ /===\s*Alternative forms\s*={3,}(.|\n|\r|\f)*?==/) {
			unless ($$section =~ s/(=== *Alternative forms *={3,}(.|\n|\r|\f)*?)(==)/$1===Pronunciation===\n$audio_marker\n\n$3/) {
				$edit_summary .= '; cannot add pron. after alternative forms';
				return (2,0,$edit_summary)
			}
		} else { # no etymology at all
			if ($$section =~ s/(==\s*$language\s*==(.|\n|\r|\f)*?)(==)/$1===Pronunciation===\n$audio_marker\n\n$3/) {
				# ok, add before first heading after language
			} elsif ($$section =~ s/(==\s*$language\s*==)/$1\n\n===Pronunciation===\n$audio_marker/) {
				# ok, no heading, so just add after language
			} else {
				$edit_summary .= '; cannot add pron. after section begin';
				return (2,0,$edit_summary);
			}
		}
	} else {
		unless ($$section =~ s/(===\s*Pronunciation\s*={3,})/$1\n$audio_marker/) {
			$edit_summary .= '; cannot add audio after pron. section';
			return (2,0,$edit_summary);
		}
	}

	$$section =~ s/\r\n/\n/g;
	while ($$section =~ /($audio_marker\n)(\*[^\n]+\n)/) {
		my $next_line = $2;
		if ($next_line =~ /homophones|rhymes|hyphenation/i) {
			last;
		} else {
			$$section =~ s/($audio_marker\n)(\*[^\n]+\n)/$2$1/;
		}
	}
	unless ($$section =~ s/$audio_marker/$audios/) {
		$edit_summary .= '; lost audios marker';
		return (2,0,$edit_summary);
	}

	if ($$section =~ /$audio_marker/) {
		$edit_summary .= '; cannot remove audios marker';
		return (2,0,$edit_summary);
	}

	if ($$section =~ /\{\{rfap/) {
		if($$section =~ s/\{\{rfap(\|lang=$lang_code)?}}\r?\n//) {
			$edit_summary .= '; removed {{rfap}}';
		} else {
			$edit_summary .= '; cannot remove {{rfap}}';
		}
	}

	$$section =~ s/(\n|\r|\f)\{\{IPA/$1*{{IPA/;

	#my $cat = '[[Category:Mandarin entries with audio links]]';
	#if ($$section =~ s/(\[\[Category:)/$cat\n$1/){
	#	$edit_summary .= "; + $cat"; # ok
	#} else {
	#	unless ($$section =~ s/(\[\[\w{2}:|----|$)/\n\n$cat\n$1/) {
	#		$edit_summary .= '; cannot add category';
	#	} else {
	#		$$section =~ s/(\n|\r|\f){3,}(\[\[Category)/$1$1$2/g;
	#		$edit_summary .= "; + $cat";
	#	}
	#}

	return (0,$audios_count,$edit_summary);
}

sub add_audio_simplewikt {
	my ($section,$pron,$lang_code,$check_only,$singular,$pron_pl,$plural) = @_;
	my $language = get_language_name('simple',$lang_code);
	($pron_pl,$plural) = ('',''); # turned off

	my ($audios,$audios_count,$edit_summary)
		= create_audio_entries('simple',$lang_code,$pron,$section,$singular);

	if ($audios eq '') {
		return (1,0,'');
	}
	if ($check_only) {
		return (0,0,'');
	}

	if ($$section =~ /^; *(verb|adjective|noun)/m) {
		return (2,0,'cannot add audio: different parts of speech');
	}

	$edit_summary = 'added audio '.$edit_summary;
	my $MARK = '>>HERE<<';

	if ($$section !~ /=== *Pronunciation *===/) {
		$edit_summary .= '; added missing pron. section';

		if ($$section =~ /=== *Etymology *===/) {
			$$section =~ s/(=== *Etymology *===)/===Pronunciation===\n\n$1/;
		} else {
			$$section =~ s/^(== *[a-zA-Z])/===Pronunciation===\n\n$1/m;
		}
	}

	if ($$section !~ /=== *Pronunciation *===/) {
		$edit_summary .= '; cannot add pronunciation section';
		return (2,0,$edit_summary);
	}

	$$section =~ s/(=== *Pronunciation *===)/$1\n$MARK/;

	$$section =~ s/\r\n/\n/g;
	while ($$section =~ /($MARK\n)(\*[^\n]+\n)/) {
		$$section =~ s/($MARK\n)(\*[^\n]+\n)/$2$1/;
	}

	unless ($$section =~ s/$MARK/$audios/) {
		$edit_summary .= '; lost audios marker';
		return (2,0,$edit_summary);
	}
	if ($$section =~ /$MARK/) {
		$edit_summary .= '; cannot remove audios marker';
		return (2,0,$edit_summary);
	}

	return (0,$audios_count,$edit_summary);
}

sub add_audio_frwikt {
	my ($section,$pron,$lang_code,$check_only,$singular,$pron_pl,$plural) = @_;

	my ($audios,$audios_count,$edit_summary)
		= create_audio_entries('fr',$lang_code,$pron,$section,$singular);

	if ($audios eq '') {
		return (1,0,'');
	}
	if ($check_only) {
		return (0,0,'');
	}

	$edit_summary = 'added audio '.$edit_summary;
	my $MARK = '>>HERE<<';

	if ($$section !~ /\{\{-pron-\}\}/) {
		$edit_summary .= '; added missing pron. section';

		my $sec='{{-pron-}}';
		my $ad=0;
		$ad = ($$section =~ s/(\{\{-homo-)/$sec\n\n$1/) unless($ad);
		$ad = ($$section =~ s/(\{\{-paro-)/$sec\n\n$1/) unless($ad);
		$ad = ($$section =~ s/(\{\{-anagr-)/$sec\n\n$1/) unless($ad);
		$ad = ($$section =~ s/(\{\{-réf-)/$sec\n\n$1/) unless($ad);
		$ad = ($$section =~ s/(\{\{-voir-)/$sec\n\n$1/) unless($ad);
		$ad = ($$section =~ s/(\[\[Catégorie:)/$sec\n\n$1/) unless($ad);
	}

	unless ($$section =~ s/(\{\{-pron-\}\})/$1\n*$MARK/) {
		$edit_summary .= '; cannot add pronunciation section';
		return (2,0,$edit_summary);
	}

	$$section =~ s/\r\n/\n/g;
	while ($$section =~ /(\* *$MARK\n)(\*[^\n]+\n)/) {
		$$section =~ s/(\* *$MARK\n)(\*[^\n]+\n)/$2$1/;
	}

	unless ($$section =~ s/$MARK/$audios/) {
		$edit_summary .= '; lost audios marker';
		return (2,0,$edit_summary);
	}
	if ($$section =~ /$MARK/) {
		$edit_summary .= '; cannot remove audios marker';
		return (2,0,$edit_summary);
	}

	return (0,$audios_count,$edit_summary);
}

# Function: add_audio_dewikt
# Returns:
#   $result - 0 when ok, 1 when section already has all audio,
#             2 when cannot add audio
#             3 when more than one speech part
#   $added_audios - how many audio files have been added
#   $edit_summary - edit summary text
sub add_audio_dewikt {
	my ($section,$pron,$lang_code,$check_only,$singular,$pron_pl,$plural) = @_;
	my $language = get_language_name('de',$lang_code);

	my ($audios,$audios_count,$edit_summary)
		= create_audio_entries('de',$lang_code,$pron,$section,$singular);

	if ($audios eq '') {
		return (1,0,'');
	}
	if ($check_only) {
		return (0,0,'');
	}

	$edit_summary = '+ Audio '.$edit_summary;

	if ($$section =~ /\{\{kSg\.\}\}/) {
		return (2,0,$edit_summary.'; found {{kSg.}}, won\'t add audio automatically');
	}

	my @speech_parts = ($$section =~ /= *\{\{(Wortart.*)/gi);
	if (scalar(@speech_parts) > 1) {
		return (3,0,$edit_summary.'; more than one speech part ('.@speech_parts.')');
	}

	$$section =~ s/:\[\[Hilfe:IPA\|IPA\]\]:/:{{IPA}}/g;
	$$section =~ s/:\[\[Hilfe:Hörbeispiele\|Hörbeispiele\]\]:/:{{Hörbeispiele}}/g;

	my $newipa = ':{{IPA}} {{Lautschrift|…}}';
	my $newaudio = ':{{Hörbeispiele}} {{Audio|}}';

	if ($$section !~ /\{\{Aussprache}}/) {
		$edit_summary .= '; + fehlende {{Aussprache}}';

		if ($$section !~ /\{\{Bedeutung/) {
			if ($$section =~ /\{\{Schweizer und Liechtensteiner Schreibweise/) {
				return (1,0,'');
			}
			unless ($$section =~ s/(==== *Übersetzungen)/{{Bedeutungen}}\n\n$1/) {
				return (2,0,$edit_summary.'; no {{Bedeutungen}} and cannot add it');
			}
			$edit_summary .= '; + {{Bedeutungen}} (leer)';
		}

		unless ($$section =~ s/\{\{Bedeutung(en)?}}/{{Aussprache}}
$newipa
$newaudio

{{Bedeutungen}}/xi) {
			return (2,0,$edit_summary.'; cannot add {{Aussprache}}');
		}
	}
	if ($$section !~ /: *\{\{Hörbeispiele}}/) {
		$$section =~ s/\{\{Aussprache}}/{{Aussprache}}
$newaudio/x;
	}

	if ($audios ne '') {
		if ($$section =~ /\{\{Hörbeispiele}} +(-|–|—|\{\{[fF]ehlend}}|\{\{[aA]udio\|}})/) {
			unless ($$section =~ s/(\{\{Hörbeispiele}}) +(-|–|—|\{\{[fF]ehlend}}|\{\{[aA]udio\|}})/$1 $audios/) {
				return (2,0,$edit_summary.'; cannot replace {{fehlend}}');
			}
		} else { # already some pronunciation
			unless ($$section =~ s/(\{\{Hörbeispiele}}) */$1 $audios /) {
				return (2,0,$edit_summary.'; cannot append pron.');
			}
			$$section =~ s/  / /g;
		}
	}

	# if audio before ipa, put it after ipa
	$$section =~ s/(:\{\{Hörbeispiele}}.*)(\n|\r|\f)(:\{\{IPA}}.*)/$3$2$1/;

	# prevent pronunciation being commented out
	#if ($$section =~ /<!--((.|\n|\r|\f)*?Aussprache(.|\n|\r|\f)*?)-->/$1/) {
	#	$edit_summary .= '; ACHTUNG: die Aussprache ist kommentiert';
	#}

	return (0,$audios_count,$edit_summary);
}

sub _put_audio_plwikt {
	my ($pron_part_ref,$audios) = @_;

	if ($$pron_part_ref =~ /\{\{IPA/) {
		unless ($$pron_part_ref =~ s/(\{\{IPA[^}]+}})/$1 $audios/) {
			return 0;
		}
	} else {
		$$pron_part_ref = $audios . ' ' . $$pron_part_ref;
	}

	return 1;
}

# Input:
#   ...'{{wymowa}} (1.1) {{lp}} {{IPA|a}}; {{lm}} {{IPA2|b}}'...
# Output:
#  (' (1.1) {{lp}} ', '{{IPA|a}};', '{{IPA2|b}}')
sub _split_pron_plwikt {
	my ($section_ref) = @_;

	$$section_ref =~ /\{\{wymowa}}([^\r\n\f]*)/;
	my $pron_line = $1;
	die if $pron_line =~ /\n|\r|\f/;
	my $pron_line_prelude='';

	if ($pron_line =~ /^ *\([^)]+\) */) { # {{wymowa}} (1.1)
		$pron_line_prelude .= $MATCH;
		$pron_line = $POSTMATCH;
	}
	if ($pron_line =~ /^.*\{\{lp}} */) {
		$pron_line_prelude .= $MATCH;
		$pron_line = $POSTMATCH;
	}

	my ($pron_line_sing,$pron_line_pl);
	if ($pron_line =~ /^(.*)\{\{lm}}/) {
		$pron_line =~ /^(.*)\{\{lm}}/;
		$pron_line_sing = $1;
		$pron_line_pl = $POSTMATCH;
	} else {
		($pron_line_sing,$pron_line_pl) = ($pron_line,'');
	}

	#print "pron:[$pron_line_prelude|$pron_line_sing|$pron_line_pl]\n";
	return ($pron_line_prelude,$pron_line_sing,$pron_line_pl);
}

# Function: add_audio_plwikt
# Parameters:
#   $pron_pl - additional parameter; plural pronunciation
#   $ipa_sing - IPA for singular, without brackets
#   $ipa_plural
#
# Returns:
#   $result - 0 when ok, 1 when section already has all audio,
#             2 when cannot add audio
#   $added_audios - how many audio files have been added
#   $edit_summary - edit summary text
sub add_audio_plwikt {
	my ($section_ref,$pron,$lang_code,$check_only,$singular,$pron_pl,$plural,$ipa_sing,$ipa_pl) = @_;
	my $language = get_language_name('pl',$lang_code);
	$pron_pl = '' if (!defined($pron_pl));
	$ipa_sing = '' if (!defined($ipa_sing));
	$ipa_pl = '' if (!defined($ipa_pl));
	my @summary;

	my ($audios,$audios_count,$edit_summary_sing)
		= create_audio_entries('pl',$lang_code,$pron,$section_ref,$singular);
	my ($audios_pl,$audios_count_pl,$edit_summary_pl)
		= create_audio_entries('pl',$lang_code,$pron_pl,$section_ref,$singular);

	if ($$section_ref !~ /\{\{wymowa}}/) {
		push @summary, '+ brakująca sekcja {{wymowa}}';
		unless ($$section_ref =~ s/\{\{znaczenia}}/{{wymowa}}\n{{znaczenia}}/) {
			push @summary, 'nie udało się dodać sekcji "wymowa"';
			return (2,0,join('; ', @summary));
		}
	}

	my ($pron_line_prelude,$pron_line_sing,$pron_line_pl)
		= _split_pron_plwikt($section_ref);

	my $can_add_ipa = ($ipa_sing ne '' && $pron_line_sing !~ /\{\{IPA/)
	|| ($ipa_pl ne '' && $pron_line_pl !~ /\{\{IPA/);

	if ($audios eq '' && $audios_pl eq '' && !$can_add_ipa) {
		return (1,'','');
	}
	if ($check_only) {
		return (0,'','');
	}

	$audios_count += $audios_count_pl;

	if ($edit_summary_sing ne '') {
		push @summary, '+ audio '.$edit_summary_sing;
	}
	if ($edit_summary_pl ne '') {
		push @summary, '+ audio dla lm '.$edit_summary_pl;
	}

	if ($ipa_sing ne '' && $pron_line_sing !~ /\{\{IPA/) {
		$pron_line_sing = "{{IPA3|$ipa_sing}} " . $pron_line_sing;
		push @summary, '+ IPA dla lp z de.wikt';
	}
	if ($ipa_pl ne '' && $pron_line_pl !~ /\{\{IPA/) {
		$pron_line_pl = "{{IPA4|$ipa_pl}} " . $pron_line_pl;
		push @summary, '+ IPA dla lm z de.wikt';
	}

	if ($audios ne '') {
		unless (_put_audio_plwikt(\$pron_line_sing,$audios)) {
			push @summary, 'nie udało się dodać audio dla lp';
			return (2,0,join('; ', @summary));
		}
	}
	if ($audios_pl ne '') {
		unless (_put_audio_plwikt(\$pron_line_pl,$audios_pl)) {
			push @summary, 'nie udało się dodać audio dla lm';
			return (2,0,join('; ', @summary));
		}
	}

	my $pron_line = ' '.$pron_line_prelude.$pron_line_sing;
	if ($pron_line_pl =~ /\w/) {
		$pron_line .= ' {{lm}} ' . $pron_line_pl;
	}
	$pron_line =~ s/ {2,}/ /g;
	$pron_line =~ s/ +$//;

	if ($pron_line =~ /\//) {
		push @summary, 'UWAGA: napotkano IPA bez szablonu';
	}

	$$section_ref =~ s/\{\{wymowa}}(.*)/{{wymowa}}$pron_line/;

	return (0,$audios_count,join('; ', @summary));
}

# Function: add_audio
# Parameters:
#   $section_ref - reference to text of section in processed language
#   $pron - 'en-us-solder.ogg<us>|en-solder.ogg'
#   $lang_code - language code of the section, 'en', 'de', 'hsb'
#   $check_only - if true, only checks whether to add pronunciation
#                 but does not modify anything (optional)
#
# Returns:
#   $result - 0 when ok, 1 when section already has all audio,
#             2 when cannot add audio
#   $added_audios - how many audio files have been added
#   $edit_summary - edit summary text
sub add_audio {
	my ($wikt_lang,$section_ref,$pron,$lang_code,$check_only,$singular,$pron_pl,$plural,$ipa_sing,$ipa_pl) = @_;
	unless ($$section_ref) {
		print encode_utf8("WARN: empty section for $singular\n");
	}

	if ($wikt_lang eq 'en') {
		return add_audio_enwikt($section_ref,$pron,$lang_code,$check_only,$singular,$pron_pl,$plural,$ipa_sing,$ipa_pl);
	} elsif ($wikt_lang eq 'de') {
		return add_audio_dewikt($section_ref,$pron,$lang_code,$check_only,$singular,$pron_pl,$plural,$ipa_sing,$ipa_pl);
	} elsif ($wikt_lang eq 'pl') {
		return add_audio_plwikt($section_ref,$pron,$lang_code,$check_only,$singular,$pron_pl,$plural,$ipa_sing,$ipa_pl);
	} elsif ($wikt_lang eq 'simple') {
		return add_audio_simplewikt($section_ref,$pron,$lang_code,$check_only,$singular,$pron_pl,$plural,$ipa_sing,$ipa_pl);
	} elsif ($wikt_lang eq 'fr') {
		return add_audio_frwikt($section_ref,$pron,$lang_code,$check_only,$singular,$pron_pl,$plural,$ipa_sing,$ipa_pl);
	} else {
		croak "Wiktionary $wikt_lang not supported";
	}
}

sub initial_cosmetics_enwikt {
	return '';
}

sub initial_cosmetics_simplewikt {
	my $page_text_ref = shift @_;
	my @summary;

	if ($$page_text_ref =~ s/^\*(\{\{(?:enPR|IPA|SAMPA|audio|US|UK))/* $1/gim) {
		push @summary, 'cosmetic';
	}

	return join(', ', @summary);
}

sub initial_cosmetics_frwikt {
	return '';
}

sub initial_cosmetics_dewikt {
	my $page_text_ref = shift;
	my @summary;
	my $comment_removed = 0;

	if ($$page_text_ref =~ s/(\{\{Aussprache}}) +(\[\[Hilfe:IPA\|)/$1\n:$2/g) {
		push @summary, '{{Aussprache}} und IPA waren in einer Zeile';
	}

	if ($$page_text_ref =~ s/Wiktionary:Hörbeispiele/Hilfe:Hörbeispiele/g) {
		push @summary, 'Linkkorr.';
	}

	my $repeat=1;
	while($repeat) {
		$repeat=0;
		while ($$page_text_ref =~ /<!--((.|\n|\r|\f)*?)-->/gc) {
			my $comment = $MATCH;
			my $inside = $1;
			if ($inside =~ /Hilfe:Hörbeispiele|\{\{Aussprache}}/) {
				# prepare to serve as regexp
				#$comment =~ s/([^\\])([\[|])/$1\\$2/g;
				$comment =~ s/(\[|\||\(|\))/\\$1/g;
				#print $comment;
				unless ($$page_text_ref =~ s/$comment/$inside/) {
					# fatal error
					push @summary, 'Entfernen des Kommentars um Aussprache fehlgeschlagen';
					last;
				}
				$comment_removed = 1;
				$repeat=1;
				#last;
			}
		}
	}
	$$page_text_ref =~ s/ +\{\{Aussprache}}/{{Aussprache}}/g;
	$$page_text_ref =~ s/ +(:\[\[Hilfe:(IPA|Hörbeispiele))/$1/g;
	if ($comment_removed) {
		push @summary, 'ein Kommentar um Aussprache wurde entfernt';
	}

	if ($$page_text_ref =~ s/(\{\{Audio[^}]+%[^}]+\}\})/Encode::decode('utf8', (uri_unescape($1)))/eg) {
		push @summary, '- "%" in Dateien'
	}

	if ($$page_text_ref =~ s/(\n|\r|\f) *(\[\[Hilfe:(IPA|Hörbeispiele))/$1:$2/g) {
		push @summary, '+ ":"';
	}

	if ($$page_text_ref =~ s/(\n|\r|\f){2,}(:\[\[Hilfe:(IPA|Hörbeispiele))/$1$2/g) {
		push @summary, '- leere Zeile';
	}

	if ($$page_text_ref =~ s/(:\[\[Hilfe:(Hörbeispiele|IPA)[^\r\f\n]*)''Plural:?''/$1\{\{Pl.}}/g) {
		push @summary, "''Plural'' -> {{Pl.}}";
	}
	if ($$page_text_ref =~ s/\{\{Bedeutung}}/{{Bedeutungen}}/gi) {
		push @summary, '{{Bedeutung}} -> {{Bedeutungen}}';
	}

	if ($$page_text_ref =~ /(\[\[Hilfe:IPA\|IPA\]\])([^\r\f\n]*)/) {
		my $before = $`.$1;
		my $after = $';
		my $ipa_line = $2;
		if ($ipa_line =~ s/&nbsp;/ /g) {
			push @summary, 'nbsp wurde entfernt';
		}
		if ($ipa_line =~ s/( )\[([^[\]]*)]/$1\{\{Lautschrift|$2}}/g) {
			push @summary, '{{Lautschrift)} wurde in IPA eingefügt';
		}
		$ipa_line =~ s/ {2,}/ /g;
		$$page_text_ref =$before.$ipa_line.$after;
	}

	return join(', ', @summary);
}

sub initial_cosmetics_plwikt {
	my $page_text_ref = shift;
	my @summary;
	my $comm_removed=0;

	$$page_text_ref =~ s/''l(p|m)''/{{l$1}}/g;

	if ($$page_text_ref =~ s/<!-- *\{\{IPA[^}]+}} *-->//g) {
		push @summary, '- zakomentowane puste IPA';
		$comm_removed = 1;
	}
	if ($$page_text_ref =~ s/<!-- *\[\[Aneks:IPA\|(IPA)?\]\]:.*?-->//g) {
		push @summary, '- zakomentowane puste IPA' if (!$comm_removed);
	}
	if ($$page_text_ref =~ s/\{\{wymowa}} +\[\[Aneks:IPA\|IPA\]\]:\s*(?:\/\s*\/\s*)?(\n|\r|\f)/{{wymowa}}$1/g) {
		push @summary, 'usun. pustego IPA';
	}

	if ($$page_text_ref =~ s/\{\{IPA.?\|}}//g) {
		push @summary, 'usun. pustego IPA';
	}
	if ($$page_text_ref =~ s/(\{\{IPA[^}]+\}\}) +(\{\{lp}})/$2 $1/g) {
		push @summary, 'formatowanie wymowy';
	}
	if ($$page_text_ref =~ s/\[\[(Image|Grafika|File):/[[Plik:/g) {
		push @summary, 'Grafika: -> Plik:';
	}

	return join(', ', @summary);
}

# Function: initial_cosmetics
# Parameters:
#   $wikt_lang - 'de', 'en', 'pl' or 'simple'
#   $page_text_ref - reference to page text
# Returns:
#   edit summary
sub initial_cosmetics {
	my ($wikt_lang, $page_text_ref) = @_;
	my @args = ($page_text_ref);

	# remove all underscores from audio
	my $repeat=1;
	while ($repeat) {
		$repeat=0;
		while ($$page_text_ref =~ /\{\{audio([^}]+)}}/igc) {
			my $inside = $1;
			if ($inside =~ /_/) {
				my $changed = $inside;
				$changed =~ s/_/ /g;
				$inside =~ s/(\[|\||\(|\))/\\$1/g;
				$$page_text_ref =~ s/$inside/$changed/g;
				$repeat = 1;
			}
		}
	}

	if ($wikt_lang eq 'de') {
		return initial_cosmetics_dewikt(@args);
	} elsif ($wikt_lang eq 'en') {
		return initial_cosmetics_enwikt(@args);
	} elsif ($wikt_lang eq 'pl') {
		return initial_cosmetics_plwikt(@args);
	} elsif ($wikt_lang eq 'simple') {
		return initial_cosmetics_simplewikt(@args);
	} elsif ($wikt_lang eq 'fr') {
		return initial_cosmetics_frwikt(@args);
	} else {
		croak "Wiktionary $wikt_lang not supported";
	}
}

sub final_cosmetics_dewikt {
	my ($page_text_ref, $word, $plural) = @_;
	my @summary;

	if ($$page_text_ref =~ s/(:\[\[Hilfe:Hörbeispiele\|Hörbeispiele\]\].*)(\n|\r|\f)(:\[\[Hilfe:IPA\|IPA\]\].*)/$3$2$1/g) {
		push @summary, 'korr. Reihenfolge von IPA und Hörbeispielen';
	}

	my $fixed_old_regional = 0;
	while (my ($old_regional,$regional_param) = each %Derbeth::I18n::text_to_regional_param_dewikt) {
		if ($$page_text_ref =~ s/(\{\{[aA]udio[^}]+)\| *($word|\{\{PAGENAME\}\}) \($old_regional\) *\}\}/$1|spr=$regional_param}}/g) {
			$fixed_old_regional = 1;
		}
		if ($plural) {
			if ($$page_text_ref =~ s/(\{\{[aA]udio[^}]+)\| *$plural \($old_regional\) *\}\}/$1|$plural|spr=$regional_param}}/g) {
				$fixed_old_regional = 1;
			}
		}
	}
	if ($fixed_old_regional) {
		push @summary, 'spr= für {{Audio}}';
	}

	return join(', ', @summary);
}

sub final_cosmetics_enwikt {
	return '';
}

sub final_cosmetics_simplewikt {
	return '';
}

sub final_cosmetics_frwikt {
	return '';
}

sub final_cosmetics_plwikt {
	my ($page_text_ref, $word) = @_;
	my @summary;

	if ($$page_text_ref =~ s/----(\n|\r|\f)//g) {
		push @summary, 'usun. poziomej linii';
	}

	if ($$page_text_ref =~ s/\{\{zobtlum/{{zobtłum/g) {
		push @summary, 'popr. zobtłum';
	}

	if ($$page_text_ref =~ s/ ''(w|f|m|n)''( *$| \(|,|;)/ {{$1}}$2/g) {
		push @summary, 'popr. rodzajników';
	}

	if ($$page_text_ref =~ s/(\n|\r|\f){3,}/$1$1/g) {
		push @summary, 'usun. pustych linii';
	}
	$$page_text_ref =~ s/(\n|\r|\f){2}\{\{wymowa\}\}/$1\{\{wymowa}}/g;
	if ($$page_text_ref =~ s/ {2,}/ /g) { # remove double spaces
		push @summary, 'usun. podw. spacji';
	}

	my ($before,$after) = split_before_sections($$page_text_ref);

	if ($before =~ s/('{2,3})?(z|Z)obacz (też|także|tez):?\s*('{2,3})?\s*\[\[([^\]]+)\]\]\s*\n/{{zobteż|$5}}\n/) {
		push @summary, 'popr. zobteż';
	}
	$before =~ s/(\n|\r|\f)+(\{\{zobteż[^}]+}})(\n|\r|\f)+/$1$2$3/;
	$before =~ s/(\n|\r|\f){2,}$/$1/;

	$$page_text_ref = $before.$after;

	my $fixed_graphics=0;
	while ($$page_text_ref =~ s/(\[\[(?:Grafika|Image|Plik|File):.*)(\n|\r|\f){1,}(==.*)/$3$2$1/g) {
		$fixed_graphics = 1;
	}
	push @summary, 'popr. grafiki przed sekcją' if ($fixed_graphics);

	return join(', ', @summary);
}

# Function: final_cosmetics
# Parameters:
#   $wikt_lang - 'de', 'en', 'pl' or 'simple'
#   $page_text_ref - ref to page text
#   $word - the pronounced word (page name)
# Returns: edit summary (may be empty)
sub final_cosmetics {
	my ($wikt_lang, $page_text_ref, $word, $plural) = @_;
	my @args = ($page_text_ref, $word, $plural);

	if ($wikt_lang eq 'de') {
		return final_cosmetics_dewikt(@args);
	} elsif ($wikt_lang eq 'en') {
		return final_cosmetics_enwikt(@args);
	} elsif ($wikt_lang eq 'pl') {
		return final_cosmetics_plwikt(@args);
	} elsif ($wikt_lang eq 'simple') {
		return final_cosmetics_simplewikt(@args);
	} elsif ($wikt_lang eq 'fr') {
		return final_cosmetics_frwikt(@args);
	} else {
		croak "Wiktionary $wikt_lang not supported";
	}
}

# Function: add_inflection_plwikt
# Parameters:
#   $section_ref - reference to section text
#   $inflection - {{lp}} der Bus, Busses, ~, ~; {{lm}} Busse, Busse, Bussen, Busse
#   $word - 'Bus'
#
# Returns:
#   0 - if not added
#   1 - if added
sub add_inflection_plwikt {
	my ($section_ref, $inflection,$word) = @_;
	unless ($$section_ref =~ /\{\{odmiana[^}]*}}(.*)/) {
		return (0,'brak sekcji odmiana');
	}
	my $infl_line=$1;
	if ($inflection !~ /\w/ || $infl_line =~ /\w/) {
		return (0,'');
	}
	$$section_ref =~ s/(\{\{odmiana[^}]*}})(.*)/$1 $inflection/;

	return (1, "+ odmiana z [[:de:$word|de.wikt]]");
}

# Function: should_not_be_in_category_plwikt
# Parameters:
#   $article - full article title
#
# Returns:
#   true if the article is beyond main namespace
sub should_not_be_in_category_plwikt {
	my ($article) = @_;
	return ($article =~ /^(Dyskusja|Szablon|Kategoria|Wikipedysta|Grafika|Plik|Użytkownik|Aneks|Plwikt)/i);
}

1;
