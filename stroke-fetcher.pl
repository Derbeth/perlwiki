#!/usr/bin/perl -w

use strict;
use English;
use utf8;
use lib '.';

use Derbeth::Wikitools;
use Derbeth::Commons;
use Encode;
use Getopt::Long;

my $refresh;

GetOptions(
	'r|refresh!' => \$refresh,
	'v|verbose!' => \$Derbeth::Commons::verbose,
) or die;

my %blacklist;
foreach my $key (qw//) {
	$blacklist{$key} = 1;
}

my %categories = (
	bw => {
		include => ['Bw.png stroke order images'],
		exclude => [
			'Disputed diagrams',
			'Abw.png stroke order images',
			'Hbw.png stroke order images',
			'Jbw.png stroke order images',
			'Tbw.png stroke order images',
		],
	},
	animate => {
		include => ['Order.gif stroke order images'],
		exclude => [
			'Disputed diagrams',
			'Aorder.gif stroke order images',
			'Horder.gif stroke order images',
			'Iorder.gif stroke order images',
			'Jorder.gif stroke order images',
			'Torder.gif stroke order images',
			'Vorder.gif stroke order images',
			'Cursive-order.gif stroke order images',
			'AnimationRequest',
		]
	},
	red => {
		include => ['Red.png stroke order images'],
		exclude => [
			'Disputed diagrams',
			'Ared.png stroke order images',
			'Ired.png stroke order images',
			'Jred.png stroke order images',
			'Tred.png stroke order images',
		]
	},
	tbw => {
		include => ['Tbw.png stroke order images'],
		exclude => ['Disputed  diagrams'],
	},
	hbw => {
		include => ['Hbw.png stroke order images'],
		exclude => ['Disputed diagrams'],
	},
	jbw => {
		include => ['Jbw.png stroke order images'],
		exclude => ['Disputed diagrams'],
	},
	tanimate => {
		include => ['Torder.gif stroke order images'],
		exclude => [
			'Disputed diagrams',
			'AnimationRequest',
		]
	},
	hanimate => {
		include => ['Horder.gif stroke order images'],
		exclude => [
			'Disputed diagrams',
			'AnimationRequest',
		]
	},
	cursive => {
		include => ['Cursive-order.gif stroke order images'],
		exclude => [
			'Disputed diagrams',
			'AnimationRequest',
		]
	},
	janimate => {
		include => ['Jorder.gif stroke order images'],
		exclude => [
			'Disputed diagrams',
			'AnimationRequest',
		]
	},
);

Derbeth::Web::enable_caching(1);

my $editor = Derbeth::Wikitools::create_editor('http://commons.wikimedia.org/w/');

my %by_type = ();
foreach my $type (sort keys %categories) {
	my @pages = Derbeth::Wikitools::get_contents_include_exclude($editor,
		$categories{$type}->{include},
		$categories{$type}->{exclude},
		[],
		{file=>1},
		$refresh);
	print "$type: ", scalar(@pages), " pages\n";
	@pages = map { s/^File://; $_ } @pages;
	@pages = grep { !exists $blacklist{$_} } @pages;
	@pages = grep { $_ !~ /-j$type/ } @pages; # for some reason exclusion does not work
	$by_type{$type} = \@pages;
}

my %signs;
foreach my $type (qw/bw animate red tbw hbw jbw tanimate hanimate cursive janimate/) {
	foreach my $file (@{$by_type{$type}}) {
		if ($file !~ /^([^-]+)-/) {
			print encode_utf8("Unexpected file: $file\n");
			next;
		}
		my $sign = $1;
		$signs{$sign} ||= $type."<$file>";
# 		push @{$signs{$sign}}, $file;
	}
}

open(OUT, '>audio/stroke.txt');
foreach my $sign (sort keys %signs) {
	print OUT encode_utf8("$sign=" . $signs{$sign}), "\n";
# 	print OUT encode_utf8("$sign=" . join('|', @{$signs{$sign}})), "\n";
}
close(OUT);
