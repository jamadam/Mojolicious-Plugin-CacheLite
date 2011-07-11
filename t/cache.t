#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 38;

# "You know, most people pray silently.
#  Marge He's way the hell up there."
use_ok 'Mojo::Cache::Extended';

my $cache = Mojo::Cache::Extended->new(max_keys => 2);
$cache->set(foo => 'bar');
is $cache->get('foo'), 'bar', 'right result';
$cache->set(bar => 'baz');
is $cache->get('foo'), 'bar', 'right result';
is $cache->get('bar'), 'baz', 'right result';
$cache->set(baz => 'yada');
is $cache->get('foo'), undef,  'no result';
is $cache->get('bar'), 'baz',  'right result';
is $cache->get('baz'), 'yada', 'right result';
$cache->set(yada => 23);
is $cache->get('foo'),  undef,  'no result';
is $cache->get('bar'),  undef,  'no result';
is $cache->get('baz'),  'yada', 'right result';
is $cache->get('yada'), 23,     'right result';

$cache = Mojo::Cache::Extended->new(max_keys => 3);
$cache->set(foo => 'bar');
is $cache->get('foo'), 'bar', 'right result';
$cache->set(bar => 'baz');
is $cache->get('foo'), 'bar', 'right result';
is $cache->get('bar'), 'baz', 'right result';
$cache->set(baz => 'yada');
is $cache->get('foo'), 'bar',  'right result';
is $cache->get('bar'), 'baz',  'right result';
is $cache->get('baz'), 'yada', 'right result';
$cache->set(yada => 23);
is $cache->get('foo'),  undef,  'no result';
is $cache->get('bar'),  'baz',  'right result';
is $cache->get('baz'),  'yada', 'right result';
is $cache->get('yada'), 23,     'right result';

$cache = Mojo::Cache::Extended->new(max_keys => 10000, max_bytes => 10);
$cache->set(foo => 'bar');
is $cache->get('foo'), 'bar', 'right result';
$cache->set(bar => 'baz');
is $cache->get('foo'), 'bar', 'right result';
is $cache->get('bar'), 'baz', 'right result';
$cache->set(baz => 'yada');
is $cache->get('foo'), 'bar',  'right result';
is $cache->get('bar'), 'baz',  'right result';
is $cache->get('baz'), 'yada', 'right result';
$cache->set(yada => 23);
is $cache->get('foo'),  undef,  'no result';
is $cache->get('bar'),  'baz',  'right result';
is $cache->get('baz'),  'yada', 'right result';
is $cache->get('yada'), 23,     'right result';

$cache = Mojo::Cache::Extended->new(max_keys => 10000, max_bytes => 10);
$cache->set(foo => 'bar');
$cache->set_expire('foo' => sub{1});
is $cache->get('foo'), undef, 'has expired';

$cache = Mojo::Cache::Extended->new(max_keys => 10000, max_bytes => 10);
$cache->set(foo => 'bar');
$cache->set_expire('foo' => sub{
    my $ts = shift;
    is time - $ts, 1, '1 sec passed';
});
sleep(1);
is $cache->get('foo'), undef, 'has expired';

is Mojo::Cache::Extended::guess_size_of([1,2,3]), 3, 'right guess';
is Mojo::Cache::Extended::guess_size_of(bless {a => 'test1', b => 'test2'}, 'Test'), 12, 'right guess';
is Mojo::Cache::Extended::guess_size_of(bless {a => 'test1', b => [1,2,3]}, 'Test'), 10, 'right guess';
is Mojo::Cache::Extended::guess_size_of(sub {1}), 15, 'right guess';
