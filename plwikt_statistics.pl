#!/usr/bin/perl

# oblicza zestawienie języków na [[Wikisłownik:Statystyka]]

use strict;
use utf8;

use Derbeth::Wikitools;
use Derbeth::Wiktionary;
use Derbeth::Util;
use Encode;

Derbeth::Web::enable_caching(1);

my %settings = load_hash('settings.ini');
my $user = $settings{bot_login};
my $pass = $settings{bot_password};
my $wiki = 'localhost/~piotr/'; #'pl.wiktionary.org';
my $prefix = 'plwikt'; #'w';
my $donefile = "done/done_plwikt_statistics.txt";

my $server = "http://$wiki/$prefix/";

my %done; # 'polski' => 6421
my %old_place;
my %old_count;
my %code;
my %new_count; # = ('polski' => 16532, 'staro-wysoko-niemiecki' => 123, 'turecki' => 50);

$SIG{INT} = $SIG{TERM} = $SIG{QUIT} = sub { save_results(); exit; };

read_hash_loose($donefile, \%done);

# ==== main

open(IN, 'in.txt');

while (<IN>) {
	next if ($_ !~ /<td>/);
	s/<\/td>|<tr align="center">|<\/tr>//g;
	my @cols = split('<td[^>]*>', $_);
	#$, = " | "; print @cols;
	
	unless (/ \(indeks\)\|([^\]]+)\]\]/) {
		#print "problem: $_\n";
		next;
	}
	my $lang = $1;
	$lang = decode_utf8($lang);
	
	my $place = @cols[1];
	my $count = @cols[2];
	my $_code = @cols[7];
	
	#print "$lang || $place || $count || $_code\n";
	$old_place{$lang} = $place;
	$old_count{$lang} = $count;
	$code{$lang} = $_code;
}

# read categories

my @indices = get_category_contents($server,'Kategoria:Indeks słów wg języków',undef,{'category'=>1});
my $all_langs = scalar(@indices);
my $lang_count = 0;

foreach my $index (@indices) {
	++$lang_count;
	print "$lang_count/$all_langs\n" if ($lang_count % 10 == 0);
	
	$index =~ / \(indeks\)$/ or next; #die $index;
	my $lang = $`; # prematch
	$lang =~ s/^Kategoria://;
	if ($done{$lang}) {
		$new_count{$lang} = $done{$lang};
		next;
	}
	my @articles_in_lang = get_category_contents($server, "$index");
	$new_count{$lang} = scalar(@articles_in_lang);
	$done{$lang} = $new_count{$lang};
	
	if ($lang_count >= 1190) {
		print "interrupted\n";
		last;
	}
}

save_results();

# show results

my $total_count = 0;
while (my ($forget,$c) = each(%new_count)) {
	$total_count += $c;
}

open(OUT, '>out.txt');

print OUT <<END;
== Języki wg liczby haseł ==

<center>
<table class="wikitable">
<tr>
 <th> miejsce </th>
 <th> aktualnie <br/>12.07.2008 </th>
 <th> poprzednio <br/>10.05.2008 </th>

 <th> różnica </th>
 <th>poprz.<br/>miejsce</th>
 <th> język </th>
 <th> kod </th>
</tr>

<tr align="center">
 <td>  </td>
 <td> <i>$total_count</i> </td>
 <td> <i>x</i> </td>
 <td> <i>+x</i> </td><td></td>

 <td> <i> razem </i> </td>
 <td>  </td>
</tr>
END

my @sorted_langs = sort {
	my $c1 = $new_count{$a}; my $c2 = $new_count{$b};
	if ($c1 != $c2) {
		return $c2 <=> $c1;
	} else {
		return $a cmp $b;
	}
} keys(%new_count);
my $place = 1;
foreach my $lang (@sorted_langs) {
	my $old_c = 0;
	my $new_lang = 1;
	if (exists($old_count{$lang})) {
		$new_lang = 0;
		$old_c = $old_count{$lang};
	}
	
	my $diff = $new_count{$lang} - $old_c;
	$diff = '+'.$diff if ($diff > 0);
	my $bgcolor;
	if ($diff < 0) {
		$bgcolor = 'lightgrey';
	} elsif ($diff == 0) {
		$bgcolor = '';
	} elsif ($diff < 15) {
		$bgcolor = '#FFFF00';
	} elsif ($diff < 50) {
		$bgcolor = '#FFCE00';
	} elsif ($diff < 250) {
		$bgcolor = '#FFA300';
	} else {
		$bgcolor = 'chocolate';
	}
	if ($bgcolor) {
		$diff = "<td style=\"background-color:$bgcolor\">$diff</td>";
	} else {
		$diff = "<td>$diff</td>";
	}
	
	my $place_diff = $old_place{$lang} - $place;
	if ($new_lang) {
		$place_diff = '<span style="color:blue">NOWY <small></small></span>';
	} elsif ($place_diff > 0) {
		$place_diff = "<span style=\"color:green\">↑ <small>$old_place{$lang}</small></span>";
	} elsif ($place_diff < 0) {
		$place_diff = "<span style=\"color:red\">↓ <small>$old_place{$lang}</small></span>";
	} else {
		$place_diff = "<span style=\"color:lightgrey\">• <small>$old_place{$lang}</small></span>";
	}
	
	print OUT '<tr align="center">';
	print OUT "<td>$place</td>";
	print OUT "<td>$new_count{$lang}</td>";
	print OUT "<td>$old_c</td>";
	print OUT $diff;
	print OUT "<td>$place_diff</td>";
	print OUT encode_utf8("<td>[[:Kategoria:$lang (indeks)|$lang]]</td>");
	print OUT "<td>$code{$lang}</td>";
	print OUT '</tr>';
	print OUT "\n";
	++$place;
}

print OUT "</table></center>\n";

close(OUT);

# ==== end main

sub save_results {
	save_hash_sorted($donefile, \%done);
}
