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
use Carp;

our @ISA = qw/Exporter/;
our @EXPORT = qw/
	extract_plural
	match_pronunciation_files
	find_pronunciation_files/;
our $VERSION = 0.2.0;

my $NOINFLECTION='1234';

sub _uniq_values {
	my %met;
	my @results;
	foreach my $val (@_) {
		unless (exists $met{$val}) {
			push @results, $val;
			$met{$val} = 1;
		}
	}
	return @results;
}

sub _extract_plural_with_cases_dewikt {
	my ($section_ref, $article_regex) = @_;
	my @singular_forms = $$section_ref =~ /Nominativ Singular[^=]*=(.+)/g;
	my @plural_forms = $$section_ref =~ /Nominativ Plural[^=]*=(.+)/g;
	_filter_forms(\@singular_forms, \@plural_forms, $article_regex);
}

sub _extract_simple_plural_dewikt {
	my ($section_ref, $article_regex) = @_;
	my @singular_forms = $$section_ref =~ /\| *Singular[^=]*=(.+)/g;
	my @plural_forms = $$section_ref =~ /\| *Plural[^=]*=(.+)/g;
	_filter_forms(\@singular_forms, \@plural_forms, $article_regex);
}

sub _filter_forms {
	my ($singular_arr, $plural_arr, $article_regex) = @_;

	foreach my $arr_ref ($singular_arr, $plural_arr) {
		map { s/^ +| +$//g } @{$arr_ref};
		if ($article_regex) {
			map { s/^$article_regex// } @{$arr_ref};
		}
		@{$arr_ref} = grep { !/^[—-]$|^$/ } @{$arr_ref};
		@{$arr_ref} = _uniq_values(@{$arr_ref});
	}
	($singular_arr, $plural_arr);
}

# Extracts plural from an entry.
# $lang - language code in which the section is (like 'en' for entry on an English word)
#
# returns list of singular forms and a list of plural forms
# each of the list can be empty if there is no such form
sub extract_plural {
	my ($wikt_lang, $lang, $word, $section_ref) = @_;
	if ($wikt_lang eq 'de') {
		if ($lang eq 'de') {
			return _extract_plural_with_cases_dewikt($section_ref, '(der|die|das) ');
		} elsif ($lang eq 'en') {
			return _extract_simple_plural_dewikt($section_ref, 'the ');
		} elsif ($lang eq 'it') {
			return _extract_simple_plural_dewikt($section_ref, '(la |le |lo |gli |il |i |l\'|l’)');
		}  elsif ($lang eq 'nl') {
			return _extract_simple_plural_dewikt($section_ref, '(het|de) ');
		} elsif ($lang eq 'pl') {
			return _extract_plural_with_cases_dewikt($section_ref);
		}
	}
	return ([], []);
}

sub match_pronunciation_files {
	my ($sing_forms_ref, $pl_forms_ref, $pron_hash_ref) = @_;
	my @pron_sing_arr = _having_pronunciation($sing_forms_ref, $pron_hash_ref);
	my @pron_pl_arr = _having_pronunciation($pl_forms_ref, $pron_hash_ref);

	my ($audio, $audio_pl, $pron_sing, $pron_pl);
	if (@pron_sing_arr) {
		($pron_sing, $audio) = ($pron_sing_arr[0]{form}, $pron_sing_arr[0]{pron});
	} else {
		($pron_sing, $audio) = ($sing_forms_ref->[0], '');
	}
	if (@pron_pl_arr) {
		($pron_pl, $audio_pl) = ($pron_pl_arr[0]{form}, join('|', map { $_->{pron} } @pron_pl_arr));
	} else {
		($pron_pl, $audio_pl) = (undef, '');
	}

	return ($audio, $audio_pl, $pron_sing, $pron_pl);
}

sub _having_pronunciation {
	my ($forms_ref, $pron_hash_ref) = @_;
	my @result;
	foreach my $form (@{$forms_ref}) {
		if (exists $$pron_hash_ref{$form}) {
			push @result, {form => $form, pron => $$pron_hash_ref{$form}};
		}
	}
	return @result;
}

sub find_pronunciation_files {
	my ($wikt_lang, $lang, $word, $section_ref, $pron_hash_ref) = @_;
	my ($sing_forms_ref, $pl_forms_ref) = extract_plural($wikt_lang, $lang, $word, $section_ref);

	if (!@{$sing_forms_ref} && !@{$pl_forms_ref}) {
		$sing_forms_ref = [$word];
	} elsif (@{$sing_forms_ref} && !grep { $_ eq $word } @{$sing_forms_ref}) {
		push @{$sing_forms_ref}, $word;
	}

	return match_pronunciation_files($sing_forms_ref, $pl_forms_ref, $pron_hash_ref);
}

1;
