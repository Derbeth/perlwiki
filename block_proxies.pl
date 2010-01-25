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

use strict;
use utf8;

# ========== settings
my $wiki = 'pl.wikinews.org';
my %settings = load_hash('Derbeth.ini');
my $user = $settings{'bot_login'};
my $pass = $settings{'bot_password'};

my $donefile = "done/block_proxies.txt";
Derbeth::Web::enable_caching(1);
# ============ end settings

my %done;
read_hash_loose($donefile, \%done);

$SIG{INT} = $SIG{TERM} = $SIG{QUIT} = sub { save_results(); exit; };

# ======= main

my %ips;

my $editor=MediaWiki::Bot->new($user);
#$editor->{debug} = 1;
$editor->set_wiki($wiki, 'w');
my $res = $editor->login($user, $pass); # die "cannot login $res $user $pass";

foreach my $entry (('en.wikipedia.org|Blocked Tor exit nodes', 'en.wikipedia.org|Open proxies blocked on Wikipedia', 'meta.wikimedia.org|Open proxies blocked on all participating projects')) {
	my ($server,$cat) = split /\|/, $entry;
	my @pages = get_category_contents("http://$server/w/","Category:$cat");
	print "$cat: ", scalar(@pages), " pages\n";
	foreach my $page (@pages) {
		if ($page =~ /User talk:(\d+\.\d+\.\d+\.\d+)/) {
			$ips{$1} = 1;
		}
	}
}

foreach my $ip (keys(%ips)) {
	if (is_done($ip)) {
		print "already done: $ip\n";
		next;
	}
	if ($editor->test_blocked($ip)) {
		mark_done($ip, 'alredy_blocked');
		print "already blocked on $wiki: $ip\n";
		next;
	}
	my $res = $editor->block($ip, '5 years', "open proxy wg en.wiki [[w:en:Special:Contributions/$ip]]", 1, 1, 1);
	if ($res) {
		print "blocked $ip\n";
		mark_done($ip, 'blocked');
	} else {
		print "failed to block $ip\n";
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

