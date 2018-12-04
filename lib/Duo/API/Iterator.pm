package Duo::API::Iterator;

use Moose;

has 'generator' => ( is => 'ro', isa => 'CodeRef', required => 1 );

sub next {
    my ($self) = @_;
    return $self->generator->();
}

sub all {
    my ($self) = @_;
    my @items;
    my $item = $self->next();
    while (defined($item)) {
      push @items, $item;
      $item = $self->next();
    }

    return @items;
}

1;
