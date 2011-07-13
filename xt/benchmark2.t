#!/usr/bin/env perl

use strict;
use warnings;
use Mojo::Cache::Extended;
use Mojo::Cache;
use Mojo::Message::Response;
use Test::Mojo;

my $cachea = Mojo::Cache->new(max_keys => 2);
my $cacheb = Mojo::Cache::Extended->new(max_keys => 2, size_of => sub {shift->content->body_size});

my $keya = 1;
my $keyb = 1;

my $t = Test::Mojo->new('_Basic');
$t->get_ok('/hello.txt');
my $res = $t->tx->res;

use Benchmark qw( timethese cmpthese ) ;
my $r = timethese(100000, {
    a => sub{
        $cachea->set($keya++, $res);
    },
    b => sub{
        $cacheb->set($keyb++, $res);
    },
} );
cmpthese $r;

package _Basic;
use Mojo::Base 'Mojolicious';
