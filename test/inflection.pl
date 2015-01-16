#!/usr/bin/perl -w

use strict;
use utf8;

use Derbeth::Inflection;
use File::Slurp;
use Test::Assert ':all';

test_extract_plural();
test_match_pronunciation_files();
test_find_pronunciation_files();

sub test_extract_plural {
	my $checked = 0;

	$checked += check_extract('de', 'de', 'ignore-word', 'Alpen.txt', [], ['Alpen']);
	$checked += check_extract('de', 'de', 'ignore-word', 'Inkarnation.txt', ['Inkarnation'], ['Inkarnationen']);
	$checked += check_extract('de', 'de', 'ignore-word', 'Mutter.txt', ['Mutter'], ['Mütter', 'Muttern']);
	$checked += check_extract('de', 'de', 'ignore-word', 'Opossum.txt', ['Opossum'], ['Opossums']);
	$checked += check_extract('de', 'de', 'ignore-word', 'Sein.txt', ['Sein'], []);
	$checked += check_extract('de', 'de', 'machen', 'machen.txt', [], []); # a verb
	$checked += check_extract('de', 'en', 'ignore-word', 'house.txt', ['house'], ['houses']);
	$checked += check_extract('de', 'en', 'ignore-word', 'police.txt', ['police'], []);
	$checked += check_extract('de', 'en', 'ignore-word', 'tea.txt', ['tea'], []);
	$checked += check_extract('de', 'en', 'investigate', 'investigate.txt', [], []);
	$checked += check_extract('de', 'es', 'ignore-word', 'ano.txt', ['año'], ['años']);
	$checked += check_extract('de', 'fr', 'ignore-word', 'abricot.txt', ['abricot'], ['abricots']);
	$checked += check_extract('de', 'fr', 'ignore-word', 'lettre.txt', ['lettre'], ['lettres']);
	$checked += check_extract('de', 'hsb', 'ignore-word', 'pjekar.txt', ['pjekar'], ['pjekarjo']);
	$checked += check_extract('de', 'it', 'ignore-word', 'anatra.txt', ['anatra'], ['anatre']);
	$checked += check_extract('de', 'it', 'ignore-word', 'scarpa.txt', ['scarpa'], ['scarpe']);
	$checked += check_extract('de', 'it', 'ignore-word', 'soldo.txt', ['soldo'], ['soldi']);
	$checked += check_extract('de', 'nl', 'ignore-word', 'hoofd.txt', ['hoofd'], ['hoofden']);
	$checked += check_extract('de', 'pl', 'ignore-word', 'matka.txt', ['matka'], ['matki']);
	$checked += check_extract('de', 'sk', 'ignore-word', 'genius.txt', ['génius'], ['géniovia']);
	$checked += check_extract('de', 'xx', 'ignore-word', 'hoofd.txt', [], []);
	$checked += check_extract('xx', 'xx', 'ignore-word', 'hoofd.txt', [], []);

	print "test_extract_plural: $checked checks succeeded\n";
}

sub test_match_pronunciation_files {
	my $checked = 0;

	# has sing, no audios
	$checked += check_match(['', '', 'house', undef], ['house'], [], {});
	# has sing, audio for sing
	$checked += check_match(['house.ogg', '', 'house', undef], ['house'], [], {'house'=>'house.ogg'});
	# has sing and plural, no audios
	$checked += check_match(['', '', 'house', undef], ['house', 'houses'], [], {});
	# has sing and plural, but audio only for sing
	$checked += check_match(['house.ogg', '', 'house', 'houses'], ['house'], ['houses'], {'house'=>'house.ogg'});
	# has sing and plural, audio for sing and plural
	$checked += check_match(['house.ogg', 'houses.ogg', 'house', 'houses'], ['house'], ['houses'], {'house'=>'house.ogg', 'houses'=>'houses.ogg'});
	# has sing and many plurals, audio for all
	$checked += check_match(['house.ogg', 'houses.ogg|housen.ogg', 'house', 'houses'], ['house'], ['houses', 'housen'],
		{'house'=>'house.ogg', 'houses'=>'houses.ogg', 'housen'=>'housen.ogg'});
	# has sing and many plurals, audio for sing and only for second plural
	$checked += check_match(['house.ogg', 'housen.ogg', 'house', 'housen'], ['house'], ['houses', 'housen'],
		{'house'=>'house.ogg', 'housen'=>'housen.ogg'});
	# has no sing, has audio for plural
	$checked += check_match(['', 'houses.ogg', undef, 'houses'], [], ['houses'], {'houses'=>'houses.ogg'});
	# has no sing, does not have audio for plural
	$checked += check_match(['', '', undef, 'houses'], [], ['houses'], {});

	print "test_match_pronunciation_files: $checked checks succeeded\n";
}

