package AppRotator;

use strict;
use warnings;
use base qw(Exporter);

# Класс используется для отказоустойчивого опроса методов Твиттера ( ибо некоторые из них отваливаются по rate limit ). 
# Соответственно, архитектурно это просто фасад, который в каждом экспонированном методе выбирает следующее доступное приложение ( или возвращает отказ, если доступных приложений не существует )

# TODO: переписать просто TwitterAPIExchange с PHP на Perl, и выбросить это дерьмо
 use Scalar::Util 'blessed';

# На вход принимаем конфиг с учетками, и создаёт массив приложений ( т.е. классов TwitterEngine + статус ( живое/не живое )). На каждый вызов метода
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

        my $self = bless {
			apps 	      => @apps,
			req_deadline  => $conf->{req_deadline}
                   }, $class;
        return  $self;
  }

# Actual scheduling cycle
sub run {
	my $self 	= shift;
	my $method  	= shift;

	my @apps	= @{ $self->{apps}};


	foreach my $app ( @apps )
	{
		if ( $app->{status} )
		{
			# Once we will be rate-limited, corresponding method will fail with undef and in this case we have to try another app or wait until either deadline or any available app
			if ( ! defined $app->$method )
			{
				$app->{status} = undef;
				next;
			} 
			break;
		}
	}
}

1;
