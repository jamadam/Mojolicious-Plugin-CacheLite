#!/usr/bin/env perl

use strict;
use warnings;

# Disable Bonjour, IPv6, epoll and kqueue
BEGIN {
  $ENV{MOJO_NO_BONJOUR} = $ENV{MOJO_NO_IPV6} = $ENV{MOJO_POLL} = 1;
  $ENV{MOJO_MODE} = 'development';
}

use Test::More tests => 18;

use FindBin;
use lib "$FindBin::Bin/lib";

use File::Spec;
use Mojo::Date;
use Mojo::Transaction::HTTP;
use Test::Mojo;
use Mojolicious;

my $t = Test::Mojo->new('MojoliciousTestCached1');

$t->get_ok('/cacheable/1')
  ->status_is(200)
  ->content_is('6');

$t->get_ok('/cacheable/2')
  ->status_is(200)
  ->content_is('7');

$t->get_ok('/cacheable/1')
  ->status_is(200)
  ->content_is('6');

$t->get_ok('/cacheable/2')
  ->status_is(200)
  ->content_is('7');

sleep(2);

$t->get_ok('/cacheable/1')
  ->status_is(200)
  ->content_is('8');

$t->get_ok('/cacheable/2')
  ->status_is(200)
  ->content_is('9');

package MojoliciousTestCached1;
use Mojo::Base 'Mojolicious';
    
    sub startup {
      my $self = shift;
      
      $self->plugin('cache-lite' => {key_generater => sub{
        my $c = shift;
        my $path = $c->req->url->path;
        if ($path =~ qr{/cacheable/}) {
          return $path;
        }
      }});
      
      my $r = $self->routes;
      my $counter = 5;
      $r->route('/cacheable/:a')->to(cb => sub {
        $counter++;
        
        Mojolicious::Plugin::Cache::Lite->set_expire(sub {time - $_[0] >= 2});
        
        shift->render_text($counter);
      });
    }
