#!/usr/bin/perl

use strict;
use utf8;
use Encode;
use Derbeth::Wikitools;
use Derbeth::Wiktionary;
use Derbeth::Util;
use Derbeth::Web;
use MediaWiki::Bot;
use Getopt::Long;

my $donefile='done/done_audio_de.txt';
my %done;
read_hash_loose($donefile, \%done);

my %settings = load_hash('settings.ini');
my $user = $settings{bot_login};
my $pass = $settings{bot_password};
my $editor = MediaWiki::Bot->new($user);
$editor->set_wiki('commons.wikimedia.org', 'w');
$editor->login($user, $pass);

my @pages = $editor->get_pages_in_category('Category:British English pronunciation');

print scalar(@pages), " pages\n";

foreach my $page (@pages) {
	$page =~ /En-uk-([^.]+)\.ogg/ or next;
	$page = $1;
	if (exists $done{"en-$page"}) {
		#print "will delete $page from done\n";
		delete $done{"en-$page"};
	}
}


save_hash_sorted($donefile, \%done);

