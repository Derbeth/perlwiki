#!/usr/bin/perl -w

use strict;
use utf8;

use MediaWiki::Bot 3.3.1;
use Getopt::Long;
use Pod::Usage;
use Encode;

use Derbeth::Util;

my $dry_run=0;
my $show_help=0;
my $is_bot=1;
my $nonbot_sleep=15;
GetOptions(
	'dry-run|d' => \$dry_run,
	'help|h' => \$show_help,
) or pod2usage('-verbose'=>1,'-exitval'=>1);
pod2usage('-verbose'=>2,'-noperldoc'=>1) if ($show_help);
pod2usage('-verbose'=>1,'-noperldoc'=>1, '-msg'=>'5 args required') if ($#ARGV != 4);

my ($year,$month_no,$month,$month_decl,$days) = map { decode_utf8($_) } @ARGV;

$month = ucfirst($month);
$month_decl = lcfirst($month_decl);

die "suspicious year: $year" unless ($year >= 1990 && $year <= 2200);
die "suspicious month number: $month_no" unless ($month_no >= 1 && $month_no <= 12);
die "suspicious name: '$month'" unless (is_text_name($month));
die "suspicious name: '$month_decl'" unless (is_text_name($month_decl));
die "incorrect month name; plain name: '$month' declined name: '$month_decl'" unless (names_similar($month,$month_decl));
die "suspicious days number: $days" unless ($days >= 28 && $days <= 31);

my %settings = load_hash('settings.ini');
my $editor = MediaWiki::Bot->new({
	host => 'pl.wikinews.org',
	protocol => 'https',
	login_data => {'username' => $settings{bot_login}, 'password' => $settings{bot_password}},
	operator => $settings{bot_operator},
	assert => 'bot',
});
die unless $editor;

my $edit_summary = "Autom. tworzenie struktury stron dla miesiąca: $month $year";

my $month_portal_text = "{{MiesiącBegin|$month_no|$year}}\n";
for my $day (1..$days) {
	$month_portal_text .= <<END;
==$day $month_decl $year==
<DynamicPageList>
category=$day $month_decl $year
namespace=0
suppresserrors=true
</DynamicPageList>
END
}
$month_portal_text .= "{{MiesiącEnd|$month_no|$year}}";

create_page_if_needed("Kategoria:$month $year", "[[Kategoria:$year]]");
for my $day (1..$days) {
	create_page_if_needed("Kategoria:$day $month_decl $year", "[[Kategoria:$month $year]]");
}
create_page_if_needed("Portal:$month $year", $month_portal_text);

sub is_text_name {
	my ($name) = @_;
	$name =~ /[a-z]/;
}

sub significant_name_part {
	my ($name) = @_;
	substr(lc($name), 0, 1);
}

sub names_similar {
	my ($name1, $name2) = @_;
	significant_name_part($name1) eq significant_name_part($name2);
}

sub create_page_if_needed {
	my ($page_name, $page_text) = @_;
	my $current_text = $editor->get_text($page_name);
	if (defined($current_text)) {
		print encode_utf8("Page '$page_name' exists, skipping\n");
		return;
	}
	if ($dry_run) {
		print encode_utf8("Would create page '$page_name', summary '$edit_summary'\n>>>>\n$page_text\n<<<<\n");
	} else {
		my $result = $editor->edit({
			page => $page_name,
			text => $page_text,
			summary => $edit_summary,
			minor => 1,
			bot => $is_bot,
		});
		if (!defined($result)) {
			print encode_utf8("Cannot edit page '$page_name': $editor->{error}->{details} ($editor->{error}->{code})\n");
			die;
		}
		print encode_utf8("Created page '$page_name'\n");
		sleep $nonbot_sleep unless ($is_bot);
	}
}

=head1 NAME

plnews_month - generates new month for Polish Wikinews

=head1 SYNOPSIS

 plnews_month.pl <year> <month number> <month name> <month declined> <no of days> [options]

 Options:
   -d --dry-run         do not make any modifications, just print what will be edited

   -h --help            show full help and exit

=head1 EXAMPLE

 plnews_month.pl 2013 2 luty lutego 28

=head1 AUTHOR

Derbeth

=cut

