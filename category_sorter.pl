#!/usr/bin/perl

my @cats;
my %pages;
my $sum_pages=0;

while(<>) {
	if (/^Category: (British )?(\S+).*pages:\s+(\d+)/) {
		if (!exists($pages{$2})) {
			$pages{$2} = $3;
			push @cats, $2;
		} else {
			$pages{$2} += $3;
		}
		$sum_pages += $3;
	} else {
		print "oops: $_\n";
	}
}

my @sorted = sort { $pages{$b} <=> $pages{$a} } @cats;

foreach my $sort (@sorted) {
	print "$sort: $pages{$sort}\n";
}

print "sum: $sum_pages\n";