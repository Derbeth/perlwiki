#!/usr/bin/perl -w

use strict;
use utf8;

use Derbeth::Util;
use File::Slurp;
use File::Temp qw/tempfile/;
use Test::Assert ':all';

test_save_hash_sorted();
test_save_read_big_hash();
print "Passed\n";

sub test_save_hash_sorted {
	my %data;
	$data{"Noun"} = "Polska";
	$data{"verb"} = "być";
	$data{"more"} = "foo";
	my $expected = <<END;
Noun=Polska
more=foo
verb=być
END

	my ($fh,$tempfile_name)=tempfile();
	save_hash_sorted($tempfile_name, \%data);
	my $saved = read_file($tempfile_name, binmode => ':utf8');
	assert_equals $expected, $saved;
}

sub test_save_read_big_hash {
	# don't use /tmp - try to catch errors when copying between devices
	system("rm -f big-hash.txt");
	my $size = 400000;
	my %data;
	foreach my $i (1..$size) {
		$data{"word$i"} = $i % 2 == 1 ? "no_audio" : "has_pronunciation";
	}
	save_hash("big-hash.txt", \%data);
	my %read_data;
	read_hash_loose("big-hash.txt", \%read_data);
	assert_equals $size, scalar(keys(%read_data));
	assert_equals "has_pronunciation", $read_data{"word300000"};
	assert_equals "no_audio", $read_data{"word300001"};
}
