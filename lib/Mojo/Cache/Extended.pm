package Mojo::Cache::Extended;
use strict;
use warnings;
use Mojo::Base -base;
    
    has 'max_keys' => 100;
    has 'max_size' => 5000000;
    has 'size_of';
    
    my $ATTR_CACHE      = 1;
    my $ATTR_STACK      = 2;
    my $ATTR_TOTAL      = 3;
    
    sub get {
        if (my $cache = $_[0]->{$ATTR_CACHE}->{$_[1]}) {
            if ($cache->[3]) {
                for my $code (@{$cache->[3]}) {
                    if ($code->($cache->[1])) {
                        return;
                    }
                }
            }
            $cache->[0];
        }
    }
    
    sub set {
        my ($self, $key, $value) = @_;
        
        my $keys  = $self->max_keys;
        my $max_size = $self->max_size;
        my $cache = $self->{$ATTR_CACHE} ||= {};
        my $stack = $self->{$ATTR_STACK} ||= [];
        $self->{$ATTR_TOTAL} ||= 0;
        my $length;
        if (my $size_of = $self->size_of) {
            $length = $size_of->($value);
            $self->{$ATTR_TOTAL} += $length;
        }
        
        while (@$stack >= $keys || $self->{$ATTR_TOTAL} > $max_size) {
            my $key = shift @$stack;
            $self->{$ATTR_TOTAL} -= $cache->{$key}->[2] || 0;
            delete $cache->{$key};
        }
        
        push @$stack, $key;
        $cache->{$key} = [$value, time, $length, undef];
        
        return $self;
    }
    
    sub set_expire {
        my ($self, $key, $cb) = @_;
        push(@{$self->{$ATTR_CACHE}->{$key}->[3]}, $cb);
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

=head2 C<max_size>

  my $max_size = $cache->max_size;
  $cache       = $cache->max_size(10000000);

Maximum size of value length sum, defaults to C<5000000>.

=head2 C<size_of>

  $cache->size_of(sub {length(shift)});

This attribute specifies the rule for measure the size of cache.

=head1 METHODS

L<Mojo::Cache> inherits all methods from L<Mojo::Base> and implements the
following new ones.

=head2 C<get>

  my $value = $cache->get('foo');

Get cached value.

=head2 C<set>

  $cache = $cache->set(foo => 'bar');

Set cached value.

=head2 C<set_expire>

Sets expiration condition by code refs. This method always wrap
the original one.
    
    $cache->set_expire('foo' => sub{
        my $ts = shift;
    });

=head2 C<guess_size_of>

This is aimed at internal use. This wild guesses the object size.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
