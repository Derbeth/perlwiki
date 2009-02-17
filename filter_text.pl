#!/usr/bin/perl

while (<>) {
	if (/[^=]=(zla_dlugosc|nie_rzeczownik)/) {
		print;
	}
}
