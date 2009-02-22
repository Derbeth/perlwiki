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

package Derbeth::Util;
require Exporter;

use strict;

use Encode;
use File::Temp qw/tempfile/;
use File::Copy;

our @ISA = qw/Exporter/;
our @EXPORT = qw/read_hash_loose
	read_hash_strict
	load_hash
	save_hash
	save_hash_sorted
	text_from_file
	add_audio_count
	escape_regex
	appendfile/;
our $VERSION = 0.3.2;

# Reads hash from file.
# Accepts lines:
#   key=val
#   key (treated as key=1)
sub read_hash_loose {
	my ($filename, $hash_ref) = @_;
	
	open(IN,$filename) or return;
	while(<IN>) {
		chomp;
		$_ = decode_utf8($_);
		my ($key,$val) = split /=/, $_;
		$val = 1 unless (defined($val));
		$hash_ref->{$key} = $val;
	}
	close(IN);
}

# Reads hash from file.
# Accepts lines:
#   key=val (only this)
sub read_hash_strict {
	my ($filename, $hash_ref) = @_;
	
	open(IN,$filename) or return;
	while(<IN>) {
		chomp;
		$_ = decode_utf8($_);
		if (/([^=]+)=(.+)/) {
			$hash_ref->{$1} = $2;
		}
	}
	close(IN);
}

sub load_hash {
	my ($filename) = @_;
	my %retval;
	
	read_hash_loose($filename, \%retval);
	return %retval;
}

sub save_hash {
	my ($filename, $hash_ref, $sort) = @_;
	
	my ($fh,$tempfile_name)=tempfile();
	
	my @keys = $sort ? sort(keys(%$hash_ref)) : keys(%$hash_ref);
	foreach my $key (@keys) {
		my $val = $$hash_ref{$key};
		print $fh encode_utf8($key.'='.$val),"\n";
	}
	close($fh);
	move($tempfile_name, $filename);
}

sub save_hash_sorted {
	my ($filename, $hash_ref) = @_;
	save_hash($filename, $hash_ref, 1);
}

sub text_from_file {
	my ($filename) = @_;
	my $retval = '';
	open(IN,$filename);
	while(<IN>) {
		$retval .= $_;
	}
	close(IN);
	$retval = decode_utf8($retval);
	return $retval;
}

sub add_audio_count {
	my ($countfile, $lang_code, $added_files) = @_;
	my %count;
	open(COUNT, $countfile);
	while(<COUNT>) {
		if (/^(\w+)=(\d+)/) {
			$count{$1} = $2;
		}
	}
	close(COUNT);
	if (exists($count{$lang_code})) {
		$count{$lang_code} += $added_files;
	} else {
		$count{$lang_code} = $added_files;
	}
	open(COUNT, '>count_temp.txt');
	while (my ($lang,$c) = each(%count)) {
		print COUNT "$lang=$c\n";
	}
	close(COUNT);
	`mv count_temp.txt $countfile`;
}

sub escape_regex {
	my ($text) = @_;
	$text =~ s/([{[\]|()])/\\$1/g;
	return $text;
}

sub appendfile {
	my ($filename, @texts) = @_;
	
	open(OUT, ">>$filename");
	foreach my $text (@texts) {
		print OUT encode_utf8($text);
	}
	close(OUT);
}

1;
