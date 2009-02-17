#!/usr/bin/perl

use strict;
use utf8;

use Encode;
use Getopt::Long;

my $langs='de';

GetOptions('l|lang=s'=>\$langs);

my @lang_codes = split /,/, $langs;

my $data_file = 'done_nottranslated.txt';

my %entries = {};
foreach my $lang_code (@lang_codes) {
	$entries{$lang_code} = {
		'not_linked' => {},
		'not_linked_from_Polish' => {},
		'not_linked_to_this_language' => {}
	};
}

open(IN,$data_file);
while(<IN>) {
	$_ = decode_utf8($_);
	chomp;
	
	if (/(\w+)-([^=]+)=(.*)/) {
		if (!is_current_lang($1)) {
			next;
		}
		
		if ($3 eq 'not_linked' || $3 eq 'not_linked_from_Polish'
		||  $3 eq 'not_linked_to_this_language') {
			$entries{$1}{$3}{$2} = 1;
		} elsif ($3 eq 'linked') {
			# do nothing
		} else {
			print encode_utf8("unrecognised line: $_\n");
		}
	} else {
		print encode_utf8("read error: $_\n");
	}
}

foreach my $lang_code (@lang_codes) {
	open(OUT, ">nottrans_${lang_code}.txt");
	print OUT encode_utf8("==Hasła, do których nic nie linkuje==\n");
	print_entry_list(\*OUT, $entries{$lang_code}{'not_linked'});
	print OUT encode_utf8("==Hasła, do których nie linkuje żadne polskie hasło==\n");
	print_entry_list(\*OUT, $entries{$lang_code}{'not_linked_from_Polish'});
	print OUT encode_utf8("==Hasła, do których linkuje polskie hasło, ale link nie jest tłumaczeniem==\n");
	print_entry_list(\*OUT, $entries{$lang_code}{'not_linked_to_this_language'});
	close(OUT);
}

sub is_current_lang {
	my $arg = shift;
	foreach my $code (@lang_codes) {
		if ($arg eq $code) {
			return 1;
		}
	}
	return 0;
}

sub print_entry_list {
	my ($fh,$hash_ref) = @_;
	foreach my $entry (sort keys(%$hash_ref)) {
		print $fh encode_utf8("# [[$entry]]\n");
	}
	print $fh "\n";
}
