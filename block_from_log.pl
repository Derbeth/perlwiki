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
Derbeth::Web::enable_caching(1);
# ============ end settings

GetOptions('wiki|w=s' => \$wiki, 'limi|l=i' => \$limit) or die "wrong usage";

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
	my $en_wiki = MediaWiki::Bot->new();
	$en_wiki->set_wiki('en.wikipedia.org');
	foreach my $log ("&user=Zzuuzz","&user=ProcseeBot","&user=Spellcast","") {
		my $url = "http://en.wikipedia.org/w/index.php?title=Special:log&limit=$limit&type=block&hide_patrol_log=1$log";
		my $html = Derbeth::Web::get_page($url);
		if (!$html || $html !~ /\w/) {
			die "cannot get $url";
		}
		while ($html =~ /<li class="mw-logline-block">(.*)/gc) {
			my $line = $1;
			next unless ($line =~ / blocked /);
			$line = $';
			next unless ($line =~ /\{\{(?:blocked ?proxy|anonblock|tor)\}\}|indefinite|5 years/i);
			next unless($line =~ /class="mw-userlink">(\d+\.[^<]+)</);
			my $ip = $1;
			my $time = '2 years';
			if ($line =~ /indefinite|5 years/i) {
				$time = '5 years';
			} elsif ($line =~ /\d months|weeks/) {
				$time = '1 year';
			}
			$ip =~ s/^ +| +$//g;
			if ($ip !~ /^\d+\.\d+\.\d+\.\d+(\/\d+)?$/) {
				print STDERR "wrong ip '$ip'\n";
			} else {
				$ips{$ip} = $time;
			}
		}
	}
}

print scalar(keys %ips), " IPs to block\n";

#foreach my $ip (sort keys(%ips)) {
#	print "block '$ip' for '$ips{$ip}'\n";
#}
#exit 0;

foreach my $ip (keys(%ips)) {
	if (is_done($ip)) {
		print "already done: $ip\n";
		next;
	}
	if ($admin->test_blocked($ip)) {
		mark_done($ip, 'alredy_blocked');
		print "already blocked on $wiki: $ip\n";
		next;
	}
	my $res = $admin->block($ip, $ips{$ip}, "open proxy wg en.wiki [[w:en:Special:Contributions/$ip]]", 1, 1, 1);
	if ($res && $res !~ /^\d+/) {
		print "blocked $ip on $wiki for $ips{$ip}\n";
		mark_done($ip, "blocked|$res");
	} else {
		print "failed to block $ip ($res)\n";
	}
	#last;
}

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

