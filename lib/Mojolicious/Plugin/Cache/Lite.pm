package Mojolicious::Plugin::Cache::Lite;
use strict;
use warnings;
our $VERSION = '0.01';
use base qw/Mojolicious::Plugin/;
use Mojo::JSON;
use Mojo::Cache::Extended;

    sub register {
        my ( $self, $app, $conf ) = @_;
        
        my $key_generater = $conf->{key_generater} || sub {
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
            my $key = $key_generater->($c);
            
            if ($active && $key) {
                my $data = Mojo::JSON->decode($cache->get($key));
                if (defined $data) {
                    $app->log->debug("serving from cache for $key");
                    $c->res->code($data->{code});
                    $c->res->headers(bless $data->{headers}, 'Mojo::Headers');
                    $c->res->body($data->{body});
                    $c->rendered;
                    $c->render_text(''); ## cheat mojolicious
                    return;
                }
            }
            
            $on_process_org->($app, $c);
            
            my $code = $c->res->code;
            
            if ($active && $key && $code && $code == 200) {
                $app->log->debug("storing in cache for $key");
                my %header = %{$c->res->headers};
                $cache->set($key, Mojo::JSON->encode({
                    body    => $c->res->body,
                    headers => \%header,
                    code    => $c->res->code
                }));
            }
        });
    }

1;

__END__

=head1 NAME

Mojolicious::Plugin::Cache::Lite - On memory cache plugin

=head1 SYNOPSIS

    use Mojolicious::Plugin::Cache::Lite;
    
    sub startup {
        my $self = shift;
        
        $self->plugin('cache_lite');
        
        or
        
        $self->plugin(cache_lite => {
            max_bytes => 1000000,
            key_generater => sub {
                my $c = shift;
                
                # generate key here maybe with $c
                # return undef causes cache disable
                
                return $key;
            },
        });
    }

=head1 DESCRIPTION

Mojolicious::Plugin::Cache::Lite provides on memory cache mechanism for
mojolicious.

=over

=item No dependency

=item Pure Perl.

=item Flexible expiration control [not implemented yet]

=back

=head1 METHODS

=head2 register

$plugin->register;

Register plugin hooks in L<Mojolicious> application.

=head1 AUTHOR

Sugama, E<lt>sugama@jamadam.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Sugama.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
