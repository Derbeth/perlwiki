#!/usr/bin/perl

@langs = qw/cs da en es fa fi fr ga hr hsb hu hy ia id is it
la lv nl pl pt ro ru sv tr zh/;

#@langs = qw/ro nl sv/;

#@langs = qw/da cs en es fa fi fr ga hr hu hy ia id is it la
#lv pl pt ro ru sv tr zh/;

#@langs = 

foreach $lang (@langs) {
	print STDERR "./audiosetter.pl $lang\n";
	#system('./audiosetter.pl','-l',$lang);
	@params=('./audiosetter.pl', '--limit', 30000, '--nofilter', '--nodebug',
		'-w', 'en', '-l', $lang);
	system(@params);
}
