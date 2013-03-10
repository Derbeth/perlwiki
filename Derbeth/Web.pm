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

# Package: Derbeth::Web
#   low-level functions for retrieving pages from server.
#
# Initialization:
#   when loaded, this package creates subdirectory <$CACHE_DIR> under directory
#   where it was called
package Derbeth::Web;
require Exporter;

use strict;

use LWP;
use Carp;
use Digest::MD5 'md5_hex';
use Encode;
use URI::Escape qw/uri_escape_utf8/;

our @ISA = qw/Exporter/;
our @EXPORT = qw/get_page/;
our $VERSION = 0.5.0;
use vars qw($user_agent $cache_pages $MAX_FILES_IN_CACHE $DEBUG);

# Variable: $CACHE_DIR
#   name of directory holding cache
my $CACHE_DIR = 'page-cache';
# Variable: $MAX_FILES_IN_CACHE
#   maximal number of cached pages
$MAX_FILES_IN_CACHE=15000;
$DEBUG=0;
# Variable: $user_agent
#   user agent passed to server when retrieving pages
$user_agent = 'DerbethBot for Wiktionary';
my $proxy='';

$cache_pages=0;

_create_cache();

# Function: clear_cache
#   removes cache dir and recreates it
sub clear_cache {
	`rm -r $CACHE_DIR`;
	_create_cache();
}

sub _create_cache {
	unless (-e $CACHE_DIR) {
		mkdir($CACHE_DIR) or die "need to have directory '$CACHE_DIR' but cannot create it";
		print "created cache dir $CACHE_DIR/\n";
	}
}

# Function: get_page_from_web
# Parameters:
#   $full_url - 'http://localhost/~piotr/enwikt/Main page'
sub get_page_from_web {
	my $full_url=shift @_;
	$full_url = encode_utf8($full_url);
	print "getting from web: $full_url";
	print " using proxy $proxy" if ($proxy);
	print "\n";
	my $ua = LWP::UserAgent->new;
	$ua->agent($user_agent);
	$ua->proxy('http', $proxy) if ($proxy);
	$ua->timeout(90); # 1.5 minute
	my $response = $ua->get($full_url);
	if ($response->is_success) {
		return $response->content;
	} else {
		print encode_utf8("error getting $full_url: "),$response->content,"\n";
		return '';
	}
}

# Function: get_page
# Parameters:
#   $full_url - 'http://localhost/~piotr/enwikt/Main page'
#   $recache  - if true, URL is retrieved without using cache and then written to cache
sub get_page {
	my ($full_url,$recache)=@_;
# 	$full_url = encode_utf8($full_url);
# 	$full_url = uri_escape_utf8($full_url);
	if ($cache_pages) {
		return get_page_from_cache($full_url,$recache);
	} else {
		return get_page_from_web($full_url);
	}
}

sub enable_caching {
	croak "expects an argument" if ($#_ == -1);
	$cache_pages = shift @_;
}

# $proxy - either 'http://foo.bar:8080' or empty string (to disable)
sub use_proxy {
	$proxy = shift @_;
}

sub can_cache {
	if( !$cache_pages ) { return 0; }
	my $dir;
	opendir($dir,$CACHE_DIR) or return 0;
	my @files = readdir $dir or return 0;
	my $space_left = ( $#files < $MAX_FILES_IN_CACHE );
	print "cache full\n" unless $space_left;
	return $space_left;
}

sub get_page_from_cache {
	my ($full_url,$recache)=@_;

	if (can_cache()) {
		my $filename=$CACHE_DIR.'/'.md5_hex(encode_utf8($full_url));

		if( -e $filename && !$recache) {
			print "reading cache for ", encode_utf8($full_url);
			#print " from $filename\n"; #DEBUG
			print "\n";
			return get_page_from_file($filename);
		} else {
			my $text = get_page_from_web($full_url);
			#print "writing to cache\n"; #DEBUG
			save_page_to_file($text, $filename);
			return $text;
      	}
	} else {
		return get_page_from_web($full_url);
	}
}

sub get_page_from_file {
   my $file = shift @_;
   #print "tryb offline\n";
   my $text = '';
   open(IN,$file) or die "cannot open file $file";
   while(my $c=<IN>) { $text .= $c; }
   #if ($text eq '') { print STDERR "warning: no content\n"; }
   return decode_utf8($text);
}

sub save_page_to_file {
   my $text = \shift @_;
   my $file = shift @_;

   open(OUT,'>',$file) or die "cannot write to file $file";
   print OUT $$text;
}

sub purge_page {
	my ($url) = @_;
	my $page = get_page_from_web($url.'&action=purge');
	my $ua = LWP::UserAgent->new;
	my @forms = HTML::Form->parse($page, $Settings::LINK_PREFIX);
	@forms = grep $_->attr("class") && $_->attr("class") eq "visualClear", @forms;
	my $form = shift @forms;
	unless($form) {
		print "No purge form ", scalar(localtime()), "\n" if $DEBUG;
		return;
	}
#     $form->dump();
	my $request = $form->click();
#     print "REQUEST:\n", $request->as_string();
	my $response = $ua->request($request);
	if( $response->is_error ) {
		print "Error purging: ", $response->status_line(), ' ', scalar(localtime()), "\n";
	}
}

1;
