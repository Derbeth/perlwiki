# Package: Derbeth::Web
#   low-level functions for retrieving pages from server.
#
# Initialization:
#   when loaded, this package creates subdirectory <$cache_dir> under directory
#   where it was called
package Derbeth::Web;
require Exporter;

use strict;

use LWP;
use Carp;
use Digest::MD5 'md5_hex';
use Encode;
use File::Path qw(make_path remove_tree);
use HTML::Form;

our @ISA = qw/Exporter/;
our @EXPORT = qw/get_page/;
our $VERSION = 0.6.0;
use vars qw($user_agent $cache_pages $max_files_in_cache $debug $cache_dir);

# Variable: $cache_dir
#   name of directory holding cache
$cache_dir = 'page-cache';
# Variable: $max_files_in_cache
#   maximal number of cached pages
$max_files_in_cache=15000;
$debug=0;
# Variable: $user_agent
#   user agent passed to server when retrieving pages
$user_agent = 'DerbethBot for Wiktionary';
my $proxy='';

$cache_pages=0;

_create_cache();

# Function: clear_cache
#   removes cache dir and recreates it
sub clear_cache {
	remove_tree($cache_dir);
	_create_cache();
}

sub _create_cache {
	unless (-e $cache_dir) {
		mkdir($cache_dir) or die "need to have directory '$cache_dir' but cannot create it";
		print "created cache dir $cache_dir/\n";
	}
}

# Function: get_page_from_web
# Parameters:
#   $full_url - 'http://localhost/~piotr/enwikt/Main page'
sub get_page_from_web {
	my $full_url=shift @_;
	$full_url = encode_utf8($full_url);
	if ($debug) {
		print "getting from web: $full_url";
		print " using proxy $proxy" if ($proxy);
		print "\n";
	}
	my $ua = LWP::UserAgent->new;
	$ua->agent($user_agent);
	$ua->proxy('http', $proxy) if ($proxy);
	$ua->timeout(90); # 1.5 minute
	my $response = $ua->get($full_url);
	if ($response->is_success) {
		return decode_utf8($response->content);
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
	opendir($dir,$cache_dir) or return 0;
	my @files = grep { !/^\./ } readdir($dir);
	my $space_left = ( scalar(@files) < $max_files_in_cache );
	print "cache full\n" unless $space_left;
	return $space_left;
}

sub get_page_from_cache {
	my ($full_url,$recache)=@_;

	if (can_cache()) {
		my $base_name = md5_hex(encode_utf8($full_url));
		my $filename=$cache_dir.'/'.$base_name;

		if( -e $filename && !$recache) {
			print "reading cache for ", encode_utf8($full_url);
			print " from $base_name" if($debug);
			print "\n";
			return get_page_from_file($filename);
		} else {
			my $text = get_page_from_web($full_url);
			# do not cache if fetching failed
			if ($text) {
# 				print "writing from ", encode_utf8($full_url), " to cache $filename\n" if $debug;
				save_page_to_file($text, $filename);
			} else {
# 				print "will not write to cache because got empty text\n"; #DEBUG
			}
			return $text;
      	}
	} else {
		return get_page_from_web($full_url);
	}
}

sub get_page_from_file {
   my $file = shift @_;
   my $text = '';
   open(IN,$file) or die "cannot open file $file: $!";
   my @lines = <IN>;
   close(IN);
   return decode_utf8(join('', @lines));
}

sub save_page_to_file {
   my $text = \shift @_;
   my $file = shift @_;

   open(OUT,'>',$file) or die "cannot write to file $file";
   print OUT encode_utf8($$text);
   close(OUT);
}

sub purge_page {
	my ($url, $base_uri) = @_;
	my $page = get_page_from_web($url.'&action=purge');
	my $ua = LWP::UserAgent->new;
	my @forms = HTML::Form->parse($page, $base_uri);
	@forms = grep $_->attr("class") && $_->attr("class") eq "visualClear", @forms;
	my $form = shift @forms;
	unless($form) {
		print "No purge form ", scalar(localtime()), "\n" if $debug;
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
