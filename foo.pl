#!/usr/bin/perl

use strict;
use utf8;
use Encode;
use Derbeth::Wikitools;
use Derbeth::Wiktionary;
use Derbeth::Util;
use Derbeth::Web;
use Perlwikipedia;
use Getopt::Long;

my %settings = load_hash('settings.ini');
my $user = $settings{bot_login}; # for wiki
my $pass = $settings{bot_password};   # for wiki

print "$user - $pass\n";

# while(<>) {
# 	/^# \[\[(.+?)\]\] >/;
# 	print "$1=unknown\n";
# }