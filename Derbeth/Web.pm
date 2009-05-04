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

package Derbeth::Web;
require Exporter;

use strict;

use LWP;
use Digest::MD5 'md5_hex';
use Encode;
use URI::Escape qw/uri_escape_utf8/;

our @ISA = qw/Exporter/;
our @EXPORT = qw/get_page/;
our $VERSION = 0.3.0;

my $CACHE_DIR = 'page-cache';
my $MAX_FILES_IN_CACHE=3000;
my $user_agent = 'Opera/10.00 (X11; Linux i686; U; pl) Presto/2.2.1';

my $cache_pages=0;

_create_cache();

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

# Parameters:
#   $full_url - 'http://localhost/~piotr/enwikt/Main page'
sub get_page_from_web {
	my $full_url=shift @_;
	$full_url = encode_utf8($full_url);
	my $ua = LWP::UserAgent->new;
	$ua->agent($user_agent);
	my $text = $ua->get($full_url)->content;
	return $text;
}

# Parameters:
#   $full_url - 'http://localhost/~piotr/enwikt/Main page'
sub get_page {
	my $full_url=shift;
	$full_url = encode_utf8($full_url);
	#$full_url = uri_escape_utf8($full_url);
	if ($cache_pages) {
		return get_page_from_cache($full_url);
	} else {
		return get_page_from_web($full_url);
	}
}


sub enable_caching {
	$cache_pages = shift @_;
}

sub can_cache {
	if( !$cache_pages ) { return 0; }
	my $dir;
	opendir($dir,$CACHE_DIR) or return 0;
	my @files = readdir $dir or return 0;
	return( $#files < $MAX_FILES_IN_CACHE );
}

sub get_page_from_cache {
	my $full_url=shift @_;
	
	if (can_cache()) {
		my $filename=$CACHE_DIR.'/'.md5_hex($full_url);
		
		if( -e $filename ) {
			#print "reading cache\n"; #DEBUG
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
   return $text;
}

sub save_page_to_file {
   my $text = \shift @_;
   my $file = shift @_;
   
   open(OUT,'>',$file) or die "cannot write to file $file";
   print OUT $$text;
}

1;