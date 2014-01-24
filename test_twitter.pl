#! /usr/bin/perl

use strict;

# TODO: переписать просто TwitterAPIExchange с PHP на Perl, и выбросить это дерьмо
 use Net::Twitter;
 use Scalar::Util 'blessed';


  my $consumer_key    = "2gitpWIwmwPPOtcNWKguQ";
  my $consumer_secret = "N9qtivpjAC0OUNr7lLuwFphsk71GQ1cOzGojCSTL3Q";
  my $token	      = "461020977-SD9qndn3iOYe3DdsAZzhBNor0s0ErNeu4hIFYYEv";
  my $token_secret    = "prc9B5jf4wavhPsrDsxXToMheuGD045b9hUccVuF4jWEg";

  my $nt = Net::Twitter->new(
      traits   => [qw/API::RESTv1_1/],
      consumer_key        => $consumer_key,
      consumer_secret     => $consumer_secret,
      access_token        => $token,
      access_token_secret => $token_secret,
      ssl => 1
  );

  #my $result = $nt->update('Hello, world!');

  my $high_water = 0;
  eval {
      my $statuses = $nt->home_timeline({  count => 100 });
      for my $status ( @$statuses ) {
          print "$status->{created_at} <$status->{user}{screen_name}> $status->{text}\n";
      }
  };


  eval {
   my @ids;
    for ( my $cursor = -1, my $r; $cursor; $cursor = $r->{next_cursor} ) {
        $r = $nt->followers_ids({ screen_name => 'kluchkovandrey', cursor => $cursor });

        #$r = $nt->followers_ids({ screen_name => '371846797', cursor => $cursor });
        push @ids, @{ $r->{ids} };
    }

  print "Klychkov followers are : \n".join( " , ", @ids )."\n";
  };

  if ( my $err = $@ ) {
      #die $@ unless blessed $err && $err->isa('Net::Twitter::Error');

      warn "HTTP Response Code: ", $err->code, "\n",
           "HTTP Message......: ", $err->message, "\n",
           "Twitter error.....: ", $err->error, "\n";
  }

  print "Our app lives happily!\n";

