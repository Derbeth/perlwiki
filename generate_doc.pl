#!/usr/bin/perl -w

use strict;

# my @libs=qw/Util Web Wikitools Wiktionary/;
# 
# foreach my $lib (@libs) {
# 	`pod2html --infile=Derbeth/$lib.pm --outfile=doc/$lib.html`;
# }
# 
# `rm -f pod2html*`;

exec("~/bin/NaturalDocs/NaturalDocs -i Derbeth -o HTML doc/NaturalDocs -p doc/project --documented-only --charset UTF-8");
