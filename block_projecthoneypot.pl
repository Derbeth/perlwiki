#!/usr/bin/perl -w

# MIT License
#
# Copyright (c) 2007 Derbeth
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

use Derbeth::Web 0.4.1;
use Derbeth::Util;
use Encode;
use Getopt::Long;

use strict;
use utf8;

# ========== settings
my $output = "to_block.txt";
my $origin = "projecthoneypot.org";
my $block_reason = "IP na listach spamu<!--projecthoneypot.org-->";
my $recache=0;
Derbeth::Web::enable_caching(1);
# ============ end settings

GetOptions('r|recache' => \$recache, 'o|output=s' => \$output) or die "wrong usage";


# ======= main

open(OUT,">>$output") or die "cannot write to $output";

my $saved=0;

my $url = "http://projecthoneypot.org/list_of_ips.php";
my $html = Derbeth::Web::get_page($url,$recache);
if (!$html || $html !~ /\w/) {
	print "cannot get $url\n";
	exit 3;
}

my @countries;
while ($html =~ /<option value="(ctry=\w+)">/gc) {
	push @countries, $1;
}
$html =~ /NOSUCH/gc; # reset
process_html($html);
foreach my $country (sort @countries) {
	get_and_process($country);
}

close(OUT);
print "$saved IPs to block\n";

# END

sub get_and_process {
	my ($country) = @_;
	my $url = "http://projecthoneypot.org/list_of_ips.php";
	$url .= "?$country" if ($country);
	my $html = Derbeth::Web::get_page($url,$recache);
	if (!$html || $html !~ /\w/) {
		print "cannot get $url\n";
		return;
	}
	process_html($html,$country);
}

sub process_html {
	my ($html,$country) = @_;
	$country =~ s/ctry=// if ($country);
	my $this_origin = $origin;
	$this_origin .= ", country $country" if ($country);
	my $this_reason = $block_reason;
	$this_reason =~ s/(-->)/, $country$1/ or die if ($country);
	while ($html =~ m!>(\d+.\d+.\d+.\d+)</a>!gc) {
		my $ip = $1;
		my $time = '6 months';
		$ip =~ s/^ +| +$//g;
		if ($ip !~ /^\d+\.\d+\.\d+\.\d+(\/\d+)?$/) {
			print STDERR "wrong ip '$ip'\n";
		} else {
			print OUT join("\t", $ip,$time,$this_reason,$this_origin), "\n";
			++$saved;
		}
	}
}
