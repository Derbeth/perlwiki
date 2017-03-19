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
use Derbeth::Cache;
use Derbeth::I18n;
use Derbeth::Util;
use Derbeth::Wikitools;
use Encode;
use Getopt::Long;
use Pod::Usage;
use Term::ANSIColor;

use strict;
use utf8;

# ========== settings
my $category_name = 'German pronunciation';
my $user = undef;
my $lang_code = 'de';
my $page_regex = undef;
my $limit=undef;
my $pages_limit=25000;
my $pause=2;
my $no_cache=0;
my $clean=0;
my $verbose=0;
my $debug=0;
my $dry_run=undef;
my $show_help=0;
my $randomize=0;

my $donefile = "done/category-jeuwre.txt";
# ============ end settings

GetOptions(
	'c|category=s' => \$category_name,
	'u|user=s' => \$user,
	'l|lang=s' => \$lang_code,
	'r|regex=s' => \$page_regex,
	'limit=i' => \$limit,
	'pages-limit=i' => \$pages_limit,
	'no-cache' => \$no_cache,
	'clean' => \$clean,
	'd|debug' => \$debug,
	'p|pause=i' => \$pause,
	'v|verbose' => \$verbose,
	'dry-run:s' => \$dry_run,
	'h|help' => \$show_help,
	'randomize' => \$randomize,
) or pod2usage('-verbose'=>1,'-exitval'=>1);
pod2usage('-verbose'=>2,'-noperldoc'=>1) if ($show_help);
pod2usage('-verbose'=>1,'-noperldoc'=>1, '-msg'=>'No args expected') if ($#ARGV != -1);

($category_name,$user,$page_regex,$dry_run) = map { defined $_ ? decode_utf8($_) : undef } ($category_name,$user,$page_regex,$dry_run);

$page_regex ||= "File:$lang_code".'[- ]([^.]+)\.og[ag]';

die "regex '$page_regex' needs to have a capture group" if $page_regex !~ /\([^)]+\)/;

my %settings = load_hash('settings.ini');
my %done;
unlink $donefile if ($clean && -e $donefile);
read_hash_loose($donefile, \%done);

# ======= main

my $editor = MediaWiki::Bot->new({
	assert => 'bot',
	host => 'commons.wikimedia.org',
	debug => $debug,
	login_data => {'username' => $settings{bot_login}, 'password' => $settings{bot_password}},
	operator => $settings{bot_operator},
});
$editor->{api}->{config}->{max_lag_delay} = 30;

my @pages;
if ($user) {
	print encode_utf8("Fixing pages like $page_regex in category $category_name from contributions of $user\n");
	my $key = "commons.wikimedia.org|$user|".($pages_limit||-1);
	my $cached_pages = $no_cache ? undef : cache_read_values($key);
	if (defined $cached_pages) {
		print "Reading from cache\n" if $verbose;
		@pages = @$cached_pages;
	} else {
		my $query = {action=>'query',list=>'usercontribs',ucuser=>$user, ucnamespace=>6,
			ucprop => 'title', ucshow => 'new'};
		$query->{uclimit} = $pages_limit if $pages_limit;
		my $result_ref = $editor->{api}->list($query, {max=>1})
			|| die $editor->{api}->{error}->{code} . ': ' . $editor->{api}->{error}->{details};
		@pages = map { $_->{title} } @{$result_ref};
		cache_write_values($key, \@pages);
	}
} else {
	print encode_utf8("Fixing pages like $page_regex in category $category_name\n");
	@pages = Derbeth::Wikitools::get_contents_include_exclude($editor,
		['German pronunciation'],
		['Bavarian pronunciation', 'German pronunciation of given names', 'German pronunciation of names of people'],
		{file=>1});
	@pages = Derbeth::Wikitools::get_category_contents_perlwikipedia($editor, "Category:$category_name",undef,{file=>1}, $no_cache);
	@pages = sort @pages;
}

