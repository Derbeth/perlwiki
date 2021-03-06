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

use Derbeth::Web;
use Derbeth::Util;
use Encode;
use Getopt::Long;

use strict;
use utf8;

# ========== settings
my $output = "to_block.txt";
my $origin = "ifreeproxies.com";
my $block_reason = "edytowanie przez proxy jest niedozwolone";
my $recache=0; # ignored
Derbeth::Web::enable_caching(0);
# ============ end settings

GetOptions('r|recache' => \$recache) or die "wrong usage";

# ======= main

open(OUT,">>$output") or die "cannot write to $output";

my $saved=0;

my $url = "http://www.ifreeproxies.com/proxies/by/ip";
my $html = Derbeth::Web::get_page($url);
if (!$html || $html !~ /\w/) {
	print "cannot get $url\n";
	last;
}
while ($html =~ /<li><a href="#[^"]+">([^<]+)<\/a>/gc) {
	my $ip = $1;
	my $time = '1 year';
	$ip =~ s/^ +| +$//g;
	if ($ip !~ /^\d+\.\d+\.\d+\.\d+(\/\d+)?$/) {
		print STDERR "wrong ip '$ip'\n";
	} else {
		print OUT join("\t", $ip,$time,$block_reason,$origin), "\n";
		++$saved;
	}
}

close(OUT);
print "$saved IPs to block\n";

