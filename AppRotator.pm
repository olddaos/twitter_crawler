package AppRotator;

use strict;
use warnings;
use base qw(Exporter);
use JSON;

# Класс используется для отказоустойчивого опроса методов Твиттера ( ибо некоторые из них отваливаются по rate limit ). 
# Соответственно, архитектурно это просто фасад, который в каждом экспонированном методе выбирает следующее доступное приложение ( или возвращает отказ, если доступных приложений не существует )

# TODO: переписать просто TwitterAPIExchange с PHP на Perl, и выбросить это дерьмо
 use Scalar::Util 'blessed';

# На вход принимаем имя конфига с учетками, и создаёт массив приложений ( т.е. классов TwitterEngine + статус ( живое/не живое )). На каждый вызов метода
  sub new {
        my $class  = shift;
	my $config = shift;

	# Дескрипторы приложений
	my @apps;

	my $conf_text;
	open CONF, "< $config" || die "Err: cannot read in config";

	while ( <CONF> )
	{
		chomp;
		$conf_text .= $_;
	}

	my $conf  = decode_json $conf_text;

	# Create apps from config
	map
	{
		my $par_hash = $_;

		my $nt = Net::Twitter->new(
				traits   => [qw/API::RESTv1_1/],
				consumer_key        => $par_hash->{consumer_key},
				consumer_secret     => $par_hash->{consumer_secret},
				access_token        => $par_hash->{token},
				access_token_secret => $par_hash->{token_secret},
				ssl => 1
				);

		push @apps, { 'appref' => $nt, 'status' => 1 };		
	} @{ $conf };

	print "- Trc : $#apps application created in pool...\n";

        my $self = bless {
			apps 	      => [ @apps ],
			active_index  => 0
                   }, $class;
        return  $self;
  }

# Returns next active instance of an application 
sub ack {
	my $self 	= shift;
	my $method  	= shift;

	my  $had_active;
	my $idx 	= 0;

	foreach my $app ( @{ $self->{apps}} ) 
	{	
		   if ( $app->{status} )
		   {
			   $had_active	         = 1;
			   $self->{active_index} = $idx;
			   return $app->{'appref'};
		   } 

		   $idx++;
	}

	if ( ! $had_active )
	{
		   # Rotate apps in order to exploit failure times non-uniformity
		   my $app = shift @{ $self->{apps}};
		   push @{ $self->{apps}}, $app;

		   $self->{active_index} = 0;

		   return $app->{'appref'};
	}
}

# Marks current app as temporarily broken
sub markdown 
{
	my $self    = shift;
	
	@{$self->{apps}}[ $self->{active_index} ]->{'status'} = 0; 
}

# Marks current app as temporarily broken
sub markup
{
	my $self    = shift;
	
	@{$self->{apps}}[ $self->{active_index} ]->{'status'} = 1; 
}

1;
