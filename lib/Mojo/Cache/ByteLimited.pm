package Mojo::Cache::ByteLimited;
use strict;
use warnings;
use Mojo::Base -base;
    
    has 'max_keys' => 100;
    has 'max_bytes' => 5000000;
    
    my $ATTR_CACHE = 1;
    my $ATTR_STACK = 2;
    my $ATTR_TOTAL = 3;
    my $ATTR_EXPIRE = 4;
    my $ATTR_TIMESTAMP = 5;
    
    sub get {
        my ($self, $key) = @_;
        if (my $val = ($self->{$ATTR_CACHE} || {})->{$key}) {
            my $expire = ($self->{$ATTR_EXPIRE} || {})->{$key};
            if ($expire && $expire->($self->{$ATTR_TIMESTAMP}->{$key})) {
                return;
            }
            return $val;
        }
    }
    
    sub set {
        my ($self, $key, $value) = @_;
        
        my $keys  = $self->max_keys;
        my $max_length = $self->max_bytes;
        my $cache = $self->{$ATTR_CACHE} ||= {};
        my $stack = $self->{$ATTR_STACK} ||= [];
        my $ts = $self->{$ATTR_TIMESTAMP} ||= {};
        $self->{$ATTR_TOTAL} ||= 0;
        $self->{$ATTR_TOTAL} += length($value);
        
        while (@$stack >= $keys || $self->{$ATTR_TOTAL} > $max_length) {
            $self->remove(shift @$stack);
        }
        
        push @$stack, $key;
        $cache->{$key} = $value;
        $ts->{$key} = time;
        
        return $self;
    }
    
    sub remove {
        my ($self, $key) = @_;
        my $cache = $self->{$ATTR_CACHE} || {};
        my $stack = $self->{$ATTR_STACK} || [];
        my $ts = $self->{$ATTR_TIMESTAMP} ||= {};
        if (defined $cache->{$key}) {
            $self->{$ATTR_TOTAL} -= length($cache->{$key});
            @$stack = grep {$_ ne $key} @$stack;
            delete $cache->{$key};
            delete $ts->{$key};
        }
    }
    
    sub set_expire {
        my ($self, $key, $cb) = @_;
        my $org = $self->{$ATTR_EXPIRE}->{$key} || sub{};
        $self->{$ATTR_EXPIRE}->{$key} = sub {
            if ($cb->(@_) || $org->(@_)) {
                $self->remove($key);
                return 1;
            }
        };
    }

1;
__END__

=head1 NAME

Mojo::Cache::ByteLimited - 

=head1 SYNOPSIS

=head1 DESCRIPTION

L<Mojo::Cache::ByteLimited> is a Mojo::Cache sub class with byte limiter.

Note that this module is EXPERIMENTAL and might change without warning!

=head1 ATTRIBUTES

L<Mojo::Cache> implements the following attributes.

=head2 C<max_keys>

  my $max_keys = $cache->max_keys;
  $cache       = $cache->max_keys(50);

Maximum number of cache keys, defaults to C<100>.

=head2 C<max_bytes>

  my $max_bytes = $cache->max_bytes;
  $cache       = $cache->max_bytes(10000000);

Maximum size of value length sum, defaults to C<5000000>.

=head1 METHODS

L<Mojo::Cache> inherits all methods from L<Mojo::Base> and implements the
following new ones.

=head2 C<get>

  my $value = $cache->get('foo');

Get cached value.

=head2 C<set>

  $cache = $cache->set(foo => 'bar');

Set cached value.

=head2 C<remove>

  $cache = $cache->remove('foo');

Remove cached value.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
