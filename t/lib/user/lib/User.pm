package User;

use strict;
use base 'Mojolicious';
use File::Spec::Functions;

# This method will run once at server start
sub startup {
    my $self = shift;

    # Routes
    my $r = $self->routes;

    $self->plugin('cache-lite');

    $r->route('/user')->via('post')->to('controller-cache#add');
    $r->route('/user/:id')->via('delete')->to('controller-cache#remove_user');
    my $books
        = $r->waypoint('/user')->via('get')->to('controller-cache#users');
    my $more
        = $books->waypoint('/:id')->via('get')->to('controller-cache#show');
    $more->route('/email')->via('get')->to('controller-cache#email');
    $more->route('/name')->via('get')->to('controller-cache#name');
}

1;
