#!/usr/bin/perl
 use MediaWiki::API;
 
 my %settings = load_hash('settings.ini');
my $user = $settings{bot_login};
my $pass = $settings{bot_password};

  my $mw = MediaWiki::API->new();
  $mw->{config}->{api_url} = 'http://localhost/~piotr/plwikt/api.php'; #'http://en.wikipedia.org/w/api.php';

  # log in to the wiki
  $mw->login( { lgname => $user, lgpassword => $pass } )
    || die $mw->{error}->{code} . ': ' . $mw->{error}->{details};

  # get a list of articles in category
  my $articles = $mw->list ( {
    action => 'query',
    list => 'categorymembers',
    cmtitle => 'Category:polski (indeks)',
    cmlimit => 'max' } )
    || die $mw->{error}->{code} . ': ' . $mw->{error}->{details};

  # and print the article titles
  foreach (@{$articles}) {
      print "$_->{title}\n";
  } 
