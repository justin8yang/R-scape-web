package RNACOV::Controller::Results;
use Moose;
use namespace::autoclean;
use File::Slurp;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

RNACOV::Controller::Results - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
  my ( $self, $c ) = @_;
  #process and redirect to results
  $c->forward('process');
}

sub results : Path : Args(1) {
  my ( $self, $c, $dir ) = @_;

  # validate dir here.

  $c->stash->{tmp_id} = $dir;
  my $results_dir = $c->config->{'Model::RNACOV'}->{dir_path} . '/' . $dir;

  if (!-e $results_dir) {
    $c->go('not_found');
  }

  $c->forward('read_results', [$results_dir]);

  return;
}

sub r2r_image : Path : Args(2) {
  my ($self, $c, $dir) = @_;
  my $results_dir = $c->config->{'Model::RNACOV'}->{dir_path} . '/' . $dir;
  $c->res->content_type('image/svg+xml');
  my $contents = read_file($results_dir . '/query.R2R.sto.svg');
  $c->res->body($contents);
  return;
}

sub dot_plot : Path : Args(3) {
  my ($self, $c, $dir) = @_;
  my $results_dir = $c->config->{'Model::RNACOV'}->{dir_path} . '/' . $dir;
  $c->res->content_type('image/svg+xml');
  my $contents = read_file($results_dir . '/query.dplot.svg');
  $c->res->body($contents);
  return;
}


sub process : Private {
  my ($self, $c) = @_;
  my $tmp_id = undef;
  eval {
    $tmp_id = $c->model('RNACOV')->run($c->req->upload('stofile'));
  };
  if ($tmp_id) {
    $c->response->redirect($c->uri_for('/results/' . $tmp_id));
  }
  return;
}

sub read_results : Private {
  my ($self, $c, $dir) = @_;

  open my $output, '<', $dir . '/query.out';

  while (<$output>) {
    next if $_ =~ /^#/;
    warn $_;
    my @line = split /\t/, $_;
    use DDP; p @line;
    push @{$c->stash->{out_file}}, [$line[0], $line[1], $line[2]];
  }

  return;
}

sub not_found : Private {
  my ($self, $c) = @_;
  $c->stash->{template} = 'not_found.tt';
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