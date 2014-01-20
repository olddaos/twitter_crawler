#! /usr/bin/perl

use strict;

use REST::Neo4p;
use strict;
use warnings;

eval {
    REST::Neo4p->connect('http://127.0.0.1:7474');
};
ref $@ ? $@->rethrow : die $@ if $@;

my @node_defs = 
    (
     { name => 'A', type => 'purine' },
     { name => 'C', type => 'pyrimidine' },
     { name => 'G', type => 'purine'},
     { name => 'T', type => 'pyrimidine' }
    );
my $nt_types = REST::Neo4p::Index->new('node','nt_types');
my $nt_names = REST::Neo4p::Index->new('node','nt_names');
my @nts = my ($A,$C,$G,$T) = map { REST::Neo4p::Node->new($_) } @node_defs;

$nt_names->add_entry($A, 'fullname' => 'adenine');
$nt_names->add_entry($C, 'fullname' => 'cytosine');
$nt_names->add_entry($G, 'fullname' => 'guanosine');
$nt_names->add_entry($T, 'fullname' => 'thymidine');

for ($A,$G) {
    $nt_types->add_entry($_, 'type' => 'purine');
}

for ($C,$T) {
    $nt_types->add_entry($_, 'type' => 'pyrimidine');
}

my $nt_mutation_types = REST::Neo4p::Index->new('relationship','nt_mutation_types');

my @all_pairs;
my @a = @nts;
while (@a) {
    my $s = shift @a;
    push @all_pairs, [$s, $_] for @a;
}

for my $pair ( @all_pairs ) {
    if ( $pair->[0]->get_property('type') eq 
  $pair->[1]->get_property('type') ) {
 $nt_mutation_types->add_entry(
     $pair->[0]->relate_to($pair->[1],'transition'),
     'mut_type' => 'transition'
     );
 $nt_mutation_types->add_entry(
     $pair->[1]->relate_to($pair->[0],'transition'),
     'mut_type' => 'transition'
     );
    }
    else {
 $nt_mutation_types->add_entry(
     $pair->[0]->relate_to($pair->[1],'transversion'),
     'mut_type' => 'transversion'
     );
 $nt_mutation_types->add_entry(
     $pair->[1]->relate_to($pair->[0],'transversion'),
     'mut_type' => 'transversion'
     );
    }
}

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
