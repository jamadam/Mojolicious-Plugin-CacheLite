use Test::More qw/no_plan/;
use Test::Mojo;
use File::Spec::Functions;
use Module::Build;
use FindBin;
use lib "$FindBin::Bin/lib/book/lib";
use lib "$FindBin::Bin/lib/user/lib";
use Mojo::Cache::ByteLimited;

BEGIN {
    $ENV{MOJO_LOG_LEVEL} ||= 'fatal';
}

my $cache = Mojo::Cache::ByteLimited->new;

use_ok('Book');
my $test = Test::Mojo->new( app => 'Book' );
$test->get_ok('/books')->status_is(200)->content_is('books');
my $base = 'http://localhost:' . $test->tx->remote_port;

$test->get_ok('/book')->status_is(404);

use_ok('User');
$test = Test::Mojo->new( app => 'User' );
$test->get_ok('/user')->status_is(200)
    ->content_is( 'users', 'it matches the content from the get request' );

$test->post_form_ok( '/user' => { id => 23 } )->status_is(200)
    ->content_is( 'added 23', 'it made a successful post request' );

$test->delete_ok('/user/23')->status_is(200)
    ->content_is( 'deleted 23', 'it has made a successful delete request' );

$test->get_ok( $base . '/user/23' )->status_is(200)
    ->content_is( 'showing 23',
    'it has made a successful get request with user id' );

$test->get_ok('/user/23/email')->status_is(200)
    ->content_is( 'email 23',
    'it has received response for /user/23/email with a get request' );

$test->get_ok('/user/23/name')->status_is(200)
    ->content_is( 'name 23',
    'it has received response for /user/23/name with a get request' );
