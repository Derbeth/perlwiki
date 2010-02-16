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
my $block_reason = "edytowanie przez proxy jest niedozwolone";
my $proxy_list = '';
my $recache=0;
Derbeth::Web::enable_caching(1);
# ============ end settings

GetOptions('recache|r' => \$recache, 'proxy|p=s' => \$proxy_list,
	'output|o=s' => \$output) or die "wrong usage";

my @proxies = split(/,/, $proxy_list);

# ======= main

open(OUT,">>$output") or die "cannot write to $output";

my $saved=0;
my $countries = Derbeth::Web::get_page("http://www.proxylist.net/sort/country", $recache);

while ($countries =~ m!href="(/list/([^/]+)/([^/]+)/([^/]+))"!gc) {
	die "WTF? $1\n" if ($3 ne '0' || $4 ne '1');
	my $country = $2;
	PAGE:
	foreach my $page (1..50) {
		my $url = "http://www.proxylist.net/list/$country/0/$page";
		my $html = Derbeth::Web::get_page($url,$recache);
		if (!$html || $html !~ /\w/) {
			print "cannot get $url\n";
			my $proxy = pop @proxies;
			if ($proxy) {
				Derbeth::Web::use_proxy("http://$proxy");
				print "using proxy $proxy\n";
				redo PAGE;
			} else {
				last PAGE;
			}
		}
		last PAGE if ($html =~ /No proxies found!<\/div>/);
		while ($html =~ m!href="/proxy/(\d+.\d+.\d+.\d+)[:"]!gc) {
			my $ip = $1;
			my $time = '1 year';
			$ip =~ s/^ +| +$//g;
			if ($ip !~ /^\d+\.\d+\.\d+\.\d+(\/\d+)?$/) {
				print STDERR "wrong ip '$ip'\n";
			} else {
				my $origin = "proxylist.net, country $country";
				print OUT join("\t", $ip,$time,$block_reason,$origin), "\n";
				++$saved;
			}
		}
	}
}

close(OUT);
print "$saved IPs to block\n";

