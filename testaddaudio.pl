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
my $TEST_TEMP_DIR = '/tmp/ort-test';

my %test_number = ('en'=>2, 'de'=>0, 'pl'=>0);

`rm -rf $TEST_TEMP_DIR/`;
`mkdir $TEST_TEMP_DIR`;

for my $wikt_lang('pl','de','en') {
	for (my $i=0; $i<$test_number{$wikt_lang}; ++$i) {
		my $test_input = "${TESTDATA_DIR}/$wikt_lang/in${i}.txt";
		my $test_output = "${TEST_TEMP_DIR}/out${i}.txt";
		my $test_expected = "${TESTDATA_DIR}/$wikt_lang/out${i}.txt";
		my $args_file = "${TESTDATA_DIR}/$wikt_lang/arg${i}.txt";
		
		my %args;
		read_hash_loose($args_file, \%args);
		do_test($wikt_lang, $test_input, $test_output, %args);
		my $equal = &compare_files($test_output, $test_expected);
		if (!$equal) {
			print "Test failed.\n";
			`kdiff3 $test_output $test_expected`;
			exit(11);
		}
	}
	print "$wikt_lang: $test_number{$wikt_lang} tests succeeded.\n";
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
	my ($wikt_lang, $test_input, $test_output, %args) = @_;
	open(OUT,">$test_output");

	my $text = text_from_file($test_input);
	my $language = get_language_name($wikt_lang,'en');

	my $initial_summary = initial_cosmetics($wikt_lang,\$text);
	my ($before, $section, $after) = split_article_wikt($wikt_lang,$language,$text);
	my @retval = add_audio($wikt_lang,\$section,$args{'audio'},$language,0,$args{'plural'},$args{'audio_pl'},$args{'ipa'},$args{'ipa_pl'});
	#print STDERR @retval, "\n";
	print OUT encode_utf8($before.$section.$after);
	close(OUT);
}