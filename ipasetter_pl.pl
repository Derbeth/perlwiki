#!/usr/bin/perl

use Perlwikipedia;
use Derbeth::Wikitools;
use Encode;

use strict;
use utf8;

my $language; 
$language = 'język rosyjski';

my @words;

my %done; # skip_word => 1
my %ipa; # word => IPA without brackets

sub save_done {
	open(DONE,'>done_pl.txt');
	foreach my $done_word (keys %done) {
		print DONE encode_utf8($done_word)."\n";
	}
	close(DONE);
}

$SIG{INT} = $SIG{TERM} = sub { save_done(); exit; };

open(DONE,'done_pl.txt');

while(<DONE>) {
	chomp;
	$done{decode_utf8($_)} =1;
}

close(DONE);

open(IPA,'plwikt_ipa_ru.txt');

while(my $line=<IPA>) {
	chomp $line;
	$line=decode_utf8($line);
	
	if ($line=~/([^=]+)=(.+)/) {
		$ipa{$1} = $2;
	} else {
		#print "no match '".encode_utf8($line)."'!\n";
	}
}

#while (my($word,$pron) = each(%ipa)) {
#	print "'".encode_utf8($word)."' => [".encode_utf8($pron)."]\n";
#}
#exit(0);

my $added=0;

my %settings = load_hash('settings.ini');
my $user = $settings{bot_login};
my $pass = $settings{bot_password};
my $editor=Perlwikipedia->new($user);
#$editor->{debug} = 1;
$editor->set_wiki('pl.wiktionary.org','w');
$editor->login($user, $pass);

while (my($word,$pron) = each(%ipa)) {
	#print "'$word' => '$pron'\n";
	
	if (exists $done{$word}) {
		print encode_utf8($word).": already done\n";
		next;
	}
	$done{$word} = 1;
	
	sleep 5;
	
	my $page_text = $editor->get_text($word);
	if ($page_text !~ /\w/) {
		print "entry does not exist: ".encode_utf8($word)."\n";
		next;
	}
	
	$page_text =~ s/''l(p|m)''/{{l$1}}/g;
	$page_text =~ s/ ''w''/ {{w}}/g;
	
	my($before,$section,$after) = split_article_plwikt($language,$page_text);
	
	if ($section eq '') {
		print "no $language section: ".encode_utf8($word)."\n";
		next;
	}
	
	# ===== section processing =======
	
	if ( $section =~ /\[\[Aneks:IPA\|IPA]]\s+(\/|\[)\S/
	|| ($section =~ /{{IPA/ && $section !~ /<!--\s*{{IPA/)) {
		print encode_utf8($word).": has IPA\n";
		next;
	}
	$section =~ s/<!--\s*{{IPA[^}]+}}\s*-->//;
	$section =~ s/<!-- \[\[Aneks:IPA\|(IPA)?\]\]:.*?-->//;
	
	print "adding pronunciation: ".encode_utf8($word)." => "
		.encode_utf8($pron)."\n";
	
	++$added;
	
	if ($section !~ /{{wymowa}}/) {
		print encode_utf8($word).": no pronunciation section\n";
		$section =~ s/{{znaczenia}}/{{wymowa}}\n{{znaczenia}}/;
	}
	
	my ($pron_sing,$pron_pl)=split /\|/, $pron;
	if (defined($pron_pl)) {
		if ($section =~ /{{wymowa}}.*{{lm}}(\n|\r|\f|.)*\{\{znaczenia}}/) {
			$section =~ s/{{wymowa}}(\s+{{lp}})?(\s*)/{{wymowa}}$1 {{IPA3|$pron_sing}}$2/;
			$section =~ s/{{wymowa}}(.*?{{lm}})/{{wymowa}}$1 {{IPA4|$pron_pl}}/;
		} else {
		
			$section =~ s/{{wymowa}}(\s+{{lp}})?(.*?)(\n|\r|\f)/{{wymowa}}$1 {{IPA3|$pron_sing}} $2 {{lm}} {{IPA4|$pron_pl}}$3/;
		}
		$section =~ s/  / /g;
	} else {
		
		$section =~ s/{{wymowa}}(\s+{{lp}})?(\s*)/{{wymowa}}$1 {{IPA3|$pron_sing}}$2/;
	}
	
	$page_text = $before.$section.$after;
	($before,$after) = split_before_sections($page_text);
	
	$before =~ s/(z|Z)obacz (też|także):?\s+\[\[([^\]]+)\]\]\s*\n/{{zobteż|$3}}\n/;
	$before =~ s/(\n|\r|\f)+({{zobteż[^}]+}})(\n|\r|\f)+/$1$2$3/;
	$before =~ s/(\n|\r|\f){2,}$/$1/;
	
	$page_text = $before.$after;
	
	$text =~ s/(\n|\r|\f){3}/$1$1/g;
	$page_text =~ s/<!-- \[\[Aneks:IPA\|(IPA)?\]\]:.*?-->//;
	$page_text =~ s/\[\[Aneks:IPA\|(IPA)?\]\]: \/ \///;
	
	my $summary='dodanie IPA z [[:en:Transwiki:Russian language/Swadesh list]]';
	#print "page text:".encode_utf8($page_text)."\n";
	#exit(0);
	$editor->edit($word, $page_text, $summary, 1);
	
	if ($added > 50) {
		print "finished\n";
		last;
	}
	
}

save_done();