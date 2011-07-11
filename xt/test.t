use strict;
use warnings;
use Test::More;
use Test::Requires 'Test::Spelling';
use Config;
use File::Spec;
use ExtUtils::MakeMaker;

my $a = *main::a;
my $b = \$a;

use Data::Dumper;
warn $$b;