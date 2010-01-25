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
my $category_name = 'German pronunciation';

my %settings = load_hash('settings.ini');
my $user = $settings{'bot_login'};
my $pass = $settings{'bot_password'};

my $donefile = "done/sort_commons_cat.txt";
Derbeth::Web::enable_caching(1);
# ============ end settings

my %done;
read_hash_loose($donefile, \%done);

$SIG{INT} = $SIG{TERM} = $SIG{QUIT} = sub { save_results(); exit; };

# ======= main

my $editor=MediaWiki::Bot->new($user);
$editor->{debug} = 1;
$editor->set_wiki('commons.wikimedia.org', 'w');
my $res = $editor->login($user, $pass); # die "cannot login $res $user $pass";

if (scalar(keys %done) == 0) {
	foreach my $page (get_category_contents('http://commons.wikimedia.org/w/',"Category:$category_name")) {
		$done{$page} = 'not_done';
	}
}

print scalar(keys %done), " pages\n";

foreach my $page (sort keys(%done)) {
	my $is_done = $done{$page};
	next if ($is_done eq 'not_fixed' || $is_done eq 'skipped' || $is_done eq 'fixed');

	if ($page =~ /De-([^.]+)\.ogg/i) {
		my $sortkey = $1;
		$sortkey =~ s/^(at)-//i;

		my $text = $editor->get_text($page);
		my $fixx = ($text =~ s/\|(at)-[^\]]+\]\]/]]/i);
		my $changed = ($text =~ s/\[\[ *Category *: *($category_name)\]\]/[[Category:$1|$sortkey]]/);
		if (!$changed && !$fixx) {
			print "nothing to fix: ", encode_utf8($page), "\n";
			$done{$page} = 'not_fixed';
		} else {
			my $edited = $editor->edit($page,$text,'catsort',1);
			if ($edited) {
				print "fixed ", encode_utf8($page), "\n";
				$done{$page} = 'fixed';
				#last;
			} else {
				die "failed to fix ", encode_utf8($page);
			}
		}
	} else {
		print "skipping because of name ", encode_utf8($page), "\n";
		$done{$page} = 'skipped';
	}
}

save_results();

# ======= end main

sub save_results {
	save_hash_sorted($donefile, \%done);
}

