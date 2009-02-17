#!/usr/bin/perl

use strict;
use utf8;

use Encode;
use Derbeth::Util;

my (%no_entry, %without_audio, %done);

read_hash_loose('done/done_rovdyr.txt', \%done);

open(IN,'done/done_rovdyr.txt');

while (my ($entry,$result) = each(%done)) {
	my @parts = split /\|/, $result;	
	if($parts[0] eq 'no_entry') {
		$no_entry{$entry} = $parts[1];
	} elsif ($parts[0] eq 'entry_without_audio') {
		$without_audio{$entry} = $parts[1];
	}
}

print encode_utf8("== Jest wymowa, ale nie ma hasła ==\n\n");

print_hash(\%no_entry);

print encode_utf8("\n\n== Jest wymowa i jest hasło (pewnie nie po rosyjsku) ==\n\n");

print_hash(\%without_audio);

sub print_hash {
	my $hash_ref=shift;
	my $counter=0;
	print encode_utf8("{| class=\"wikitable sortable\"
! nr !! hasło !! plik
");
	foreach my $tit (sort(keys(%$hash_ref))) {
		++$counter;
		my $audio = $hash_ref->{$tit};
		print encode_utf8("|-\n| $counter || [[$tit]] || [[commons:Image:$audio]]\n") 
	}
	print "|}\n";
}
