#!/usr/bin/perl -w

use strict;
use Derbeth::Wikitools;
use Derbeth::Wiktionary;
use Derbeth::I18n;
use Derbeth::Inflection;
use Derbeth::Util;
use Derbeth::Web;
use Getopt::Long;
use Encode;

my $interactive=0; # run kdiff3

GetOptions('i|interactive!'=> \$interactive) or die;

my @VALID_ARGS = qw{added_audios audio audio_pl ipa ipa_pl lang_code  plural result word};
my $TESTDATA_DIR = 'testdata';
my $TEST_TEMP_DIR = '/tmp/testaddaudio-test';

my @tested_wikts = qw/de en pl simple fr/;

`rm -rf $TEST_TEMP_DIR/`;
`mkdir $TEST_TEMP_DIR`;

my %valid_args;
foreach (@VALID_ARGS) { $valid_args{$_} = 1; }

for my $wikt_lang(@tested_wikts) {
	my $i=0;
	while(1) {
		my $test_input = "${TESTDATA_DIR}/$wikt_lang/in${i}.txt";
		my $test_output = "${TEST_TEMP_DIR}/out${i}.txt";
		my $test_expected = "${TESTDATA_DIR}/$wikt_lang/out${i}.txt";
		my $args_file = "${TESTDATA_DIR}/$wikt_lang/arg${i}.ini";

		unless (-e $test_input) {
			last;
		}
		
		my %args;
		read_hash_loose($args_file, \%args);
		validate_args($args_file, %args);
		my $equal = do_test($test_input, $wikt_lang, $test_input, $test_output, %args)
		&& compare_files($test_output, $test_expected);
		if (!$equal) {
			print "Test $i failed.\n";
			if ($interactive) {
				system("kdiff3 $test_output $test_expected -L1 Received -L2 Expected");
			} else {
				system("diff -u $test_output $test_expected");
			}
			exit(11);
		}

		++$i;
	}
	print "$wikt_lang: $i tests succeeded.\n";
	system("rm -f $TEST_TEMP_DIR/*");
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
	my $lang_code = 'en';
	$lang_code = $args{'lang_code'} if (exists $args{'lang_code'});
	my $word = $args{'word'};
	unless($word) {
		print "missing 'word' parameter for $file\n";
		return 0;
	}

	my $initial_summary = initial_cosmetics($wikt_lang,\$text);
	my ($before, $section, $after) = split_article_wikt($wikt_lang,$lang_code,$text,1);
	my ($result,$added_audios,$edit_summary) = add_audio_new($wikt_lang,\$section,$args{'audio'},$lang_code,0,$word,$args{'audio_pl'},$args{'plural'},$args{'ipa'},$args{'ipa_pl'});
	$text = $before.$section.$after;
	final_cosmetics($wikt_lang, \$text);
	print OUT encode_utf8($text);
	close(OUT);

	if (exists($args{'result'}) && $args{'result'} != $result) {
		print "$file: expected result $args{result} but got $result ($edit_summary)\n";
		return 0;
	}
	if (exists($args{'added_audios'}) && $args{'added_audios'} != $added_audios) {
		print "$file: expected added $args{added_audios} but got $added_audios ($edit_summary)\n";
		return 0;
	}
	return 1;
}

sub validate_args {
	my ($args_file, %args) = @_;
	foreach my $k (sort keys %args) {
		unless(exists $valid_args{$k}) {
			die "$args_file: illegal argument '$k'. Valid arguments are: @VALID_ARGS";
		}
	}
}
