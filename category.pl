#!/usr/bin/perl

use strict;
use utf8;

use Derbeth::Wikitools;
use Derbeth::Wiktionary;
use Derbeth::Inflection;
use Perlwikipedia;
use Encode;

my $word='Abart';

my %settings = load_hash('settings.ini');
my $user = $settings{bot_login}; # for wiki
my $pass = $settings{bot_password};   # for wiki

my $editor_local=Perlwikipedia->new($user);
#$editor_local->{debug} = 1;
$editor_local->set_wiki('localhost/~piotr', 'dewikt');
$editor_local->login($user, $pass);

my $editor_remote=Perlwikipedia->new($user);
$editor_remote->set_wiki('localhost/~piotr', 'plwikt');
$editor_remote->login($user, $pass);

my $pron='De-Abart.ogg';
my $pron_pl='';
my ($inflection,$singular,$plural,$ipa_sing,$ipa_pl);

	{
		my $page_text_local = $editor_local->get_text($word);
		if ($page_text_local !~ /\w/) {
			print "entry does not exist: ",encode_utf8($word),"\n";
			next;
		}
		
		initial_cosmetics('de',\$page_text_local);
		my($before_l,$section_l,$after_l) = split_article_wikt('de','Deutsch',$page_text_local);
		
		if ($section_l eq '') {
			print encode_utf8("no język niemiecki section: $word\n");
			next;
		}
		
		# ===== check =======
		
		($inflection,$singular,$plural,$ipa_sing,$ipa_pl)
			= extract_inflection_dewikt(\$section_l);
		print encode_utf8("inf: '$inflection'\n");
		print encode_utf8("s: $singular, p: $plural, [$ipa_sing], [$ipa_pl]\n");
	}

my $page_text_remote = $editor_remote->get_text($word);
	my $original_page_text = $page_text_remote;
	if ($page_text_remote !~ /\w/) {
		print "entry does not exist: ",encode_utf8($word),"\n";
		next;
	}
	
	my $initial_summary = initial_cosmetics('pl',\$page_text_remote);
	my ($before,$section,$after) = split_article_wikt('pl','język niemiecki',$page_text_remote);
	
	my($result,$audios_count,$edit_summary) #adding
		= add_audio_plwikt(\$section,$pron,'język niemiecki',0,$pron_pl,$ipa_sing,$ipa_pl);
	
	$page_text_remote = $before.$section.$after;
	
	my $final_summary = final_cosmetics('pl', \$page_text_remote);
	$edit_summary .= '; '.$initial_summary if ($initial_summary);
	$edit_summary .= '; '.$final_summary if ($final_summary);
	
	
open(IN,'>in.txt');
print IN encode_utf8($original_page_text);
close(IN);
open(OUT,'>out.txt');
print OUT encode_utf8($page_text_remote);
close(OUT);
	
print encode_utf8($edit_summary),"\n";
