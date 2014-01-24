#! /usr/bin/perl

use strict;

use Queue;
use AppRotator;
use TwitterEngine;
use GraphStorage;
use Data::Dumper;

my $machine     = new AppRotator('apps.json');
my $q	        = new Queue;
my $engine      = new TwitterEngine( $machine );
my $graph_store = new GraphStorage;

$q->put( 371846797, 1 );

my $fetch_exhaustive = 1;
my $fetch_shallow    = 0;
my $maxcount;
my $process_limit    = 1048576;

open FILEGRAPH, "> filegraph.csv" || die "Err: cannot open graph file\n";

# Store queue on Ctrl-C
local $SIG{ALARM} = sub {
   warn "Ctrl-C is pressed, boiling down\n";

   $q->serialize("new_queue.json"); 

   close FILEGRAPH;
   die "Err: written queue, then dead!\n" 
};


# Выбираем задания из очереди, пока она не пуста, либо пока не достигли счетчика
while ( ! $q->is_empty() || $maxcount++ > $process_limit )
{
	print "Trc: queue size is ".$q->size()." \n";
	my $item = $q->get();

	# Получаем ВСЕХ фолловеров первого круга
	my @fc_ids   = $engine->extract_followers( $item->[0], $fetch_exhaustive );


	# Разбиваем их на группы по 100 ( сколько по максимуму понимает lookup ) и получаем outdegree
	my $chunk_size;
	my @chunk;

	map {
		my $id = $_;

		print FILEGRAPH "$item->[0];$id\n";
		push @chunk, $id;
		if ( ++$chunk_size > 99 )
		{
			$chunk_size = 0;
			my $lookup_result = $engine->lookup_users({ user_id => [ @chunk ] });
			map {
				 my $follower = $_;

				 $q->put( $follower->{id}, $follower->{followers_count} );
				 print ".";
				 #print "Trc: follower count $follower->{followers_count}, screen: $follower->{screen_name}\n";
			    } @{ $lookup_result};
			# TODO: тут нужно организовать запихивание в очередь пар ( user_id, outdegree )
			undef @chunk;
			print "\n done chunk...\n";
		}
	} @fc_ids;

	# Сюда мы попадаем в случае, если фолловеров меньше 100
	if ( defined @chunk )
	{
		my $lookup_result = $engine->lookup_users({ user_id => [ @chunk ] });

                        map {
                                 my $follower = $_;

                                 $q->put( $follower->{id}, $follower->{followers_count} );
                                 print "Trc: follower count $follower->{followers_count}, screen: $follower->{screen_name}\n"; 
                            } @{ $lookup_result};
		# TODO: тут нужно организовать запихивание в очередь пар ( user_id, outdegree )
	}

}

# Недообработанные остатки пишем в файлик
$q->serialize("new_queue.json");
