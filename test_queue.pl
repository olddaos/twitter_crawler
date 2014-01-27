#! /usr/bin/perl

use strict;
use Queue;
use Data::Dumper;

my $q= new Queue;

foreach my $pri (1..16)
{
	$q->force_put( int(rand(16384) + rand(256)), $pri );
}

$q->serialize('ddd');
while( ! $q->is_empty())
{
	my $eleam = $q->get();
	print Dumper( $eleam );
}
