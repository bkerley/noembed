package Noembed;

use Class::Load qw/try_load_class/;
use Plack::Request;
use JSON;

use parent 'Plack::Component';

our $DEFAULT = [ qw/GitHub YouTube Wikipedia oEmbed/ ];

sub prepare_app {
  my $self = shift;

  $self->{sources} ||= $DEFAULT;
  $self->{providers} = [];

  $self->register_provider($_) for @{$self->{sources}};
  delete $self->{sources};
}

sub call {
  my ($self, $env) = @_;

  my $req = Plack::Request->new($env);
  my $url = $req->parameters->{url};

  return error("url parameter required") unless $url;
  return $self->handle_url($url);
}

sub handle_url {
  my ($self, $url) = @_;

  for my $provider (@{$self->{providers}}) {
    if ($provider->matches($url)) {
      return _handle_match($provider, $url);
      last;
    }
  }

  error("no matching providers found for $url");
}

sub _handle_match {
  my ($provider, $url) = @_;

  return sub {
    my $respond = shift;

    $provider->download($url, sub {
      my ($body, $error) = shift;
      $respond->($error ? error($error) : json_res($body));
    });
  };
}

sub json_res {
  my $body = shift;

  [
    200,
    [
      'Content-Type', 'application/json',
      'Content-Length', length $body
    ],
    [$body]
  ];
}

sub error {
  my $message = shift;
  my $body = encode_json {error => ($message || "unknown error")};
  json_res $body;
}

sub _source_opts {
  my $self = shift;
  return map {$_ => $self->{$_}}
        grep {defined $self->{$_}}
             qw/maxwidth maxheight/;
}

sub register_provider {
  my ($self, $class) = @_;

  if ($class !~ s/^\+//) {
    $class = "Noembed::Source::$class";
  }

  my ($loaded, $error) = try_load_class($class);
  if ($loaded) {
    my $provider = $class->new($self->_source_opts);
    push @{ $self->{providers} }, $provider;
  }
  else {
    warn "Could not load provider $class: $error";
  }
}

1;