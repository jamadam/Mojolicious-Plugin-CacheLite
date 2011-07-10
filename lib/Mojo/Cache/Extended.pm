package Mojo::Cache::Extended;
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
        if ($_[0]->{$ATTR_EXPIRE}) {
            my $expire = $_[0]->{$ATTR_EXPIRE}->{$_[1]};
            if ($expire && $expire->($_[0]->{$ATTR_TIMESTAMP}->{$_[1]})) {
                return;
            }
        }
        return ($_[0]->{$ATTR_CACHE} || {})->{$_[1]};
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

Mojo::Cache::Extended - 

=head1 SYNOPSIS

=head1 DESCRIPTION

L<Mojo::Cache::Extended> class represents caches. 

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

=head2 C<set_expire>

Sets expiration condition by code refs. This method always wrap
the original one.
    
    $cache->set_expire('foo' => sub{
        my $ts = shift;
    });

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
