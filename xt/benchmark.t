#!/usr/bin/env perl

use strict;
use warnings;
use Mojo::Cache::Response;
use Mojo::Cache;

my $cachea = Mojo::Cache->new(max_keys => 2);
my $cacheb = Mojo::Cache::Response->new(max_keys => 2);
$cachea->set('key', 'value');
$cacheb->set('key', 'value');

    use Benchmark qw( timethese cmpthese ) ;
    my $r = timethese(1000000, {
        a => sub{
            $cachea->get('key');
        },
        b => sub{
            $cacheb->get('key');
        },
    } );
    cmpthese $r;