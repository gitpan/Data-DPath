package Data::DPath::Attrs;
BEGIN {
  $Data::DPath::Attrs::AUTHORITY = 'cpan:SCHWIGON';
}
{
  $Data::DPath::Attrs::VERSION = '0.45';
}
# ABSTRACT: Abstraction for internal attributes attached to a point

use strict;
use warnings;

use Class::XSAccessor # ::Array
    chained     => 1,
    constructor => 'new',
    accessors   => [qw( key )];

1;



=pod

=encoding utf-8

=head1 NAME

Data::DPath::Attrs - Abstraction for internal attributes attached to a point

=head1 INTERNAL METHODS

=head2 new

Constructor.

=head2 key

Attribute / accessor.

The key actual hash key under which the point is located in case it's
the value of a hash entry.

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

