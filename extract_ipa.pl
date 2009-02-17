#!/usr/bin/perl

# Usage:
#   put Swadesh wikicode do swadesh.txt
#   ./extract_ipa.pl > ipa_pl.txt // ipa_de.txt ipa_en.txt

use Encode;

use strict;

open(IPA,'swadesh.txt');

my %ipa;
my @words;

while(my $line=<IPA>) {
	$line = decode_utf8($line);
	#chomp $line;
	#$line =~ s/\s+$//g;
	
	if ($line =~ /^\|wrd0*(\d+)=(.*)/) {
		my ($m1,$m2)=($1,$2);
		$m2 =~ s/\s*''[^']+''//g;
		$m2 =~ s/\s*\([^)]+\)//g;
		$m2 =~ s/;/,/g;
		$m2 =~ s/  / /g;
		$m2 =~ s/\s*\*//g;
		$m2 =~ s/\s+$//g;
		$words[$m1] = $m2;
		#print "wo: $1 - $2 - $words[$1]\n";
	} elsif ($line =~ /^\|pho0*(\d+)=(.*)/) {
		my($m1,$m2) = ($1,$2);
		$m2 =~ s/\s*''[^']+''//g;
		$m2 =~ s/\s*\([^)]+\)//g;
		$m2 =~ s/;/,/g;
		$m2 =~ s/  / /g;
		$m2 =~ s/\s*\*//g;
		$m2 =~ s/\s+$//g;
		$m2 =~ s/{{BIPA\|//g;
		$m2 =~ s/}}//g;
		my @word_parts = split /,\s+/, $words[$m1];
		my @ipa_parts = split /,\s+/, $m2;
		for (my $i=0; $i<=$#word_parts; ++$i) {
			if ($word_parts[$i] ne '' && $ipa_parts[$i] ne '') {
				$ipa{ $word_parts[$i] } = $ipa_parts[$i];
			}
		}
	} else {
		#print "no match for line: ".encode_utf8($line);
	}
}

while (my($word,$pron) = each(%ipa)) {
	print encode_utf8($word).'='.encode_utf8($pron)."\n";
}
