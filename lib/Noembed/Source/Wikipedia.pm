package Noembed::Source::Wikipedia;

use Web::Scraper;
use JSON;

use parent 'Noembed::Source';

my $re = qr{http://[^\.]+\.wikipedia\.org/wiki/.*}i;

sub prepare_source {
  my $self = shift;

  my $self->{scraper} = scraper {
    process "#firstHeading", title => 'TEXT';
    process "#bodyContent p:first-child", html => 'HTML';
  };
}

sub request_url {
  my ($self, $url) = @_;

  return $url;
}

sub filter {
  my ($self, $body) = @_;

  my $res = $self->{scraper}->scrape($body);
  return $res;
}

sub matches {
  my ($self, $url) = @_;
  return $url =~ $self->{pattern};
}

1;