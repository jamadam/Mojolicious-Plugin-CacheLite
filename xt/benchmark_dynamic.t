#!/usr/bin/env perl

use strict;
use warnings;
use Mojo::Cache::Extended;
use Mojo::Cache;
use Mojo::Message::Response;
use Test::Mojo;
use Time::HiRes qw(sleep);

my $ta = Test::Mojo->new('_TestAppA');
my $tb = Test::Mojo->new('_TestAppB');

use Benchmark qw( timethese cmpthese ) ;
my $r = timethese(5, {
    a => sub{
        $ta->tx($ta->ua->get('/'));
    },
    b => sub{
        $tb->tx($tb->ua->get('/'));
    },
} );
cmpthese $r;

package _TestAppA;
use Mojo::Base 'Mojolicious';
    
    sub startup {
      my $self = shift;
      my $r = $self->routes;
      $r->route('/')->to(cb => sub {
        shift->render(template => 'simple');
      });
    }

package _TestAppB;
use Mojo::Base 'Mojolicious';
    
    sub startup {
      my $self = shift;
      $self->plugin(cache_lite => {});
      my $r = $self->routes;
      $r->route('/')->to(cb => sub {
        shift->render(template => 'simple');
      });
    }
