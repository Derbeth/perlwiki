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
our $VERSION = 0.4.1;

# Function: read_hash_loose
#   reads hash from file.
# 
# Accepts lines:
#   key=val
#   key (treated as key=1)
#
# Parameters:
#   $filename - filename
#   $hash_ref - reference to hash
#
# Returns:
#   1 on success, 0 on failure
sub read_hash_loose {
	my ($filename, $hash_ref) = @_;
	
	open(IN,$filename) or return 0;
	while(<IN>) {
		next unless(/\S/);
		next if (/^#/);
		chomp;
		$_ = decode_utf8($_);
		my ($key,$val) = split /=/, $_;
		$val = 1 unless (defined($val));
		$hash_ref->{$key} = $val;
	}
	close(IN);
	return 1;
}

# Function: read_hash_strict
#   reads hash from file.
#
# Accepts lines:
#   key=val (only this)
# 
# Parameters:
#   $filename - filename
#   $hash_ref - reference to hash
#
# Returns:
#   1 on success, 0 on failure
sub read_hash_strict {
	my ($filename, $hash_ref) = @_;
	
	open(IN,$filename) or return 0;
	while(<IN>) {
		next unless(/\S/);
		chomp;
		$_ = decode_utf8($_);
		if (/([^=]+)=(.+)/) {
			$hash_ref->{$1} = $2;
		}
	}
	close(IN);
	return 1;
}

# Function: load_hash
# loads hash and returns it
#
# Parameters:
#   $filename - filename
sub load_hash {
	my ($filename) = @_;
	my %retval;
	
	read_hash_loose($filename, \%retval);
	return %retval;
}

# Function: save_hash
# Parameters:
#   $filename - filename
#   $hash_ref - reference to hash
#   $sort - whether to sort keys
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

# Function: save_hash_sorted
# Parameters:
#   $filename - filename to save to
#   $hash_ref - reference to hash
sub save_hash_sorted {
	my ($filename, $hash_ref) = @_;
	save_hash($filename, $hash_ref, 1);
}

# Function: text_from_file
# returns text read from file
# 
# Parameters:
#   $filename - filename
sub text_from_file {
	my ($filename) = @_;
	my $retval = '';
	open(IN,$filename) or die "cannot read $filename";
	while(<IN>) {
		$retval .= $_;
	}
	close(IN);
	$retval = decode_utf8($retval);
	return $retval;
}

# Function: add_audio_count
# Parameters:
#   $countfile - file with audio count
#   $lang_code - code of language to add to
#   $added_files - number of added files
sub add_audio_count {
	my ($countfile, $lang_code, $added_files) = @_;
	my %count;
	if (open(COUNT, $countfile)) {
		while(<COUNT>) {
			if (/^(\w+)=(\d+)/) {
				$count{$1} = $2;
			}
		}
		close(COUNT);
	}
	if (exists($count{$lang_code})) {
		$count{$lang_code} += $added_files;
	} else {
		$count{$lang_code} = $added_files;
	}
	my ($handle,$filename) = tempfile();
	save_hash_sorted($filename, \%count);
	move($filename,$countfile);
}

# Function: escape_regex
# Parameters:
#   $text - text to escape
sub escape_regex {
	my ($text) = @_;
	$text =~ s/([{[\]|()])/\\$1/g;
	return $text;
}

# Function: appendfile
# Parameters:
#   $filename - filename to append to
#   @texts - list of text to append to
sub appendfile {
	my ($filename, @texts) = @_;
	
	open(OUT, ">>$filename");
	foreach my $text (@texts) {
		print OUT encode_utf8($text);
	}
	close(OUT);
}

1;

__END__

