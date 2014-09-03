#!/usr/bin/perl -w

use strict;
use utf8;

use MediaWiki::Bot 3.3.1;
use Getopt::Long;
use Pod::Usage;
use Encode;

use Derbeth::Util;

my $wiki = 'pl.wikinews.org';
my $clear = 0;
my $max_changed = undef;
my $show_help=0;

GetOptions(
	'clear|c' => \$clear,
	'limit|l=i' => \$max_changed,
	'wiki|w=s' => \$wiki,
	'help|h' => \$show_help,
) or pod2usage('-verbose'=>1,'-exitval'=>1);
pod2usage('-verbose'=>2,'-noperldoc'=>1) if ($show_help);
pod2usage('-verbose'=>1,'-noperldoc'=>1, '-msg'=>'2 args required') if ($#ARGV != 1);

my ($from_category, $to_category) = @ARGV;

my $donefile = 'done/category_fixer.txt';

mkdir 'done' unless(-e 'done');
unline $donefile if $clear;
my %done;
read_hash_loose($donefile, \%done);

$SIG{INT} = $SIG{TERM} = $SIG{QUIT} = sub { save_results(); exit; };

# ======= main

my %settings = load_hash('settings.ini');
my $editor = MediaWiki::Bot->new({
	host => $wiki,
	protocol => 'https',
	login_data => {'username' => $settings{bot_login}, 'password' => $settings{bot_password}},
	operator => $settings{bot_operator},
	assert => 'bot',
});
die unless $editor;

assure_category_exists($from_category);
assure_category_exists($to_category);

my @pages = $editor->get_pages_in_category("Category:$from_category", {max=>0});
print scalar(@pages), " pages to fix\n";
my $visited = 0;
my $changed = 0;
foreach my $page (sort @pages) {
	++$visited;
	print "$visited/",scalar(@pages)," visited\n" if ($visited % 50 == 0);
	
	next if $done{$page};
	my $text = $editor->get_text($page);
	unless ($text) {
		$done{$page} = 'no_text';
		next;
	}
	unless ($text =~ s/Kategoria:$from_category\b/Kategoria:$to_category/g) {
		$done{$page} = 'nothing_to_change';
		next;
	}
	my $saved = $editor->edit({
		page => $page,
		text => $text,
		summary => "Zmiana kategorii z $from_category na $to_category",
		minor => 1,
		bot => 1,
	});
	if (!defined($saved)) {
		print encode_utf8("Cannot edit page '$page': $editor->{error}->{details} ($editor->{error}->{code})\n");
		last;
	}
	$done{$page} = 'fixed';
	++$changed;
	if (defined($max_changed) && $changed >= $max_changed) {
		print "Limit of edited pages ($max_changed) reached\n";
		last;
	}
	sleep 1;
}
print "Visited $visited/",scalar(@pages),", changed $changed\n";
save_results();

# ======= end main

sub save_results {
	save_hash_sorted($donefile, \%done);
}

sub assure_category_exists {
	my ($cat_name) = @_;
	unless (defined($editor->get_id("Category:$cat_name"))) {
		die "No category '$cat_name' in wiki $wiki";
	}
}

=head1 NAME

category-fixer.pl - moves pages between categories

=head1 SYNOPSIS

 category-fixer.pl <from category> <to category>

 Options:
   -l --limit <limit>   maximal number of edited pages
   -w --wiki  <page>    wiki to use, defaults to 'pl.wikinews.org'
   -c --clear           forget state of 'done' work

   -h --help            show full help and exit

=head1 EXAMPLE

 ./category-fixer.pl -w pl.wikinews.org --limit 3 Technologia Technika

=head1 AUTHOR

Derbeth

=cut