my $pages_count = scalar(@pages);
print "$pages_count pages";
die if $pages_count == 0;
print ': ', encode_utf8($pages[0]);
print ' to ', encode_utf8($pages[$#pages]);
print "\n";

my $progress_every = $pages_count < 400 ? 25 : 100;
my $visited_pages=0;
my $processed_pages=0;
my $fixed_count=0;

@pages = sort { return int(rand(3)) -1; } @pages if $randomize;

if (defined $dry_run) {
	if ($dry_run) {
		test_match($dry_run);
	}
	if (@pages) {
		test_match($pages[0]);
	}
	exit;
}

$SIG{INT} = $SIG{TERM} = $SIG{QUIT} = sub { print_progress(); save_results(); exit 1; };

foreach my $page (@pages) {
	++$processed_pages;

	my $is_done = $done{$page};
	if ($is_done && $is_done ne 'not_done') {
		print encode_utf8("already done: $page\n") if $verbose && $visited_pages > 0;
		next;
	}

	print_progress() if $visited_pages > 0 && $processed_pages % $progress_every == 0;

	if ($page !~ /$page_regex/io) {
		print "skipping because of name ", encode_utf8($page), "\n" if $verbose && $visited_pages > 0;
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

	# initial cosmetics
	$text =~ s/\[\[ *Category *: */[[Category:/g;
	while ($text =~ s/(\[\[ *Category[^\]]+\]\]) *(\[\[Category)/$1\n$2/g) {};
	while ($text =~ s/\[\[ *Category *: *([^_\]|]+)_/[[Category:$1 /g) {}

	my $changed = 0;
	foreach my $term ($category_name, 'German pronunciation of [^|\]]+',
		'Audio files made by jeuwre', 'Created with Audacity',
		'Audio files made using a Rode NT-USB \(supported by Wikimedia Deutschland\)') {
		($text =~ s/\[\[ *Category *: *($term)\]\]/[[Category:$1|$sortkey]]/g) and $changed = 1;
	}
	if (!$changed) {
		if ($text =~ /Category:$category_name *\|([^\]]+)/) {
			print encode_utf8("already sorted: $page ($1)\n");
			$done{$page} = 'already_sorted';
		} elsif ($text =~ /\b$category_name\b/) {
			print encode_utf8("in category, but won't fix: $page\n");
			$done{$page} = 'not_fixed';
		} else {
			print encode_utf8("not in this category: $page\n");
			$done{$page} = 'not_in_category';
		}
		next;
	}
	my $edited = $editor->edit({page=>$page, text=>$text, bot=>1, minor=>1,
		summary=>"sort in categories ($sortkey)"});
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
		print "limit ($limit) reached\n";
		last;
	}
}

print_progress();
save_results();

# ======= end main

sub test_match {
	my ($name) = @_;
	if ($name =~ /$page_regex/i) {
		print encode_utf8("Matched $name: sort key is '$1'\n");
	} else {
		print encode_utf8("Did not match $name\n");
	}
}

sub print_progress {
	my ($sec,$min,$hour) = localtime();
	printf '%02d:%02d %d/%d', $hour, $min, $processed_pages, $pages_count;
	printf colored(' %2.0f%%', 'green'), 100*$processed_pages/$pages_count;
	print " fixed $fixed_count\n";
}

sub save_results {
	save_hash_sorted($donefile, \%done);
}

=head1 NAME

sort_commons_cat - adds sort key to audio files on Commons

=head1 SYNOPSIS

 plnews_month.pl [options]

 Options:
   -c --category <cat>    read pages from category, for example 'German pronunciation' (required)
   -u --user <user>       read pages from recent user contributions, for example 'JohnDoe'
   -l --lang <lang>       language code like 'de' used to create the regular expression (optional)
   -r --regex <regex>     regular expression used to match file names and get sort key
                          defaults to "File:$lang_code".'[- ]([^.]+)\.og[ag]'
      --limit <limit>     edit at most <limit> pages, then finish
      --pages-limit <l>   fetch at most <l> pages from server
   -p --pause <pause>     pause for <pause> seconds before fetching each page
                          defaults to 2
      --no-cache          skip cache when fetching the list pages from server
      --clean             forget what was done before
                          needed if you change category since last run
      --dry-run[=exmpl]   do not make any modifications, just print what will be edited
                          if the example is provided, a match against the regular expression will be tried

   -v --verbose           print diagnostic messages
   -d --debug             print diagnostic messages for MediaWiki bot
   -h --help              show full help and exit

=head1 EXAMPLE

 ./sort_commmons_cat.pl -c 'German pronunciation' -l 'de' --pause 4
 ./sort_commmons_cat.pl -c 'English pronunciation' -r 'File:En-ca[- ]([^.]+)\.og[ag]' --dry-run='File:En-ca-cat.ogg'

=head1 AUTHOR

Derbeth <https://github.com/Derbeth>

=cut
