#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

# Disable Bonjour, IPv6, epoll and kqueue
BEGIN {
  $ENV{MOJO_NO_BONJOUR} = $ENV{MOJO_NO_IPV6} = $ENV{MOJO_POLL} = 1;
  $ENV{MOJO_MODE} = 'development';
}

use Test::More tests => 30;

use FindBin;
use lib "$FindBin::Bin/lib";

use File::Spec;
use Mojo::Date;
use Mojo::Transaction::HTTP;
use Test::Mojo;
use Mojolicious;

my $t = Test::Mojo->new('_Basic');

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

$t->get_ok('/cacheable/mb')
  ->status_is(200)
  ->content_is('♥');

$t->get_ok('/cacheable/mb')
  ->status_is(200)
  ->content_is('♥');

$t = Test::Mojo->new('_SometimesSlowApp');

$t->get_ok('/cacheable/fast')
  ->status_is(200)
  ->content_is('6');

$t->get_ok('/cacheable/fast')
  ->status_is(200)
  ->content_is('7');

$t = Test::Mojo->new('_SometimesSlowApp');

$t->get_ok('/cacheable/slow')
  ->status_is(200)
  ->content_is('6');

$t->get_ok('/cacheable/slow')
  ->status_is(200)
  ->content_is('6');

package _Basic;
use Mojo::Base 'Mojolicious';
    
    sub startup {
      my $self = shift;
      
      $self->plugin(cache_lite => {
        keygen => sub{
          my $c = shift;
          my $path = $c->req->url->path;
          if ($path =~ qr{/cacheable/}) {
            return $path;
          }
        },
      });
      
      my $r = $self->routes;
      my $counter = 5;
      $r->route('/cacheable/mb')->to(cb => sub {
        shift->render_text('♥');
      });
      $r->route('/cacheable/:a')->to(cb => sub {
        $counter++;
        shift->render_text($counter);
      });
    }

package _SometimesSlowApp;
use Mojo::Base 'Mojolicious';
    
    sub startup {
      my $self = shift;
      
      $self->plugin(cache_lite => {
        keygen => sub{
          my $c = shift;
          my $path = $c->req->url->path;
          if ($path =~ qr{/cacheable/}) {
            return $path;
          }
        },
        threshold => 0.8,
      });
      
      my $r = $self->routes;
      my $counter = 5;
      $r->route('/cacheable/slow')->to(cb => sub {
        sleep(1);
        $counter++;
        shift->render_text($counter);
      });
      $r->route('/cacheable/fast')->to(cb => sub {
        $counter++;
        shift->render_text($counter);
      });
    }
