package Queue; 

use strict;
use warnings;
use base qw(Exporter);

use JSON;

# Реализует методы простой файловой очереди с приоритетами 

# На вход принимаем имя файла с очередь. Если оно пустое, то создаём тупо пустую очередь 
  sub new {
        my $class       = shift;
        my $file_queue  = shift;

	my $queue;
	if ( defined $file_queue )
	{
		open FH, "< $file_queue" || die "Err: cannot construct Queue object. Queue file is missing\n";
		my   ( $config_text, $config );

		while ( <FH> )
		{
			chomp;
			$config_text .= $_;
		}

		$queue  = decode_json $config_text;
	}
	else
	{
		$queue = [ ];
	}

        my $self = bless {
                        queue   => $queue
                   }, $class;
        return  $self;
  }

  sub size
  {
	my $self        = shift;

	return	scalar @{ $self->{queue} };
  }

  sub is_empty
  {
	my $self 	= shift;
	my $amount =  ( scalar @{ $self->{queue} } );	

	print "q amount is $amount\n";
	return ( $amount <= 0 );
  }

  # self->queue всегда сортирован по убыванию приоритетов ( т.к. у нас приоритет -- это outdegree, и мы хотим в первую очередь выкачивать узлы с большим outdegree )
  sub put 
  {
	my $self        = shift;
	my $item	= shift;
	my $priority    = shift;
	
	push @{ $self->{queue} }, [ $item, $priority ]; 

	my  @sorted = sort { $b->[1] <=> $a->[1] }
	               		@{ $self->{queue} };	

	@{ $self->{queue} }  =  @sorted;
  }

  # Puts with external consistent priority, do not sort
  sub force_put 
  {
	my $self        = shift;
	my $item	= shift;
	my $priority    = shift;
	
	push @{ $self->{queue} }, [ $item, $priority ]; 
  }

  # Возвращаем узлы по убыванию приоритетов
  sub get
  {
	my $self                  = shift;
	my $element		  = shift @{ $self->{queue} };

	return $element;
  }

  sub serialize
  {
	my $self       = shift;
	my $out_file   = shift;

	my $config_str = encode_json $self->{queue};

	open FH, "> $out_file" || die "Err: cannot open config for writing!\n";
	print FH $config_str;

	close FH;
  }
1;
