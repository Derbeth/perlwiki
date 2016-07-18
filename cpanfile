requires 'HTML::Form';
requires 'MediaWiki::Bot';

on test => sub {
	requires 'File::Slurp'
	requires 'Test::Assert'
};
