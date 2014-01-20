package TwitterEngine;

use strict;
use warnings;
use base qw(Exporter);

# Класс используется для обеспечения функционирования одного Твиттерного сервиса ( предполагается, что входные данные ( включая токен ) ему дала МашинаРотации )

# TODO: переписать просто TwitterAPIExchange с PHP на Perl, и выбросить это дерьмо
 use Net::Twitter;
 use Scalar::Util 'blessed';

# На вход принимаем учётные данные приложения ( от МашиныРотации )
  sub new {
	my $class = shift;
	my ( $ckey, $csecret, $token, $tsecret ) = @_;

	my $self = bless {
			consumer_key 	 => $ckey,
			consumer_secret  => $csecret,
			token		 => $token,
			token_secret	 => $tsecret,
			nt		 => Net::Twitter->new(
					      traits   => [qw/API::RESTv1_1/],
					      consumer_key        => $ckey,
					      consumer_secret     => $csecret,
					      access_token        => $token,
					      access_token_secret => $tsecret,
					      ssl 		  => 1
					   )
		   }, $class;
	return	$self;
  }


  sub followers_ids
  {
	my $self    = shift;
	my $screen  = shift;
	my $nt      = $self->{nt};

	die "Err: followers_ids cannot be called, as object was not constructed properly!\n" unless defined $nt;

	my @ids;
	for ( my $cursor = -1, my $r; $cursor; $cursor = $r->{next_cursor} ) {
		$r = $nt->followers_ids({ screen_name => qq($screen), cursor => $cursor });
		push @ids, @{ $r->{ids} };
	}

	print "Trc: $screen followers are : \n".join( " , ", @ids )."\n";

	if ( my $err = $@ ) {
		die $@ unless blessed $err && $err->isa('Net::Twitter::Error');

		warn "HTTP Response Code: ", $err->code, "\n",
		     "HTTP Message......: ", $err->message, "\n",
		     "Twitter error.....: ", $err->error, "\n";
	}

  }

1;
