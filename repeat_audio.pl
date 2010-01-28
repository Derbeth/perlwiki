#!/usr/bin/perl

@params=('./audiosetter.pl', '--nofilter', '--nodebug',
		'--limit', '100', '-w', 'de', '-l', 'fr');

for($i=0; $i<30; ++$i) {
	system(@params);
}
