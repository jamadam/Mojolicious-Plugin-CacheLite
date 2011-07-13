#!/usr/bin/env perl

use strict;
use warnings;
use Mojo::Cache::Extended;
use Mojo::Cache;
use Mojo::Message::Response;
use Test::Mojo;


my $ta = Test::Mojo->new('_TestAppA');
my $tb = Test::Mojo->new('_TestAppB');

use Benchmark qw( timethese cmpthese ) ;
my $r = timethese(100, {
    a => sub{
        $ta->tx($ta->ua->get('/hello.txt'));
    },
    b => sub{
        $tb->tx($tb->ua->get('/hello.txt'));
    },
} );
cmpthese $r;

package _TestAppA;
use Mojo::Base 'Mojolicious';
    
    sub startup {
      my $self = shift;
    }

package _TestAppB;
use Mojo::Base 'Mojolicious';
    
    sub startup {
      my $self = shift;
      $self->plugin(cache_lite => {});
    }
