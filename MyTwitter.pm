package MyTwitter;

use strict;
use warnings;
use base qw(Exporter);
our @EXPORT_OK = qw( l2dist_padd l2norm cosine poisson_substract interpol upsample poisson );

our $VERSION = '0.01';

my  $oauth_access_token;
my  $oauth_access_token_secret;
my  $consumer_key;
my  $consumer_secret;
my  $postfields;
my  $getfield;
my  $oauth;
my  $url;

    /**
     * Create the API access object. Requires an array of settings::
     * oauth access token, oauth access token secret, consumer key, consumer secret
     * These are all available by creating your own application on dev.twitter.com
     * Requires the cURL library
     * 
     * @param array $settings
     */
    sub  __construct
    {

	my $settings = shift;

        if (! defined($settings->{'oauth_access_token'})
            || ! defined($settings->{'oauth_access_token_secret'})
            || ! defined($settings->{'consumer_key'})
            || ! defined($settings->{'consumer_secret'}))
        {
            die "Make sure you are passing in the correct parameters\n";
        }

        $this->oauth_access_token = $settings['oauth_access_token'];
        $this->oauth_access_token_secret = $settings['oauth_access_token_secret'];
        $this->consumer_key = $settings['consumer_key'];
        $this->consumer_secret = $settings['consumer_secret'];
    }

1;
