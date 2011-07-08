package Mojo::Cache::ByteLimited;
use Mojo::Base -base;
    
    has 'max_keys' => 100;
    has 'max_bytes' => 5000000;
    
    sub get { (shift->{cache} || {})->{shift()} }
    
    sub set {
        my ($self, $key, $value) = @_;
        
        # Cache with size limit
        my $keys  = $self->max_keys;
        my $max_length = $self->max_bytes;
        my $cache = $self->{cache} ||= {};
        my $stack = $self->{stack} ||= [];
        $self->{total} ||= 0;
        $self->{total} += length($value);
        
        while (@$stack >= $keys || $self->{total} > $max_length) {
            my $key = shift @$stack;
            $self->{total} -= length($cache->{$key});
            delete $cache->{$key};
        }
        
        push @$stack, $key;
        $cache->{$key} = $value;
        
        return $self;
    }
    
    sub remove {
        my ($self, $key) = @_;
        my $cache = $self->{cache};
        my $stack = $self->{stack};
        if (defined $cache->{$key}) {
            $self->{total} -= length($cache->{$key});
            @$stack = grep {$_ ne $key} @$stack;
            delete $cache->{$key};
        }
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

=head1 METHODS

L<Mojo::Cache> inherits all methods from L<Mojo::Base> and implements the
following new ones.

=head2 C<get>

  my $value = $cache->get('foo');

Get cached value.

=head2 C<set>

  $cache = $cache->set(foo => 'bar');

Set cached value.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
