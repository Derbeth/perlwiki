#!/usr/bin/perl -w

use strict;
use utf8;

use MediaWiki::Bot 3.3.1;
use MediaWiki::API;
use Getopt::Long;
use Pod::Usage;
use Encode;
use Term::ANSIColor;

use Derbeth::Util 0.5.0;

my $show_help = 0;
my $dry_run = 0;
my $verbose = 1;

my $wiki = 'pl.wikinews.org';
my $rc_limit = 50;

my $delete_reason = 'spam';

my $block_reason = 'spam';
my $expiry = '1 day';
my $anononly = 1;
my $allowusertalk = 1;

sub match_suspicious_text {
	my ($page_text) = @_;
	return $& if $page_text =~ /\{\{(ek|delete) *\| *spam/i;

	$page_text =~ /\bcar games\b/;
	return $&;
}

GetOptions(
	'dry-run|d' => \$dry_run,
	'help|h' => \$show_help,
	'verbose|v' => \$verbose,
	'wiki|w=s' => \$wiki,
	'recent|r=i' => \$rc_limit,
	'delete-reason=s' => \$delete_reason,
	'block-reason=s' => \$block_reason,
	'expiry=s' => \$expiry,
	'anononly' => \$anononly,
	'allowusertalk' => \$allowusertalk,
) or pod2usage('-verbose'=>1,'-exitval'=>1);
pod2usage('-verbose'=>2,'-noperldoc'=>1) if ($show_help);
pod2usage('-verbose'=>1,'-noperldoc'=>1, '-msg'=>'No args expected') if ($#ARGV != -1);

#==== START

my %settings = load_hash('settings-admin.ini');
my $editor = MediaWiki::Bot->new({
	host => $wiki,
	protocol => 'https',
	login_data => {'username' => $settings{bot_login}, 'password' => $settings{bot_password}},
	operator => $settings{bot_operator},
});

my @rc = $editor->recentchanges({limit => $rc_limit, show => {anon => 1, patrolled => 0}});
print "$wiki has ", scalar(@rc), " anonymous, non patrolled recent changes\n";
@rc = grep { suspicious_page($_) } @rc;
print "Found ", scalar(@rc), " suspicious pages\n";

if ($dry_run) {
	foreach my $hashref (@rc) {
		print encode_utf8("Would delete '$hashref->{title}' with reason '$delete_reason'\n");
		print encode_utf8("Would block '$hashref->{user}' for '$expiry' with reason '$delete_reason'"),
			" anononly=$anononly allowusertalk=$allowusertalk\n";
	}
	exit;
}

my $mw = MediaWiki::API->new( { api_url => "https://$wiki/w/api.php" }  );
$mw->login( {lgname => $settings{bot_login}, lgpassword => $settings{bot_password} } )
    || die $mw->{error}->{code} . ': ' . $mw->{error}->{details};
my $response = $mw->api({action => 'tokens', type => 'block|delete'})
	|| die $mw->{error}->{code} . ': ' . $mw->{error}->{details};
my $block_token = $response->{tokens}->{"blocktoken"};
my $delete_token = $response->{tokens}->{"deletetoken"};
foreach my $hashref (@rc) {
	my $blocked = $mw->api( {
		action => 'block',
		user => $hashref->{user},
		token => $block_token,
		expiry => $expiry,
		reason => $block_reason,
		anononly => $anononly,
		allowusertalk => $allowusertalk,
		} );
	if (!$blocked) {
		if ($mw->{error}->{code} eq 'alreadyblocked') {
			print "$hashref->{user} already blocked\n"; # TODO query and confirm
		} else {
			die "Cannot block $hashref->{user}: $mw->{error}->{code} ($mw->{error}->{details})";
		}
	} else {
		print "Blocked $hashref->{user}\n";
	}

	my $deleted = $mw->api( {
		action => 'delete',
		title => $hashref->{title},
		token => $delete_token,
		reason => $delete_reason,
		} );
	if (!$deleted) {
		if ($mw->{error}->{code} eq 'cantdelete') {
			print encode_utf8("Cannot delete $hashref->{title} (already deleted?)\n"); # TODO query and confirm
		} else {
			die encode_utf8("Cannot delete $hashref->{title}: $mw->{error}->{code} ($mw->{error}->{details})");
		}
	} else {
		print encode_utf8("Deleted $hashref->{title}\n");
	}
}

sub get_token {
	my ($api, $title, $token_type) = @_;
}

sub is_ip {
	my ($arg) = @_;
	return $arg =~ /^\d+\.\d+/;
}

sub suspicious_page {
	my ($page) = @_;

	if (!is_ip($page->{user})) {
		print colored('OK', 'green'), encode_utf8(" $page->{title} (author $page->{user} is not ip)\n") if $verbose;
		return 0;
	}

	my $page_text = $editor->get_text($page->{title});
	unless ($page_text) {
		print colored('OK', 'green'), encode_utf8(" $page->{title} (cannot get page text)\n") if $verbose;
		return 0;
	}

	my $suspicious = match_suspicious_text($page_text);
	if ($suspicious) {
		print colored('NOT OK', 'red'), encode_utf8(" $page->{title} (suspicious text: '$suspicious')\n") if $verbose;
		return 1;
	}

	print colored('OK', 'green'), encode_utf8(" $page->{title} (nothing suspicious in page text)\n") if $verbose;
	return 0;
}

=head1 NAME

blockdelete - scans recent changes for vandalisms, blocks vandals and deletes pages

=head1 SYNOPSIS

 blockdelete [options]

 Options:
   -w --wiki <page>     wiki to run on (like 'pl.wikinews.org')
   -r --recent <no>     number of recent changes to scan, defaults to 50

   -d --dry-run         do not make any modifications, just print what will be edited
   -v --verbose         explain what the bot does

   -h --help            show full help and exit

=head1 DETAILS

 Requires admin's credentials stored in 'settings-admin.ini' (see settings.ini.example for the format).

 Only treats anon edits as vandalism.

=head1 AUTHOR

Derbeth http://pl.wikinews.org/wiki/User:Derbeth https://github.com/Derbeth

=cut
