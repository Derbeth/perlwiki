#!/usr/bin/perl -w

use strict;

use Derbeth::Inflection;
use File::Slurp;
use Test::Assert ':all';

my $checked = 0;

check('Alpen.txt', '', 'Alpen');
check('Inkarnation.txt', 'Inkarnation', 'Inkarnationen');
check('Mutter.txt', 'Mutter', 'Mütter', 'Muttern');
check('Opossum.txt', 'Opossum', 'Opossums');
check('Sein.txt', 'Sein');

print $checked, " checks succeeded\n";

sub check {
	my ($file, @expected) = @_;
	my $input = read_file("testdata/inflection/$file");
	my @actual = extract_de_inflection_dewikt(\$input);
	assert_deep_equals \@expected, \@actual;
	++$checked;
}
