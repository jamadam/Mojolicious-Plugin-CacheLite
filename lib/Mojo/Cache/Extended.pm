package Mojo::Cache::Extended;
use strict;
use warnings;
use Mojo::Base -base;
    
    has 'max_keys' => 100;
    has 'max_bytes' => 5000000;
    
    my $ATTR_CACHE      = 1;
    my $ATTR_STACK      = 2;
    my $ATTR_TOTAL      = 3;
    my $ATTR_EXPIRE     = 4;
    my $ATTR_TIMESTAMP  = 5;
    
    sub get {
        if ($_[0]->{$ATTR_EXPIRE}) {
            if (my $expire = $_[0]->{$ATTR_EXPIRE}->{$_[1]}) {
                for my $code (@$expire) {
                    if ($code->($_[0]->{$ATTR_TIMESTAMP}->{$_[1]})) {
                        return;
                    }
                }
            }
        }
        ($_[0]->{$ATTR_CACHE} || {})->{$_[1]};
    }
    
    sub set {
        my ($self, $key, $value) = @_;
        
        my $keys  = $self->max_keys;
        my $max_length = $self->max_bytes;
        my $cache = $self->{$ATTR_CACHE} ||= {};
        my $stack = $self->{$ATTR_STACK} ||= [];
        my $ts = $self->{$ATTR_TIMESTAMP} ||= {};
        $self->{$ATTR_TOTAL} ||= 0;
        $self->{$ATTR_TOTAL} += guess_size_of($value);
        
        while (@$stack >= $keys || $self->{$ATTR_TOTAL} > $max_length) {
            my $key = shift @$stack;
            $self->{$ATTR_TOTAL} -= guess_size_of($cache->{$key});
            delete $cache->{$key};
            delete $ts->{$key};
        }
        
        push @$stack, $key;
        $cache->{$key} = $value;
        $ts->{$key} = time;
        
        return $self;
    }
    
    sub set_expire {
        my ($self, $key, $cb) = @_;
        push(@{$self->{$ATTR_EXPIRE}->{$key}}, $cb);
    }
    
    sub guess_size_of {
        
        my $obj = shift;
        my $res = 0;
        if (ref $obj) {
            if (my $type = ("$obj" =~ qr{(?:^|=)(\w+)\(})[0]) {
                if ($type eq 'ARRAY') {
                    for my $a (@$obj) {
                        $res += guess_size_of($a);
                    }
                } elsif ($type eq 'HASH') {
                    for my $key (keys %$obj) {
                        $res += length($key);
                        $res += guess_size_of($obj->{$key});
                    }
                } elsif ($type eq 'SCALAR') {
                    $res = length($$obj);
                }
            }
        } elsif ($obj) {
            $res = length($obj);
        }
        $res;
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
