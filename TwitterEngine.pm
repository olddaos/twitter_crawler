package TwitterEngine;

use strict;
use warnings;
use base qw(Exporter);

# Реализует методы для извлечения и сохранения фолловеров, а также приоритизации узлов для выкачки. Использует машину ротации для общения с Твиттером посредством нескольких приложений 

 use Net::Twitter;
 use Scalar::Util 'blessed';

# На вход принимаем ссылку на машину ротации. Машина ротации циклически предоставляет ссылку на следующее гарантированно живое приложение
  sub new {
	my $class       = shift;
	my $rot_machine = shift;

	my $self = bless {
			machine   => $rot_machine
		   }, $class;
	return	$self;
  }

  # Uses closures to wrap every piece of exception-prone code
  sub  backoff
  {
	my $self 	= shift;
	my $sub		= shift;	# Actually, this is just a complete call-ready wrapup

	my ( $gotit, $try_counter );

        my $max_tries = 32;

        my ( $lookupres, $r );
        my $cursor      = -1;
	my $sleep_delay = 16;
        while ( ! $gotit && ( $try_counter++ < $max_tries))
        {
                # The following is to replace try ( ) {...} catch in normal languages
                eval {
			$sub->();

                        # Сюда мы попадаем только если Лось НЕ кинул исключение. И значит, мы имеем право пометить приложение, как работающее ( ведь могло случиться и так, что оно 
                        $self->{machine}->markup();
			$gotit     = 1;
                };
                if ( my $err = $@ ) {
			# Смысл нижеследующей строчки в том, чтобы дохнуть от НЕтвиттерных ошибок! Иначе вечный кайф гарантирован
                        die $@ unless blessed $err && $err->isa('Net::Twitter::Error');

                        warn "Trc: sleeping due to Twitter ban!";

                        # Тут нужно пометить соответствующее приложение как standby
                        warn "HTTP Response Code: ", $err->code, "\n",
                             "HTTP Message......: ", $err->message, "\n",
                             "Twitter error.....: ", $err->error, "\n";
                        $self->{machine}->markdown();

                        $sleep_delay    *= 1.2;

                        sleep int( $sleep_delay );
                }
        }

  }

  # Extracts detailed user info
  sub  lookup_users
  {
	my $self	= shift;
	my $params	= shift;
	my $machine	= $self->{machine};
	my $lookupres;

	my $looksub = sub {
		my $engine      = $machine->ack();
		# TODO: исследовать переносимость курсора между приложениями. Если у нас rate limit случился во время итерирования, то можем ли мы продолжить итерировать в другом приложении?
		$lookupres	= $engine->lookup_users( $params );
	};

	$self->backoff( $looksub );
		
	return $lookupres;
  }

  # Extracts specified amount of pages, full of followers ids 
  # Implements exponential back off on 403 ( when we are rate limited )
  sub  extract_followers
  {
	my $self       = shift;
	my $userid     = shift;
	my $exhaustive = shift;	     # exhaustive == true => we gather everything, else we get only single page of results ( at the moment, 5000 maximum )
	my $nt         = $self->{machine}->ack();

	my ( @ids, $r) ;
	my $cursor = -1;
	my $extact_sub	= sub {
                        for ( ; $cursor; $cursor = $r->{next_cursor} ) {

                                # Ротируем приложения для гарантии их равномерной загрузки
                                # TODO: фиг знает, что лучше. Если все приложения уже забанены, то нам нужно пользоваться тем, что есть...i
                                my $nt      = $self->{machine}->ack();
                                $r          = $nt->followers_ids({ user_id => qq($userid), cursor => $cursor });
                                push @ids, @{ $r->{ids} };

                                last if ! $exhaustive;
                        }

                #        print "Trc: $userid followers are : \n".join( " , ", @ids )."\n";
		};

	$self->backoff( $extact_sub );

	return @ids;
  }

1;
