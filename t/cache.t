#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 36;

# "You know, most people pray silently.
#  Marge He's way the hell up there."
use_ok 'Mojo::Cache::Extended';

my $cache = Mojo::Cache::Extended->new;
$cache->size_of(sub {scalar @{$_[0]}});
is $cache->size_of->([1,2,3,4,5]), 5, 'size of works';

$cache = Mojo::Cache::Extended->new(max_keys => 2);
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

$cache = Mojo::Cache::Extended->new(max_keys => 10000, max_size => 10, size_of => sub {length(shift)});
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

$cache = Mojo::Cache::Extended->new(max_keys => 10000);
$cache->set(foo => 'bar');
$cache->set_expire('foo' => sub{1});
is $cache->get('foo'), undef, 'has expired';

$cache = Mojo::Cache::Extended->new(max_keys => 10000);
$cache->set(foo => 'bar');
$cache->set_expire('foo' => sub{
    my $ts = shift;
    is time - $ts, 1, '1 sec passed';
});
sleep(1);
is $cache->get('foo'), undef, 'has expired';

$cache = Mojo::Cache::Extended->new();
is eval {$cache->get('a')} ,undef, 'non exist key';
