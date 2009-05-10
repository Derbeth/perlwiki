#!/usr/bin/perl

use strict;
use Derbeth::Wikitools;
use Derbeth::Wiktionary;
use Derbeth::I18n;
use Derbeth::Inflection;
use Derbeth::Util;
use Derbeth::Web;
use Encode;

my $TESTDATA_DIR = 'testdata';
my $TEST_TEMP_DIR = '/tmp/testaddaudio-test';

my @tested_wikts = ('de', 'en', 'pl', 'simple');

`rm -rf $TEST_TEMP_DIR/`;
`mkdir $TEST_TEMP_DIR`;

for my $wikt_lang(@tested_wikts) {
	my $i=0;
	while(1) {
		my $test_input = "${TESTDATA_DIR}/$wikt_lang/in${i}.txt";
		my $test_output = "${TEST_TEMP_DIR}/out${i}.txt";
		my $test_expected = "${TESTDATA_DIR}/$wikt_lang/out${i}.txt";
		my $args_file = "${TESTDATA_DIR}/$wikt_lang/arg${i}.txt";

		unless (-e $test_input) {
			last;
		}
		
		my %args;
		read_hash_loose($args_file, \%args);
		do_test($test_input, $wikt_lang, $test_input, $test_output, %args);
		my $equal = &compare_files($test_output, $test_expected);
		if (!$equal) {
			print "Test failed.\n";
			`kdiff3 $test_output $test_expected`;
			exit(11);
		}

		++$i;
	}
	print "$wikt_lang: $i tests succeeded.\n";
}
print "all ok\n";
exit(0);

# returns true if files are identical, otherwise false.
# when files are not identical, prints diff to standard output.
sub compare_files {
	my ($file1,$file2) = @_;
	my $result = `diff $file1 $file2`;
	if ($result eq '') {
		return 1;
	} else {
		#print $result;
		return 0;
	}
}

sub do_test {
	my ($file, $wikt_lang, $test_input, $test_output, %args) = @_;
	open(OUT,">$test_output");

	my $text = text_from_file($test_input);
	my $language = get_language_name($wikt_lang,'en');

	my $initial_summary = initial_cosmetics($wikt_lang,\$text);
	my ($before, $section, $after) = split_article_wikt($wikt_lang,$language,$text);
	my ($result,$added_audios,$edit_summary) = add_audio($wikt_lang,\$section,$args{'audio'},$language,0,$args{'plural'},$args{'audio_pl'},$args{'ipa'},$args{'ipa_pl'});

	if (exists($args{'result'}) && $args{'result'} != $result) {
		die "$file: expected result $args{result} but got $result ($edit_summary)";
	}
	if (exists($args{'added_audios'}) && $args{'added_audios'} != $added_audios) {
		die "$file: expected added $args{added_audios} but got $added_audios ($edit_summary)";
	}
	
	print OUT encode_utf8($before.$section.$after);
	close(OUT);
}