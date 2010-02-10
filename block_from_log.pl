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
use Switch;

# ========== settings
my $output = "to_block.txt";
my $users_list=',Zzuuzz,ProcseeBot,Spellcast,Dominic,Tiptoety'; # first comma to make no user
my $limit = 500;
my $from = ''; # format: 2009-02-27
my $recache=0;
Derbeth::Web::enable_caching(1);
# ============ end settings

GetOptions('limi|l=i' => \$limit, 'from|f=s' => \$from, 'users|u=s' => \$users_list,
	'recache|r' => \$recache) or die "wrong usage";

if ($from) {
	die "'from' is '$from', should be in form like '2009-02-27'" if ($from !~ /^\d{4}-\d{2}-\d{2}$/);
	$from =~ s/-//g;
	$from .= '000000';
}
die unless ($users_list);
my @users = split /, */, $users_list;

# ======= main

open(OUT,">>$output") or die "cannot write to $output";

my $saved=0;
foreach my $user (@users) {
	my $last_time = '';
	my $user_blocked=0;
	my $url = "http://en.wikipedia.org/w/index.php?title=Special:log&limit=$limit&type=block&hide_patrol_log=1";
	$url .= "&user=$user" if ($user);
	$url .= "&offset=$from" if ($from);
	my $html = Derbeth::Web::get_page($url,$recache);
	if (!$html || $html !~ /\w/) {
		die "cannot get $url";
	}
	while ($html =~ /<li class="mw-logline-block">(.*)/gc) {
		my $line = $1;
			if ($line =~ /^([^<]+)<a href=/) {
				my $this_time = parse_date($1);
				$last_time = $this_time if (!$last_time || $this_time lt $last_time);
		}

		next unless ($line =~ / (blocked|changed block settings) /);
		$line = $';
		next unless ($line =~ /\{\{(?:blocked ?proxy|anonblock|tor)\}\}|indefinite|5 years/i);
		next unless($line =~ /class="mw-userlink">(\d+\.[^<]+)</);
		my $ip = $1;
		my $time = '2 years';
		if ($line =~ /indefinite|5 years/i) {
			$time = '5 years';
		} elsif ($line =~ /\d month|week|day|hour/) {
			next if ($from);
			$time = '1 year';
		}
		$ip =~ s/^ +| +$//g;
		if ($ip !~ /^\d+\.\d+\.\d+\.\d+(\/\d+)?$/) {
			print STDERR "wrong ip '$ip'\n";
		} else {
			my $reason = "open proxy wg en.wiki [[w:en:Special:Contributions/$ip]]";
			my $origin = "en.wiki";
			$origin .= ", user $user" if ($user);
			print OUT join("\t", $ip,$time,$reason,$origin), "\n";
			++$saved;
			++$user_blocked;
		}
	}
	print "user $user, blocked $user_blocked, last time $last_time\n";
}
close(OUT);

print "$saved IPs to block\n";

# == END

sub parse_date {
	my ($date_time) = @_;
	$date_time =~ /(\d+):(\d+), (\d+) (\w+) (\d+)/ or die "$date_time";
	my ($day,$month_str,$year) = ($3,$4,$5);
	$day = "0$day" if ($day < 10);
	my $month = month_to_str($month_str);
	return "$year-$month-$day";
}

sub month_to_str {
	switch (shift @_) {
		case /January/i { return '01' }
		case /February/i { return '02' }
		case /March/i { return '03' }
		case /April/i { return '04' }
		case /May/i { return '05' }
		case /June/i { return '06' }
		case /July/i { return '07' }
		case /August/i { return '08' }
		case /September/i { return '09' }
		case /October/i { return 10 }
		case /November/i { return 11 }
		case /December/i { return 12 }
		else { die }
	}
}

