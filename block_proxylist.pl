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

use MediaWiki::Bot;
use Derbeth::Web 0.4.0;
use Derbeth::Wikitools;
use Derbeth::Wiktionary;
use Derbeth::I18n;
use Derbeth::Inflection;
use Derbeth::Util;
use Encode;
use Getopt::Long;

use strict;
use utf8;

# ========== settings
my $wiki = 'pl.wikinews.org';
my %settings = load_hash('Derbeth.ini');
my $user = $settings{'bot_login'};
my $pass = $settings{'bot_password'};

my $donefile = "done/block_proxies.txt";
my $limit = 500;
my ($from,$to) = (1,30);
my $block_reason = "edytowanie przez proxy jest niedozwolone";
my $proxy_list = '';
my $recache=0;
Derbeth::Web::enable_caching(1);
# ============ end settings

GetOptions('wiki|w=s' => \$wiki, 'limi|l=i' => \$limit,
	'recache|r' => \$recache, 'proxy|p=s' => \$proxy_list,
	'from|f=i' => \$from, 'to|t=i' => \$to) or die "wrong usage";

my @proxies = split(/,/, $proxy_list);

my %done;
read_hash_loose($donefile, \%done);

$SIG{INT} = $SIG{TERM} = $SIG{QUIT} = sub { save_results(); exit; };

# ======= main

my %ips;

my $admin=MediaWiki::Bot->new();
#$admin->{debug} = 1;
$admin->set_wiki($wiki, 'w');
$admin->login($user, $pass) == 0 or die "cannot login to $wiki";

{
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
					$ips{$ip} = $time;
				}
			}
		}
	}
}

print scalar(keys %ips), " IPs to block\n";

#die;
#foreach my $ip (sort keys(%ips)) {
#	print "block '$ip' for '$ips{$ip}'\n";
#}
#exit 0;

my $all_processed=0;
my $blocked=0;
my $checked=0;
foreach my $ip (keys(%ips)) {
	++$all_processed;
	if (is_done($ip)) {
		print "already done: $ip\n";
		next;
	}
	if (++$checked % 25 == 0) {
		print "done $all_processed/", scalar(keys %ips), "\n";
		save_results();
	}
	if ($admin->test_blocked($ip)) {
		mark_done($ip, 'already_blocked');
		print "already blocked on $wiki: $ip\n";
		next;
	}
	my $res = $admin->block($ip, $ips{$ip}, $block_reason, 1, 1, 1);
	if ($res && $res !~ /^\d+/) {
		print "blocked $ip on $wiki for $ips{$ip}\n";
		mark_done($ip, "blocked|$ips{$ip}|$block_reason");
		++$blocked;
	} else {
		print "failed to block $ip ($res)\n";
		save_results();
		die;
	}
	#last;
}

print "blocked $blocked IPs\n";
save_results();

# ======= end main

sub is_done {
	my ($ip) = @_;
	return exists $done{"$wiki-$ip"};
}

sub mark_done {
	my ($ip, $comment) = @_;
	$done{"$wiki-$ip"} = $comment;
}

sub save_results {
	save_hash_sorted($donefile, \%done);
}

