package Derbeth::Testeditor;
require Exporter;
use strict;

=head1 NAME
Derbeth::Testeditor - acts as Perlwikipedia object, but outputs results to file instead of making real changes.
=cut

use Derbeth::Util;

our @ISA = ('Perlwikipedia');

sub new {
	my ($class, $infile, $outfile, @other_args) = @_;
	$infile = 'in.txt' unless $infile;
	$outfile = 'out.txt' unless $outfile;
	
	my $object = $class->SUPER::new(@other_args);
	$object->{'infile'} = $infile;
	$object->{'outfile'} = $outfile;
	unlink $infile;
	unlink $outfile;
	return $object;
}

sub get_text {
	my $self = shift;
	my $retval = $self->SUPER::get_text(@_);
	
	$self->{'intext'} = $retval;
	return $retval;
	
}

sub edit {
	my ($self, $page, $text, $summary, $is_minor) = @_;
	appendfile($self->{'infile'},  "\n=======\n\n", $self->{'intext'});
	appendfile($self->{'outfile'}, "\n=======\n$summary\n", $text);
	
	return 1;
}

1;
