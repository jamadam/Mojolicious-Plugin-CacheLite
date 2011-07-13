package Mojolicious::Plugin::CacheLite;
use strict;
use warnings;
our $VERSION = '0.03';
use base qw/Mojolicious::Plugin/;
use Mojo::Cache::Extended;
use Time::HiRes qw(time);

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
        
        my $cache = Mojo::Cache::Extended->new(
            size_of => sub {shift->content->body_size}
        );
        
        if ($conf->{max_size}) {
            $cache->max_size($conf->{max_size});
        }
        
        if ($conf->{max_keys}) {
            $cache->max_keys($conf->{max_keys});
        }
        
        my $on_process_org = $app->on_process;
        
        $app->on_process(sub {
            
            my ($app, $c) = @_;
            
            my $key = ($c->req->method eq 'GET') ? $keygen->($c) : undef;
            
            if ($key) {
                my $res = $cache->get($key);
                if (defined $res) {
                    $app->log->debug("serving from cache for $key");
                    $c->tx->res($res);
                    $c->rendered;
                    return;
                }
            }
            
            local $_EXPIRE_CODE_ARRAY;
            
            my $ts_s = time;
            
            $on_process_org->($app, $c);
            
            if ($key && time - $ts_s > ($conf->{threshold} || 0)) {
                my $code = $c->res->code;
                if ($code && $code == 200) {
                    $app->log->debug("storing in cache for $key");
                    $cache->set($key, $c->res);
                    for my $code (@$_EXPIRE_CODE_ARRAY) {
                        $cache->set_expire($key, $code);
                    }
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
            max_size => 1000000,
            max_keys  => 100,
            threshold => 0.08,
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

=head1 OPTIONS

=head2 keygen => code reference [optional]

Key generator for cache entries. This must be given in code reference.
The following is the default.

    $self->plugin(cache_lite => {
        keygen => sub {
            $c = shift; ## mojolicious controller
            return $c->req->url->to_abs->to_string;
        }
    });

returning undef causes cache generation and reference disabled.

=head2 max_size => number [optional]

Maximum byte length for total of body lengths of cache. Default is 5000000.
Since it only measures body length, this value must be considered for rough
limitation for memory size.

    $self->plugin(cache_lite => {max_size => 5000000});

=head2 max_keys => number [optional]

Maximum number of cache keys, defaults to 100.

    $self->plugin(cache_lite => {max_keys => 100});

=head2 threshold => number [optional]

Threshold time interval for page generation to activate cache generation.
You can give it a floating number of second. This plugin measures how long
the page generation spent the time and compares to the threshold. 

    $self->plugin(cache_lite => {threshold => 0.8});

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
