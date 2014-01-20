#! /usr/bin/perl

use strict;

use REST::Neo4p;
use strict;
use warnings;

eval {
    REST::Neo4p->connect('http://127.0.0.1:7474');
};
ref $@ ? $@->rethrow : die $@ if $@;


my $idx = REST::Neo4p->get_index_by_name('nt_names','node');
my ($node) = $idx->find_entries(fullname => 'adenine');
my @nodes = $idx->find_entries('fullname:*');

my $query = REST::Neo4p::Query->new(
  'START r=relationship:nt_mutation_types(mut_type = "transversion")
   MATCH a-[r]->b
   RETURN a,b'
  );
$query->execute;
while (my $result = $query->fetch) {
   print $result->[0]->get_property('name'),'->',
         $result->[1]->get_property('name'),"\n";
}

print "Hoho, yoyo\n";
