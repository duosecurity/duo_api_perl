package Duo::API::Iterator;

our $VERSION = '1.1';

=head1 NAME

Duo::API::Iterator

=head1 SYNOPSIS

    use Duo::API::Iterator;
    my @items = (5, 4, 3, 2, 1);
    my $generator = sub {
        return shift @items;
    };
    my $iter = Duo::API::Iterator(generator => $generator);

    my $first_item = $iter->next(); # 5
    my @remaining = $iter->all();   # (4, 3, 2, 1)

=head1 DESCRIPTION

An iterator to be used by the C<Duo::API> client for paginated requests.

=head1 METHODS

=over 4

=item new(%params)

Provides a new instace of C<Duo::API::Iterator>.

=over 4

=item Parameters:

=over 4

=item * generator B<required>

A subroutine reference which produces one item of a sequence upon each call. The
generator must indicate the last item has already been provided by returning
C<undef>.

=back

=item Returns:

C<Duo::API::Iterator>

=back

=item next()

Returns: the next item provided by the generator.

=item all()

Returns: a list of all remaining items not yet returned by the generator.

=back

=cut

use Moo;
use Carp qw(croak);
use Scalar::Util qw(reftype);

has 'generator' => (
    is => 'ro',
    isa => sub {
        my $input = shift;
        croak "The generator parameter must be a subroutine references."
            unless reftype($input) eq 'CODE' 
    },
    required => 1
);

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
