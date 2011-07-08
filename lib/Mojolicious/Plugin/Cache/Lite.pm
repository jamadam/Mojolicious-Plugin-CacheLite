package Mojolicious::Plugin::Cache::Lite;
use strict;
use warnings;
our $VERSION = '0.01';
use base qw/Mojolicious::Plugin/;
use Mojo::JSON;
use Mojo::Cache::ByteLimited;

    sub register {
        my ( $self, $app, $conf ) = @_;
        
        my $key_generater = $conf->{key_generater} || sub {
            shift->req->url->to_abs->to_string;
        };
    
        my $cache = Mojo::Cache::ByteLimited->new;
        
        $app->plugins->add_hook(
            'before_dispatch' => sub {
                my ($c) = shift;
                
                return if $c->req->method ne 'GET';
                
                if (my $key = $key_generater->($c)) {
                    my $data = Mojo::JSON->decode($cache->get($key));
                    if (defined $data) {
                        use Data::Dumper;
                        warn Dumper $data;
                        $app->log->debug("serving from cache for $key");
                        $c->res->code($data->{code});
                        $c->res->headers($data->{headers});
                        $c->res->body($data->{body});
                        $c->stash('from_cache' => 1);
                        $c->rendered;
                        #$c->render('');
                    }
                }
            }
        );
    
        $app->plugins->add_hook(
            'after_dispatch' => sub {
                my $c = shift;
                
                #conditions at which no caching will be done
                ## - it is already a cached response
                return if $c->stash('from_cache');
                
                ## - has to be GET request
                return if $c->req->method ne 'GET';
                
                ## - only successful response
                return if $c->res->code != 200;
                
                if (my $key = $key_generater->($c)) {
                    $app->log->debug("storing in cache for $key");
                    my %header = %{$c->res->headers};
                    $cache->set($key, Mojo::JSON->encode({
                        body    => $c->res->body,
                        headers => \%header,
                        code    => $c->res->code
                    }));
                }
            }
        );
    
        return;
    }

1;

__END__

=head1 NAME

Mojolicious::Plugin::Cache::Lite - 

=head1 SYNOPSIS

    use Mojolicious::Plugin::Cache::Lite;
    Mojolicious::Plugin::Cache::Lite->new;

=head1 DESCRIPTION

=head1 METHODS

=head2 new

=head1 AUTHOR

sugama, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by sugama.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
