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
use Derbeth::I18n;
use Derbeth::Util;
use Derbeth::Wikitools;
use Encode;
use Getopt::Long;
use Term::ANSIColor;

use strict;
use utf8;

# ========== settings
my $category_name = 'German pronunciation';
my $lang_code = 'de';
my $page_regex = undef;
my $limit=undef;
my $pause=2;
my $clean=0;
my $verbose=0;
my $debug=0;

my $donefile = "done/sort_commons_cat.txt";
# ============ end settings

GetOptions(
	'c|category=s' => \$category_name,
	'l|lang=s' => \$lang_code,
	'r|regex=s' => \$page_regex,
	'limit=i' => \$limit,
	'clean' => \$clean,
	'd|debug' => \$debug,
	'p|pause=i' => \$pause,
	'v|verbose' => \$verbose,
) or die;

$page_regex ||= "File:$lang_code".'[- ]([^.]+)\.og[ag]';

die "regex '$page_regex' needs to have a capture group" if $page_regex !~ /\([^)]+\)/;

my %settings = load_hash('settings.ini');
my %done;
unlink $donefile if ($clean && -e $donefile);
read_hash_loose($donefile, \%done);

$SIG{INT} = $SIG{TERM} = $SIG{QUIT} = sub { print_progress(); save_results(); exit 1; };

# ======= main

my $editor = MediaWiki::Bot->new({
	assert => 'bot',
	host => 'commons.wikimedia.org',
	debug => $debug,
	login_data => {'username' => $settings{bot_login}, 'password' => $settings{bot_password}},
	operator => $settings{bot_operator},
});

print "Fixing pages like $page_regex in $category_name\n";

if (scalar(keys %done) == 0) {
	foreach my $page (Derbeth::Wikitools::get_category_contents_perlwikipedia($editor, "Category:$category_name",undef,{file=>1})) {
		$done{$page} = 'not_done';
	}
}

my $pages_count = scalar(keys %done);
print "$pages_count pages\n";
my $progress_every = $pages_count < 400 ? 50 : 100;
my $visited_pages=0;
my $processed_pages=0;
my $fixed_count=0;

foreach my $page (sort keys(%done)) {
	++$processed_pages;

	print_progress() if $visited_pages > 0 && $processed_pages % $progress_every == 0;

	my $is_done = $done{$page};
	next if ($is_done eq 'not_fixed' || $is_done eq 'skipped' || $is_done eq 'fixed');

	if ($page !~ /$page_regex/io) {
		print "skipping because of name ", encode_utf8($page), "\n" if $verbose;
		$done{$page} = 'skipped';
		next;
	}
	my $sortkey = $1;
	$sortkey =~ s/^(at)-//i;

	++$visited_pages;
	sleep $pause;

	my $text = $editor->get_text($page);
	unless (defined($text)) {
		if ($editor->{error} && $editor->{error}->{code}) {
			print colored('cannot','red'), encode_utf8(" get text of $page: "), $editor->{error}->{details}, "\n";
		} else {
			print 'unknown ', colored('error','red'), encode_utf8(" getting text of $page\n");
		}
		last;
	}

	my $changed = ($text =~ s/\[\[ *Category *: *($category_name) *\]\]/[[Category:$1|$sortkey]]/);
	if (!$changed) {
		print "nothing to fix: ", encode_utf8($page), "\n";
		$done{$page} = 'not_fixed';
		next;
	}
	my $edited = $editor->edit({page=>$page, text=>$text, bot=>1, minor=>1,
		summary=>"sort in Category:$category_name ($sortkey)"});
	if (!$edited) {
		print colored('failed','red'), " to fix ", encode_utf8($page);
		print " details: $editor->{error}->{details}" if $editor->{error};
		print "\n";
		last;
	}
	print encode_utf8("fixed $page using sort '$sortkey'\n");
	$done{$page} = 'fixed';
	++$fixed_count;

	if ($limit && $fixed_count >= $limit) {
		last;
	}
}

print_progress();
save_results();

# ======= end main

sub print_progress {
	my ($sec,$min,$hour) = localtime();
	printf '%02d:%02d %d/%d', $hour, $min, $processed_pages, $pages_count;
	printf colored(' %2.0f%%', 'green'), 100*$processed_pages/$pages_count;
	print " fixed $fixed_count\n";
}

sub save_results {
	save_hash_sorted($donefile, \%done);
}
