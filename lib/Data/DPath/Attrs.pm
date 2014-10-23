package Data::DPath::Attrs;

use strict;
use warnings;

use Class::XSAccessor # ::Array
    chained     => 1,
    constructor => 'new',
    accessors   => [qw( key )];

1;

__END__

=head1 NAME

Data::DPath::Attrs - Abstraction for internal attributes attached to a point

=head1 INTERNAL METHODS

=head2 new

Constructor.

=head2 key

Attribute / accessor.

The key actual hash key under which the point is located in case it's
the value of a hash entry.

=cut
