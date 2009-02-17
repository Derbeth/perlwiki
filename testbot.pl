#!/usr/bin/perl
use strict; # 'strict' insists that all variables be declared

# Call the Perlwikipedia module.
# Note that the 'p' is capitalized, due to Perl style.
use Perlwikipedia;
use Encode;
use URI::Escape qw(uri_escape_utf8);

use utf8;

# Username and password. 
my $user = 'Derbeth'; my $pass = '';

#Create a Perlwikipedia object
my $editor=Perlwikipedia->new($user);

# Uncomment below to set the wiki language to 'de' (German)
# (the default is 'en').
# Wikipedias in all languages use 'w' as the path:
# (de.wikipedia.org/w/index.php)
$editor->set_wiki('pl.wiktionary.org','w');

# Turn debugging on, to see what the bot is doing
$editor->{debug} = 1;

#Log in. 
$editor->login($user, $pass);

#Pull the wikitext of the Wikipedia Sandbox

my $article = "Wikisłownik:Brudnopis";
#my $article = 'słońce';

#open(IN,'in2.txt');
#my $article = <IN>; chomp ($article);
#$article = decode_utf8($article);
my $text=$editor->get_text($article);

exit;

#print $text;
#if ($text =~ /język polski/) { print "okeeeee\n"; }
#exit(0);

# append something to the text
#$text = $text . "Experimenting a little bit...\n";

#$text =~ s/This.*/This iś a test../g;

$text .= 'test';

my $edit_summary='test';

# Whether to check the minor edit box.
# One has $is_minor == 1 for minor edits. This argument is optional.
my $is_minor = 0;

# Submit to Wikipedia.
# Note: This does not warn of edit conflicts, it just overwrites existing text.
$editor->edit($article, $text, $edit_summary, $is_minor);

# Take a break (frequent edits are forbidden per bot policy)
print "Sleep 5\n";
sleep 5;