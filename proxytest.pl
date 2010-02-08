#!/usr/bin/perl -w

use LWP::UserAgent;

my $ua = new LWP::UserAgent;

$ua->proxy('http', 'http://201.92.9.250:8080');
my $response = $ua->get('http://example.com');
print $response->content;

