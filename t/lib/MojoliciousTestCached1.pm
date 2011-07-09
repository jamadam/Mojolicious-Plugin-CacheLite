package MojoliciousTestCached1;
use Mojo::Base 'Mojolicious';

sub development_mode {
  my $self = shift;

  # Static root for development
  $self->static->root($self->home->rel_dir('public_dev'));
}

# "Let's face it, comedy's a dead art form. Tragedy, now that's funny."
sub startup {
  my $self = shift;
  
  $self->plugin('cache-lite' => {key_generater => sub{
    my $c = shift;
    my $path = $c->req->url->path;
    if ($path =~ qr{/cacheable/}) {
      return $path;
    }
  }});
  
  my $r = $self->routes;
  my $counter = 5;
  $r->route('/cacheable/:a')->to(cb => sub {
    $counter++;
    shift->render_text($counter);
  });
}

1;
