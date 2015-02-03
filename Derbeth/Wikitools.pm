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

package Derbeth::Wikitools;
require Exporter;

use strict;
use utf8;

use Carp;
use Encode;
use Derbeth::Cache;
use Derbeth::Web;
use Derbeth::Util;
use Derbeth::I18n 0.5.2;
use MediaWiki::Bot;
use HTML::Entities;
use URI::Escape qw/uri_escape_utf8/;

our @ISA = qw/Exporter/;
our @EXPORT = qw/split_before_sections
	split_article_wikt
	split_article_dewikt
	split_article_enwikt
	split_article_plwikt
	get_category_contents
	extract_page_contents
	get_linking_to
	get_wikicode/;
our $VERSION = 0.9.2;

# Variable: $use_perlwikipedia
our $use_perlwikipedia=0;

# Function: split_before_sections
# Parameters:
#  $article_text - article text
#
# Returns:
#   ($before,$rest) - text before first of sections and rest
#   ('',$rest) - if not text before sections
sub split_before_sections {
	my $article_text=shift @_;
	my $point = index($article_text,'==');
	if ($point == -1) {
		return('',$article_text);
	}
	#my @parts = split /(==)/, $article_text, 2;
	#return @parts;
	return(substr($article_text,0,$point),substr($article_text,$point));
}

# Function: split_article_wikt
# Parameters:
#   $wikt_lang - only 'de', 'en', 'pl' or 'simple', other Wiktionaries are not
#                supported
#  $lang_code - 'en', 'de', 'hsb' (no regional part, no 'en-uk'!)
#  $article_text - full article text
#  $vercheck - as v0.8 breaks backward compatibility, this flag will be used untill all code is changed
#
# Returns:
#  ($before,$lang_section,$after)
#  if no lang section exists: ($article_text, '', '')
sub split_article_wikt {
	my ($wikt_lang, $lang_code, $article_text, $vercheck) = @_;
	croak "version 0.8 breaks backward compatibility" unless($vercheck);
	
	if ($wikt_lang eq 'de') {
		return split_article_dewikt($lang_code, $article_text);
	} elsif ($wikt_lang eq 'en') {
		return split_article_enwikt($lang_code, $article_text);
	} elsif ($wikt_lang eq 'pl') {
		return split_article_plwikt($lang_code, $article_text);
	} elsif ($wikt_lang eq 'simple') {
		return split_article_simplewikt($lang_code, $article_text);
	} elsif ($wikt_lang eq 'fr') {
		return split_article_frwikt($lang_code, $article_text);
	} else {
		croak "Wiktionary $wikt_lang not supported";
	}
}

sub split_article_simplewikt {
	my ($lang, $article_text) = @_;
	return ('',$article_text,'');
}

# Function: split_article_plwikt
# Parameters:
#  $lang - 'język polski', 'język niemiecki', 'interlingua', 'slovio'
#  $article_text - full article text
#
# Returns:
#  ($before,$lang_section,$after)
#  if no lang section exists: ($article_text, '', '')
sub split_article_plwikt {
	my ($lang, $article_text) = @_;
	my $lang_name = get_language_name('pl',$lang);
	return _join_sections($article_text,
		_split_article_pl($lang_name, $article_text));
}

# Parameters:
#  $lang - 'język polski', 'język niemiecki', 'interlingua', 'slovio'
#  $article_text - full article text
#
# Returns:
#   $lang_index - index of this lang section
#   @sections
sub _split_article_pl {
	my ($lang, $article_text) = @_;
	
	my @sections = split /(==.*?\( *{{[^}]+\}\} *\).*?==)/, $article_text;
	
	#print "sections: $#sections\n";
	
	my $lang_index=0;
	#print "lang: '$lang'\n";
	
	foreach my $section (@sections) {
		
		my $lang_escaped = escape_regex($lang);
		#print encode_utf8("lang escaped: $lang_escaped\n");
		if ($section =~ /==.*?\( *{{ *$lang_escaped *(\|[^}]+)?}} *\).*?==/i) {
			last;
		}
		++$lang_index;
	}
	
	return ($lang_index, @sections);
}

