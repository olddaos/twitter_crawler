#! /usr/bin/perl

use strict;

use Queue;
use AppRotator;
use TwitterEngine;
use GraphStorage;
use Data::Dumper;

my $machine     = new AppRotator('apps.json');
my $q	        = new Queue('new_queue.json');
my $engine      = new TwitterEngine( $machine );
my $graph_store = new GraphStorage;

#$q->force_put( 371846797, 1 );

#$q->put( 174953869, 1 );

my $fetch_exhaustive = 1;
my $fetch_shallow    = 0;
my $maxcount;
my $process_limit    = 1048576;

open FILEGRAPH, ">> circle_filegraph.csv" || die "Err: cannot open graph file\n";
open NODEATTR, ">> node_attr.csv" || die "Err: cannot open node attributes file\n";

open DEGCORREL, ">> deg_correl.csv" || die "Err: cannot open degree correlation sequence\n";

# Store quee on Ctrl-C
$SIG{'INT'} = sub {
   warn "Ctrl-C is pressed, boiling down\n";

   $q->serialize("new_queue.json"); 

   close FILEGRAPH;
   close NODEATTR;
   close DEGCORREL;
   die "Err: written queue, then dead!\n" 
};

my $priority = 1;

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

		# TODO: add only Moscow nodes!
		 print FILEGRAPH "$item->[0];$id\n";
		push @chunk, $id;
		if ( ++$chunk_size > 99 )
		{
			$chunk_size = 0;
			my $lookup_result = $engine->lookup_users({ user_id => [ @chunk ] });
			map {
				 my $follower = $_;

				 # TODO: make it regex if (( $follower->{location} eq "" ) || ( lc($follower->{location}) eq "moscow"))
				 #{
			    		 print DEGCORREL "$#fc_ids;$follower->{followers_count}\n";
					 $q->force_put( $follower->{id}, ++$priority );
					 print ".";
					 print NODEATTR qq($follower->{id}\t$follower->{screen_name}\t$follower->{followers_count}\t$follower->{friends_count}\t$follower->{status}->{created_at}\n);
				 #}
				 #print "Trc: follower count $follower->{followers_count}, screen: $follower->{screen_name}\n";
			    } sort  { $b->{followers_count} <=> $a->{followers_count} } @{ $lookup_result};
			# TODO: тут нужно организовать запихивание в очередь пар ( user_id, outdegree )
			undef @chunk;
			print "\n done chunk...\n";
		}
	} @fc_ids;

	# Сюда мы попадаем в случае, если фолловеров меньше 100
	if ( defined @chunk )
	{
		my $lookup_result = $engine->lookup_users({ user_id => [ @chunk ] });

		# TODO: use closures to omit this fucken shit
		map {
			my $follower = $_;

			# TODO: make it regex if (( $follower->{location} eq "" ) || ( lc($follower->{location}) eq "moscow"))
			#{
			print DEGCORREL "$#fc_ids;$follower->{followers_count}\n";
			$q->force_put( $follower->{id}, ++$priority );
			print ".";
			print NODEATTR qq($follower->{id}\t$follower->{screen_name}\t$follower->{followers_count}\t$follower->{friends_count}\t$follower->{status}->{created_at}\n);
			#}
			#print "Trc: follower count $follower->{followers_count}, screen: $follower->{screen_name}\n";
		} sort  { $b->{followers_count} <=> $a->{followers_count} } @{ $lookup_result};

		print "\n done SMALL chunk\n";
	}

}

# Недообработанные остатки пишем в файлик
$q->serialize("new_queue.json");
