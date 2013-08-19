# MIT License
#
# Copyright (c) 2013 Derbeth
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

package Derbeth::Cache;
require Exporter;

use strict;

use Digest::MD5 'md5_hex';
use Encode;

our @ISA = qw/Exporter/;
our @EXPORT = qw/cache_read cache_read_values cache_write cache_write_values/;
our $VERSION = 0.1.0;
use vars qw($cache_dir $MAX_FILES_IN_CACHE);

# Variable: $cache_dir
#   name of directory holding cache
$cache_dir = 'page-cache';
# Variable: $MAX_FILES_IN_CACHE
#   maximal number of cached pages
$MAX_FILES_IN_CACHE=15000;

_create_cache();

# Function: clear_cache
#   removes cache dir and recreates it
sub clear_cache {
	system("rm -r $cache_dir");
	_create_cache();
}

sub _create_cache {
	unless (-e $cache_dir) {
		mkdir($cache_dir) or die "need to have directory '$cache_dir' but cannot create it";
		print "created cache dir $cache_dir/\n";
	}
}

sub _check_can_cache {
	die "cache full" unless can_cache();
}

sub can_cache {
	my $dir;
	opendir($dir,$cache_dir) or return 0;
	my @files = readdir $dir or return 0;
	my $space_left = ( $#files < $MAX_FILES_IN_CACHE );
	print "cache full\n" unless $space_left;
	return $space_left;
}

sub _cache_file {
	my ($key) = @_;
	return $cache_dir . '/' . md5_hex(encode_utf8($key));
}

sub cache_read {
	my ($key) = @_;
	my $filename = _cache_file($key);
	return undef unless (-e $filename);
	open(IN,$filename) or die "cannot open file $filename";
	my $text='';
	while(my $c=<IN>) { $text .= $c; }
	close(IN);
	return decode_utf8($text);
}

sub cache_read_values {
	my ($key) = @_;
	my $filename = _cache_file($key);
	return undef unless (-e $filename);
	open(IN,$filename) or die "cannot open file $filename";
	my @result;
	while(my $c=<IN>) {
		chomp $c;
		push @result, decode_utf8($c)
	}
	close(IN);
	if ($#result == 0 && $result[0] eq '') {
		@result = ();
	}
	return \@result;
}

sub cache_write {
	my ($key, $text) = @_;
	my $filename = _cache_file($key);
	open(OUT,'>',$filename) or die "cannot write to file $filename";
	print OUT encode_utf8($text);
	close OUT;
}

sub cache_write_values {
	my ($key, $values_ref) = @_;
	cache_write($key, join("\n", @{$values_ref}) . "\n");
}

1;