# Parameters:
#   $article_text
#   $lang_index
#   @sections
#
# Returns:
#  ($before,$lang_section,$after)
#  if no lang section exists: ($article_text, '', '')
sub _join_sections {
	my ($article_text,$lang_index, @sections) = @_;
	my ($before, $lang_section, $after)=('','','');

	if ($lang_index == -1 || $lang_index > $#sections) {
		return ($article_text, '', ''); # lang section not found
	}
	
	for (my $i=0; $i<$lang_index; ++$i) {
		$before .= $sections[$i];
	}
	$lang_section = $sections[$lang_index].$sections[$lang_index+1];
	for (my $i=$lang_index+2; $i<=$#sections; ++$i) {
		$after .= $sections[$i];
	}
	
	return ($before, $lang_section, $after);
}

# Function: split_article_dewikt
# Parameters:
#  $lang - 'Polnisch', 'Deutsch'
#  $article_text - full article text
sub split_article_dewikt {
	my ($lang, $article_text) = @_;
	my $lang_name = get_language_name('de',$lang);
	return _join_sections($article_text,
		_split_article_de($lang_name, $article_text));
}

sub _split_article_de {
	my ($lang, $article_text) = @_;
	
	my @sections = split /(==[^={]+\(\s*{{\s*Sprache\s*\|\s*[^)]+\)\s*==)/, $article_text;
	
	#print "sections: $#sections\n";
	
	my $lang_index=0;
	#print "lang: '$lang'\n";
	
	foreach my $section (@sections) {
			
		if ($section =~ /==[^={]+\(\s*{{\s*Sprache\s*\|\s*$lang\s*}}\s*\)\s*==/) {
			last;
		}
		++$lang_index;
	}
	
	return ($lang_index, @sections);
}

# Function: split_article_enwikt
# Parameters:
#  $lang - 'Polish', 'German'
#  $article_text - full article text
sub split_article_enwikt {
	my ($lang, $article_text) = @_;
	my $lang_name = get_language_name('en',$lang);
	return _join_sections($article_text,
		_split_article_en($lang_name, $article_text));
}

sub _split_article_en {
	my ($lang, $article_text) = @_;
	
	my @sections = split /^(==[-'a-zA-Zāâäáèëéíīõüú ]+==[^=])/m, $article_text;
	
# 	print "sections: ", scalar(@sections), "\n";
	
	my $lang_index=0;
# 	print encode_utf8("lang: '$lang'\n");
	
	foreach my $section (@sections) {
# 		print encode_utf8("$section\n&&&&&&&&&&&&\n");
		if ($section =~ /^==\s*$lang\s*==/) {
			last;
		}
		++$lang_index;
	}
	
# 	print "lang index: $lang_index\n";
	return ($lang_index, @sections);
}

# Function: split_article_frwikt
# Parameters:
#  $lang - 'en', 'de'
#  $article_text - full article text
sub split_article_frwikt {
	my ($lang, $article_text) = @_;
	return _join_sections($article_text,
		_split_article_fr($lang, $article_text));
}

sub _split_article_fr {
	my ($lang, $article_text) = @_;

	my @sections = split /(== *\{\{ *=[-a-zA-Z ]+= *\}\} *==)/, $article_text;

# 	print "sections: $#sections\n";

	my $lang_index=0;
# 	print "lang: '$lang'\n";

	foreach my $section (@sections) {
# 		print "$section\n&&&&&&&&&&&&\n";
		if ($section =~ /== *\{\{ *=$lang= *\}\} *==/) {
			last;
		}
		++$lang_index;
	}

# 	print "lang index: $lang_index\n";
	return ($lang_index, @sections);
}

# Function: extract_page_contents
# Parameters:
#   $page_text - full page text
sub extract_page_contents {
	my $page_text=\shift @_;
	my $begin = index($$page_text, '<!-- start content -->');
	if ($begin == -1) {
		$begin = index($$page_text, '<!-- bodytext -->');
	}
	if ($begin == -1) {
		$begin = index($$page_text, '<!-- bodycontent -->');
	}
	my $end = index($$page_text, 'printfooter');
	#print "indexes: $begin | $end\n";
	return substr($$page_text, $begin, $end-$begin+1);
}

# Parameters:
#   $page_text - full page text
#   $server - 'http://localhost/~piotr/enwikt/'
#   $category_name - 'Category:Arabic nouns'
sub _find_category_next_link {
	my $page_text=\shift @_;
	my $server=shift @_;
	my $category_name=shift @_;
	
	if ($$page_text =~ /<a href=".+?(&amp;(filefrom|pagefrom|from)=([^"]+))" title="[^"]+">/) {
		my $url = $server.'index.php?title='.$category_name.$1;
		$url =~ s/&amp;/&/g;
		return $url;
	} else {
		return '';
	}
}

# Function: get_category_contents
#   gets category contents. See also <$use_perlwikipedia>.
#
# Parameters:
#   $server - 'http://localhost/~piotr/enwikt/', 'http://commons.wikimedia.org/w/'
#   $category - 'Category:Arabic nouns', 'Kategoria:Gramatyka'
#   $maxparts - how many result pages to visit (optional)
#   $allow_namespaces - hash
#                        {main=>0, category=>1, image=>0, file=>0, template=>0}
#                        by default main and image are accepted and all other
#                        are rejected; special: all=>1 causes all namespaces to
#                        be accepted
#
# Returns:
#   @retval - array of page names in UTF-8, after decode_utf8
# See also:
#   
sub get_category_contents {
	my ($server,$category,$maxparts,$allow_namespaces,$from) = @_;
	
	$allow_namespaces = {'main'=>1, 'image'=>1, 'file'=>1} unless (defined($allow_namespaces));
	$allow_namespaces->{'main'} = 1 unless (exists($allow_namespaces->{main}));

	if ($use_perlwikipedia) {
		return get_category_contents_perlwikipedia(create_editor($server),$category,$maxparts,$allow_namespaces,$from);
	} else {
		return get_category_contents_internal($server,$category,$maxparts,$allow_namespaces,$from);
	}
}

sub create_editor {
	my ($full_server) = @_;

	$full_server =~ s!^http://!!;
	$full_server =~ m!^(.*)/([^/]+)/$! or die "invalid server spec";
	my ($server, $prefix) = ($1,$2);

	my %settings = load_hash('settings.ini');

	my $editor=MediaWiki::Bot->new({
		host => $server,
		path => $prefix,
		login_data => {'username' => $settings{bot_login}, 'password' => $settings{bot_password}},
		operator => $settings{bot_operator},
	});
# 	$editor->{debug} = 1;
# 	$editor->login($user, $pass);
	return $editor;
}

sub get_category_contents_perlwikipedia {
	my ($editor,$category,$maxparts,$allow_namespaces,$recache) = @_;
	my @retval;

	my $key = $editor->{host} . '|' . $category;
	my @pages;
	my $cached_pages = $recache ? undef : cache_read_values($key);
	if (defined $cached_pages) {
		@pages = @$cached_pages;
	} else {
		@pages = $editor->get_pages_in_category($category, { max => 0 });
		cache_write_values($key, \@pages);
	}
	foreach my $page (@pages) {
# 		print scalar(@pages);
		if ($allow_namespaces->{'all'}) {
			push @retval, $page;
		} else {
			if ($page =~ /(Category|Kategoria|Kategorie):/) {
				push @retval, $page if ($allow_namespaces->{'category'});
			} elsif ($page =~ /(Template|Szablon|Vorlage):/) {
				push @retval, $page if ($allow_namespaces->{'template'});
			}  elsif ($page =~ /(Image|File|Grafika|Plik):/) {
				push @retval, $page if ($allow_namespaces->{'image'} || $allow_namespaces->{'file'});
			} else {
				push @retval, $page if ($allow_namespaces->{'main'});
			}
		}
	}

	return @retval;
}

sub get_category_contents_internal {
	my ($server,$category,$maxparts,$allow_namespaces,$from) = @_;
	my @retval;
	
	$category = uri_escape_utf8($category);
	my $page=$server.'index.php?title='.$category;
	$page .= "&$from" if $from;
# 	$page .= '&action=purge';
	my $part=1;
	
	while($page ne '') {
		my $page_text;
# 		print "visiting $page\n";
		$page_text=get_page($page);
		$page_text=extract_page_contents($page_text);
		
		while ($page_text =~ /<li><a href="[^"]+" title="([^"]+)">/g) {
			my $title=$1;
			if ($title =~ /(Category|Kategoria|Kategorie):/) {
				if($allow_namespaces->{'category'} || $allow_namespaces->{'all'}) {
					push @retval, decode_utf8($title);
				}
			} elsif ($title =~ /(Template|Szablon|Vorlage):/
			&& ($allow_namespaces->{'template'} || $allow_namespaces->{'all'})) {
				push @retval, decode_utf8($title);
			} elsif ($allow_namespaces->{'main'}) {
				push @retval, decode_utf8($title);
			}
		}
		if ($allow_namespaces->{'category'} || $allow_namespaces->{'all'}) {
			while ($page_text =~ /<div class="CategoryTreeSection">(.*)/g) {
				my $match = $1;
				if ($match =~ /<a.*>([^<]+)<\/a><\/div>/) {
					push @retval, decode_utf8('Category:'.$1);
				}
			}
		}
		
		if ($allow_namespaces->{'image'} || $allow_namespaces->{'file'} || $allow_namespaces->{'all'}) {
			while ($page_text =~ /<a href="[^"]+" class="image" title="([^"]+)">/gc) {
				push @retval, decode_utf8('Image:'.$1);
			}
			while ($page_text =~ /<a href="[^"]+" title="(File:[^">]+)">/gc) {
				push @retval, decode_utf8($1);
			}
		}
		
		++$part;
		if (defined($maxparts) && $part > $maxparts) {
			last;
		}
		
		$page = _find_category_next_link($page_text,$server,$category);
		#print "next: $page\n";
	}
	
	for (my $i=0; $i<=$#retval; ++$i) {
		decode_entities($retval[$i]);
	}
	
	return @retval;
}

# Function: get_linking_to
# Parameters:
#   $server - 'http://localhost/~piotr/enwikt/', 'http://commons.wikimedia.org/w/'
#   $article - 'Template:audio', 'Szablon:IPA'
#   $only_main_namespace - return only results from main namespace
#   $maxparts - how many result pages to visit (optional)
#
# Returns:
#   @retval - array of page names in UTF-8, after decode_utf8
sub get_linking_to {
	my ($server,$article,$only_main_namespace,$maxparts) = @_;
	my @retval;
	
	$article = uri_escape_utf8($article);
	
	my $page=$server.'index.php?title=Special:Whatlinkshere&target='.$article;
	if ($only_main_namespace) {
		$page.='&namespace=0';
	}
	
	my $part=1;
	
	while($page ne '') {
		#print "visiting $page\n";
		my $page_text;
		$page_text=get_page($page);
		$page_text=extract_page_contents($page_text);
		
		#print "===\n$page_text===\n";
		
		while ($page_text =~ /<li><a href="[^"]+" title="([^"]+)">/gc) {
			my $title=$1;
			push @retval, decode_utf8($title);
		}
		
		++$part;
		if (defined($maxparts) && $part > $maxparts) {
			last;
		}

		
		$page='';
		if ($page_text =~ /from=(\d+)&amp;back=\d+"/) {
			$page = $server.'index.php?title=Special:Whatlinkshere/'.$article.'&from='.$1;
			#print "next: $page\n";
		}
	}
	
	return @retval;
}

# Function: get_wikicode
# Parameters:
#   $server - 'http://localhost/~piotr/enwikt/', 'http://commons.wikimedia.org/w/'
#             (always with http://)
#   $article - 'Template:audio', 'Szablon:IPA' (case-sensitive)
#
# Returns:
#   page wikicode
sub get_wikicode {
	my ($server,$article) = @_;
	my $page=$server.'index.php?title='.uri_escape_utf8($article).'&action=raw';
	my $text = decode_utf8(Derbeth::Web::get_page($page));
	if (index($text,'<meta name="generator" content="MediaWiki') != -1) {
		# bad request
		return '';
	} else {
		return $text;
	}
}

sub get_wikicode_perlwikipedia {
	my ($editor, $article) = @_;

	my $key = $editor->{host} . '|' . $article;
	my $text = cache_read($key);
	if (defined $text) {
		return $text;
	}

	$text = $editor->get_text($article);
	if (defined $text) {
		cache_write($key, $text);
	}
	return $text;
}

1;
