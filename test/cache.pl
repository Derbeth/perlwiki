#!/usr/bin/perl -w

use strict;
use utf8;
use lib '.';

use Derbeth::Cache;

use File::Path qw(make_path remove_tree);
use Test::Assert ':all';
use Encode;

# === Running

_set_up();
test_caching();
_set_up();
test_caching_many_values();
print "Passed\n";

# === Tests

sub _set_up {
	my $temp_cache_dir = '/tmp/derbeth-web-test-page-cache';
	$Derbeth::Cache::cache_dir = $temp_cache_dir;
	remove_tree $temp_cache_dir;
	make_path $temp_cache_dir;
}

sub test_caching {
	assert_false (cache_read('non-existent'));
	
	cache_write('key1', 'first key');
	cache_write('key2', 'second key');
	my $unicode_str = "bździągwa\nnowa linia\n";
	cache_write('unicode', $unicode_str);
	
	assert_equals 'first key', cache_read('key1');
	assert_not_equals cache_read('key1'), cache_read('key2');
	assert_equals $unicode_str, cache_read('unicode');
}

sub test_caching_many_values {
	assert_false cache_read_values('non-existent');
	
	cache_write_values('empty', []);
	cache_write_values('one', ['singular']);
	cache_write_values('unicode', ['bździągwa', 'łotr']);
	
	assert_deep_equals([], cache_read_values('empty'));
	assert_deep_equals(['singular'], cache_read_values('one'));
	assert_deep_equals(['bździągwa', 'łotr'], cache_read_values('unicode'));
}
