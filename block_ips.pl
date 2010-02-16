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
use Derbeth::Util;
use Encode;
use Getopt::Long;

use strict;
use utf8;

# ========== settings
my $dry_run=0;
my $input = "to_block.txt";
my $quiet=0;

my $wiki = 'pl.wikinews.org';
my %settings = load_hash('Derbeth.ini');
my $user = $settings{'bot_login'};
my $pass = $settings{'bot_password'};

my $donefile = "done/block_proxies.txt";
# ============ end settings

GetOptions('wiki|w=s' => \$wiki, 'dry-run|d!' => \$dry_run,
	'input|i=s' => \$input, 'quiet|q!' => \$quiet) or die "wrong usage";

my $blocked=0;
my %done;
my %done_now;
read_hash_loose($donefile, \%done);

$SIG{INT} = $SIG{TERM} = $SIG{QUIT} = sub { print "blocked $blocked IPs\n"; save_results(); exit 10; };

# ======= main

my $admin=MediaWiki::Bot->new();
#$admin->{debug} = 1;
$admin->set_wiki($wiki, 'w');
$admin->login($user, $pass) == 0 or die "cannot login to $wiki";

my $how_many = `cat $input | wc -l`;
chomp($how_many);
print "$how_many IPs to block\n";

sleep 2;

my $all_processed=0;
my $checked=0;
open(IN, $input) or die "cannot open $input";
while (<IN>) {
	chomp;
	my ($ip,$time,$block_reason,$origin) = split /\t/;
	next unless($ip && $time && $block_reason && $ip =~ /^\d+\.\d+\.\d+\.\d+/);

	++$all_processed;
	if (my $how_done = is_done($ip)) {
		unless($quiet) {
			print "already done: $ip";
			if (exists($done_now{$ip})) {
				print " (now)";
			} else {
				my @parts = split /\|/, $how_done;
				if ($#parts >= 3) {
					print " ($parts[3]";
					my $end = $#parts >= 4 ? " $parts[4])" : ")";
					print $end;
				}
			}
			print "\n";
		}
		next;
	}

	if ($dry_run) {
		++$blocked;
		mark_done($ip, 'dry_run_block');
		$done_now{$ip} = 1;
		print "would block $ip on $wiki for $time ($origin)\n";
		next;
	}

	if (++$checked % 20 == 0) {
		print "done $all_processed/$how_many, blocked $blocked\n";
		save_results();
	}
	if ($admin->test_blocked($ip)) {
		mark_done($ip, 'already_blocked');
		print "already blocked on $wiki: $ip\n";
		next;
	}
	my $res = $admin->block($ip, $time, $block_reason, 1, 1, 1);
	if ($res && $res !~ /^\d+/) {
		print "blocked $ip on $wiki for $time ($origin)\n";
		my $blocked_on = get_current_time();
		mark_done($ip, "blocked|$time|$block_reason|$origin|$blocked_on");
		$done_now{$ip} = 1;
		++$blocked;
	} else {
		print "failed to block $ip ($res)\n";
		save_results();
		die;
	}
	#last;
}

print "blocked $blocked IPs";
print " (dry run)" if ($dry_run);
print "\n";
save_results();

# ======= end main

sub get_current_time {
	my ($sec,$min,$hour,$mday,$mon,$year) = localtime(time);
	$year += 1900;
	++$mon;
	$mon = "0$mon" if ($mon < 10);
	$mday = "0$mday" if ($mday < 10);
	$hour = "0$hour" if ($hour < 10);
	$min = "0$min" if ($min < 10);
	return "$year-$mon-$mday $hour:$min";
}

sub is_done {
	my ($ip) = @_;
	return $done{"$wiki-$ip"};
}

sub mark_done {
	my ($ip, $comment) = @_;
	$done{"$wiki-$ip"} = $comment;
}

sub save_results {
	return if ($dry_run);
	save_hash_sorted($donefile, \%done);
}

