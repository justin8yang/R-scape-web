package Rscape::Controller::Download;
use Moose;
use namespace::autoclean;
use File::Slurp;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

Rscape::Controller::Download - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
  my ( $self, $c ) = @_;
  $c->res->redirect($c->uri_for($c->controller('Root')->action_for('index')));
  return;
}

sub tabed_results :Path :Args(1) {
  my ( $self, $c, $dir ) = @_;
  my $results_dir = $c->config->{'Model::Rscape'}->{dir_path} . '/' . $dir;

  if (!-e $results_dir) {
    $c->go('not_found');
  }

  $c->forward('read_results', [$results_dir]);

  $c->res->header('Content-Disposition' => "attachment; filename=results.txt");
  $c->res->content_type('text/plain');
  $c->response->body($c->stash->{out});
  return;
}

sub read_results : Private {
  my ($self, $c, $dir) = @_;

  my $decoder = Sereal::Decoder->new();
  my $encoded_meta = read_file("$dir/meta");

  my $meta = $decoder->decode($encoded_meta);

  my $name = $meta->{upload_name};
  $name =~ s/\.[^\.]*$//;

  my $out_path = $dir . '/' . $name . '.out';

  my $output_file = $out_path;

  if (-z $output_file) {
    $c->go('bad_input');
  }

  open my $output, '<', $out_path;

  while (<$output>) {
    next if $_ =~ /^#/;
    $c->stash->{out} .= $_;
  }

  return;
}

=head1 AUTHOR

Clements, Jody

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;