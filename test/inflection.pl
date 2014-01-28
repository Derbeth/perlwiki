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

	$checked += check_pl('de', 'de', 'ignore-word', 'Alpen.txt', [], ['Alpen']);
	$checked += check_pl('de', 'de', 'ignore-word', 'Inkarnation.txt', ['Inkarnation'], ['Inkarnationen']);
	$checked += check_pl('de', 'de', 'ignore-word', 'Mutter.txt', ['Mutter'], ['Mütter', 'Muttern']);
	$checked += check_pl('de', 'de', 'ignore-word', 'Opossum.txt', ['Opossum'], ['Opossums']);
	$checked += check_pl('de', 'de', 'ignore-word', 'Sein.txt', ['Sein'], []);
	$checked += check_pl('de', 'en', 'ignore-word', 'house.txt', ['house'], ['houses']);
	$checked += check_pl('de', 'en', 'ignore-word', 'police.txt', ['police'], []);
	$checked += check_pl('de', 'en', 'ignore-word', 'tea.txt', ['tea'], []);
	$checked += check_pl('de', 'nl', 'ignore-word', 'hoofd.txt', ['hoofd'], ['hoofden']);
	$checked += check_pl('de', 'xx', 'use-this-word', 'hoofd.txt', ['use-this-word'], []);
	$checked += check_pl('xx', 'xx', 'use-this-word', 'hoofd.txt', ['use-this-word'], []);

	print "test_extract_plural: $checked checks succeeded\n";
}

sub test_match_pronunciation_files {
	my $checked = 0;

	# has sing, no audios
	$checked += check_match(['', ''], ['house'], [], {});
	# has sing, audio for sing
	$checked += check_match(['house.ogg', ''], ['house'], [], {'house'=>'house.ogg'});
	# has sing and plural, but audio only for sing
	$checked += check_match(['house.ogg', ''], ['house'], ['houses'], {'house'=>'house.ogg'});
	# has sing and plural, audio for sing and plural
	$checked += check_match(['house.ogg', 'houses.ogg'], ['house'], ['houses'], {'house'=>'house.ogg', 'houses'=>'houses.ogg'});
	# has sing and many plurals, audio for all
	$checked += check_match(['house.ogg', 'houses.ogg'], ['house'], ['houses', 'housen'],
		{'house'=>'house.ogg', 'houses'=>'houses.ogg', 'housen'=>'housen.ogg'});
	# has sing and many plurals, audio for sing and only for second plural
	$checked += check_match(['house.ogg', 'housen.ogg'], ['house'], ['houses', 'housen'],
		{'house'=>'house.ogg', 'housen'=>'housen.ogg'});
	# has no sing, has audio for plural
	$checked += check_match(['', 'houses.ogg'], [], ['houses'], {'houses'=>'houses.ogg'});
	# has no sing, does not have audio for plural
	$checked += check_match(['', ''], [], ['houses'], {});

	print "test_match_pronunciation_files: $checked checks succeeded\n";
}

sub test_find_pronunciation_files {
	my $input = read_file("testdata/inflection/Inkarnation.txt", binmode => ':utf8');
	my @actual = find_pronunciation_files('de', 'de', 'ignore-word', \$input, {'Inkarnation'=>'Inkarnation.ogg', 'Inkarnationen'=>'Inkarnationen.ogg'});
	assert_deep_equals ['Inkarnation.ogg', 'Inkarnationen.ogg', 'Inkarnation', 'Inkarnationen'], \@actual;
	print "test_find_pronunciation_files: succeeded\n";
}

sub check_pl {
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