sub test_find_pronunciation_files {
	my $checked = 0;

	$checked += check_find('de', 'de', 'ignore-word', 'Inkarnation.txt', {'Inkarnation'=>'Inkarnation.ogg', 'Inkarnationen'=>'Inkarnationen.ogg'},
		['Inkarnation.ogg', 'Inkarnationen.ogg', 'Inkarnation', 'Inkarnationen']);
	$checked += check_find('de', 'de', 'Sein', 'Sein.txt', {'no-matching'=>'irrelevant.ogg'},
		['', '', 'Sein', undef]);
	$checked += check_find('de', 'de', 'Ablaß', 'Ablass.txt', {'Ablaß'=>'Ablaß.ogg', 'Ablaßens'=>'Ablaßens.ogg'},
		['Ablaß.ogg', '', 'Ablaß', undef]); # text contains wrongly formatted, unreadable forms
	$checked += check_find('de', 'de', 'Arme', 'Arme.txt', {'Arme' => 'Arme.ogg'},
		['Arme.ogg', '', 'Arme', undef]);
	$checked += check_find('de', 'de', 'machen', 'machen.txt', {'machen'=>'De-machen.ogg'},
		['De-machen.ogg', '', 'machen', undef]);
	$checked += check_find('de', 'en', 'investigate', 'investigate.txt', {'investigate' => 'En-investigate.ogg'},
		['En-investigate.ogg', '', 'investigate', undef]);
	$checked += check_find('de', 'en', 'only-plural', 'only-plural.txt', {'only-plural' => 'only-plural.ogg'},
		['', 'only-plural.ogg', undef, 'only-plural']);
	$checked += check_find('de', 'en', 'only-plural', 'only-plural.txt', {'singular' => 'singular.ogg'},
		['', '', undef, 'only-plural']);
	$checked += check_find('xx', 'xx', 'use-this', 'hoofd.txt', {'use-this' => 'use-this.ogg'},
		['use-this.ogg', '', 'use-this', undef]);

	print "test_find_pronunciation_files: $checked checks succeeded\n";
}

sub check_extract {
	my ($wikt_lang, $lang, $word, $file, @expected) = @_;
	my $input = read_file("testdata/inflection/$file", binmode => ':utf8');
	my @actual = extract_plural($wikt_lang, $lang, $word, \$input);
	assert_deep_equals \@expected, \@actual;
	1;
}

sub check_match {
	my ($expected_ref, $sing_ref, $plural_ref, $pron_ref) = @_;
	my @actual = match_pronunciation_files($sing_ref, $plural_ref, $pron_ref);
	assert_deep_equals $expected_ref, \@actual;
	1;
}

sub check_find {
	my ($wikt_lang, $lang, $word, $file, $audios, $expected) = @_;
	my $input = read_file("testdata/inflection/$file", binmode => ':utf8');
	my @actual = find_pronunciation_files($wikt_lang, $lang, $word, \$input, $audios);
	assert_deep_equals $expected, \@actual;
	1;
}
