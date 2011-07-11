use strict;
use warnings;
use Test::Memory::Cycle;
use Test::More;
use MojoX::Tusu;

    use Test::More tests => 1;
    
    my $app = SomeApp->new;
    memory_cycle_ok( $app );
    
        package SomeApp;
        use strict;
        use warnings;
        use base 'Mojolicious';
        use MojoX::Tusu;
        
        sub startup {
            my $self = shift;
            $self->plugin(cache_lite => {});
        }

	package Plack::Middleware::TestFilter2;
	use strict;
	use warnings;
	use base qw( Plack::Middleware );
	
	sub call {
		
		my $self = shift;
		my $res = $self->app->(@_);
		$self->response_cb($res, sub {
			return sub {
			};
			$res;
		});
	}

__END__
