package Mojolicious::Plugin::CacheLite;
use strict;
use warnings;
our $VERSION = '0.01';
use base qw/Mojolicious::Plugin/;
use Mojo::Cache::Extended;

    our $_EXPIRE_CODE_ARRAY = [];
    
    sub set_expire {
        my ($class, $code) = @_;
        push @$_EXPIRE_CODE_ARRAY, $code;
    }
    
    sub register {
        my ( $self, $app, $conf ) = @_;
        
        my $keygen = $conf->{keygen} || sub {
            shift->req->url->to_abs->to_string;
        };
        
        my $cache = Mojo::Cache::Extended->new();
        
        if ($conf->{max_bytes}) {
            $cache->max_bytes($conf->{max_bytes});
        }
        
        my $on_process_org = $app->on_process;
        
        $app->on_process(sub {
            
            my ($app, $c) = @_;
            
            my $active = ($c->req->method eq 'GET');
            my $key = $keygen->($c);
            
            if ($active && $key) {
                my $res = $cache->get($key);
                if (defined $res) {
                    $app->log->debug("serving from cache for $key");
                    $c->tx->res($res);
                    $c->rendered;
                    return;
                }
            }
            
            local $_EXPIRE_CODE_ARRAY;
            
            $on_process_org->($app, $c);
            
            my $code = $c->res->code;
            
            if ($active && $key && $code && $code == 200) {
                $app->log->debug("storing in cache for $key");
                $cache->set($key, $c->res);
                for my $code (@$_EXPIRE_CODE_ARRAY) {
                    $cache->set_expire($key, $code);
                }
            }
        });
    }

1;

__END__

=head1 NAME

Mojolicious::Plugin::CacheLite - On memory cache plugin [ALPHA]

=head1 SYNOPSIS

    use Mojolicious::Plugin::CacheLite;
    
    sub startup {
        my $self = shift;
        
        $self->plugin('cache_lite');
        
        or
        
        $self->plugin(cache_lite => {
            max_bytes => 1000000,
            keygen => sub {
                my $c = shift;
                
                # generate key here maybe with $c
                # return undef causes cache disable
                
                return $key;
            },
        });
    }
    
    sub some_where {
        Mojolicious::Plugin::CacheLite->set_expire(sub {
            my $cache_timestamp = shift;
            return 1;
        });
    }

=head1 DESCRIPTION

Mojolicious::Plugin::CacheLite provides on memory cache mechanism for
mojolicious.

This plugin caches whole response into key-value object and returns it for next
request instead of invoking on_process code. You can specify the cache key by
giving code reference which gets mojolicious controller for argument.

You can also specify one or more expiration conditions for each cache key from
anywhere in your app by giving code references. In many case, a single page
output involves not only one data model and each of the models may should have
own cache expiration conditions. To expire a cache exactly right timing,
the cache itself must know when to expire. The feature of this class provides
the mechanism.

=head1 METHODS

=head2 register

$plugin->register;

Register plugin hooks in L<Mojolicious> application.

=head2 Mojolicious::Plugin::CacheLite->set_expire($code_ref)

This appends a code reference for cache expiration control. 
    
    package Model::NewsRelease;
    
    my $sqlite_file = 'news_release.sqlite';
    
    sub list {
        ...
        
        Mojolicious::Plugin::CacheLite->set_expire(sub {
            my $cache_timestamp = shift;
            return $cache_timestamp - (stat($sqlite_file))[9] > 0;
        });
        ...
    }

=head1 AUTHOR

Sugama, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Sugama.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
