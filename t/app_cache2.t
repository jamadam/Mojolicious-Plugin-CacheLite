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

$t->get_ok('/hello.txt')->content_is('Hello Mojo from a static file!');

package _Basic;
use Mojo::Base 'Mojolicious';
    
    sub startup {
      my $self = shift;
      $self->plugin(cache_lite => {});
    }
