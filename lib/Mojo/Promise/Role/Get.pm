package Mojo::Promise::Role::Get;

use Carp ();
use Role::Tiny;

our $VERSION = 'v0.1.0';

requires qw(ioloop then wait);

sub get {
  my ($self) = @_;
  Carp::croak "'get' cannot be called when the event loop is running" if $self->ioloop->is_running;
  my (@result, $is_error);
  $self->then(sub { @result = @_ }, sub { $is_error = 1; @result = @_ })->wait;
  if ($is_error) {
    my $exception = $result[0];
    Carp::croak $exception unless ref $exception or $exception =~ m/\n$/;
    die $exception;
  }
  return @result[0..$#result]; # be slightly more sensible in scalar context
}

1;

=head1 NAME

Mojo::Promise::Role::Get - Wait for the results of a Mojo::Promise

=head1 SYNOPSIS

  use Mojo::IOLoop;
  use Mojo::Promise;
  use Mojo::UserAgent;
  my $ua = Mojo::UserAgent->new;

  # long way of writing $ua->get('http://example.com')
  my ($tx) = $ua->get_p('http://example.com')->with_roles('+Get')->get;

  # wait for multiple requests at once
  my @txs = map { $_->[0] } Mojo::Promise->all($ua->get_p('http://example.com'),
    $ua->get_p('https://www.google.com'))->with_roles('+Get')->get;

  # request with exception on timeout
  my $timeout = Mojo::Promise->new;
  Mojo::IOLoop->timer(1 => sub { $timeout->reject('Timed out!') });
  my ($tx) = Mojo::Promise->race($ua->get_p('http://example.com'), $timeout)
    ->with_roles('Mojo::Promise::Role::Get')->get;

=head1 DESCRIPTION

L<Mojo::Promise::Role::Get> is a L<Mojo::Promise> L<role|Role::Tiny> which adds
a L</"get"> method that facilitates the usage of asynchronous code in a
synchronous manner, similar to L<Future/"get">.

=head1 METHODS

L<Mojo::Promise::Role::Get> composes the following methods.

=head2 get

  my ($result) = $promise->get;
  my @results = $promise->get;

Blocks until the promise resolves or is rejected. If it is fulfilled, the
results are returned as a list. The return value is not guaranteed to be
suitable in scalar context. If it is rejected, the rejection reason is thrown
as an exception.

An exception is thrown if the L<Mojo::Promise/"ioloop"> is running, to prevent
recursing into the event reactor.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Future>