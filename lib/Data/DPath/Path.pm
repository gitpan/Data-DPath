package Data::DPath::Path;

use strict;
use warnings;

use Data::Dumper;
use aliased 'Data::DPath::Step';
use aliased 'Data::DPath::Point';
use aliased 'Data::DPath::Context';
use Text::Balanced 'extract_delimited', 'extract_codeblock';

use Class::XSAccessor
    chained     => 1,
    accessors   => {
                    path            => 'path',
                    _steps          => '_steps',
                    give_references => 'give_references',
                   };

use constant { ROOT     => 'ROOT',
               ANYWHERE => 'ANYWHERE',
               KEY      => 'KEY',
               ANYSTEP  => 'ANYSTEP',
               NOSTEP   => 'NOSTEP',
               PARENT   => 'PARENT',
           };

sub new {
        my $class = shift;
        my $self  = bless { @_ }, $class;
        $self->_build__steps;
        return $self;
}

sub unescape {
        my ($str) = @_;

        return unless defined $str;
        $str =~ s/(?<!\\)\\(["'])/$1/g; # '"$
        $str =~ s/\\{2}/\\/g;
        return $str;
}

sub unquote {
        my ($str) = @_;
        $str =~ s/^"(.*)"$/$1/g;
        return $str;
}

sub quoted { shift =~ m,^/["'],; }                                             # "

eval 'use overload "~~" => \&op_match' if $] >= 5.010;

sub op_match {
        my ($self, $data, $rhs) = @_;

        return [ $self->match( $data ) ];
}

# essentially the Path parser
sub _build__steps {
        my ($self) = @_;

        my $remaining_path = $self->path;
        my $extracted;
        my @steps;

        push @steps, Step->new->part('')->kind(ROOT);

        while ($remaining_path) {
                my $plain_part;
                my $filter;
                my $kind;
                if ( quoted($remaining_path) ) {
                        ($plain_part, $remaining_path) = extract_delimited($remaining_path, q/'"/, "/"); # '
                        ($filter,     $remaining_path) = extract_codeblock($remaining_path, "[]");
                        $plain_part                    = unescape unquote $plain_part;
                        $kind                          = KEY; # quoted is always a key
                }
                else
                {
                        my $filter_already_extracted = 0;
                        ($extracted, $remaining_path) = extract_delimited($remaining_path,'/');

                        if (not $extracted) {
                                ($extracted, $remaining_path) = ($remaining_path, undef); # END OF PATH
                        } else {

                                # work around to recognize slashes in filter expressions and handle them:
                                #
                                # - 1) see if key unexpectedly contains opening "[" but no closing "]"
                                # - 2) use the part before "["
                                # - 3) unshift the rest to remaining
                                # - 4) extract_codeblock() explicitely
                                if ($extracted =~ /(.*)((?<!\\)\[.*)/ and $extracted !~ m|\]/\s*$|) {
                                        $remaining_path =  $2 . $remaining_path;
                                        ( $plain_part   =  $1 ) =~ s|^/||;
                                        ($filter, $remaining_path) = extract_codeblock($remaining_path, "[]");
                                        $filter_already_extracted = 1;
                                } else {
                                        $remaining_path = (chop $extracted) . $remaining_path;
                                }
                        }

                        ($plain_part, $filter) = $extracted =~ m,^/              # leading /
                                                                 (.*?)           # path part
                                                                 (\[.*\])?$      # optional filter
                                                                ,xg unless $filter_already_extracted;
                        $plain_part = unescape $plain_part;
                }

                if    ($plain_part eq '')   { $kind ||= ANYWHERE }
                elsif ($plain_part eq '*')  { $kind ||= ANYSTEP  }
                elsif ($plain_part eq '.')  { $kind ||= NOSTEP   }
                elsif ($plain_part eq '..') { $kind ||= PARENT   }
                else                        { $kind ||= KEY      }

                push @steps, Step->new->part($plain_part)->kind($kind)->filter($filter);
        }
        pop @steps if $steps[-1]->kind eq ANYWHERE; # ignore final '/'
        $self->_steps( \@steps );
}

sub match {
        my ($self, $data) = @_;

        my $context = Context
            ->new
                ->current_points([ Point->new->ref(\$data) ])
                    ->give_references($self->give_references);
        return $context->match($self);
}

1;

__END__

=head1 NAME

Data::DPath::Path - Abstraction for a DPath.

Take a string description, parse it, provide frontend methods.

=head1 PUBLIC METHODS

=head2 new ( %args )

Constructor; creates instance.

Args:

=over 4

=item give_references

Default 0. If set to true value then results are references to the
matched points in the data structure.

=back

=head2 match( $data )

Returns an array of all values in C<$data> that match the Path object.

=head1 INTERNAL METHODS

=head2 op_match( $self, $data )

This sub/method is bound as the overloading function for C<~~>.

=head2 quoted

Checks whether a path part starts with quotes.

=head2 unquote

Removes surrounding quotes.

=head2 unescape

Converts backslashed characters into their non-backslashed form.

=head2 _build__steps

This method is essentially the DPath parser as it tokenizes the path
into single steps whose later execution is the base functionality of
the whole DPath module.

=head2 path

Attribute / accessor.

=head2 _steps

Attribute / accessor.

=head2 give_references

Attribute / accessor.

=head1 AUTHOR

Steffen Schwigon, C<< <schwigon at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008,2009 Steffen Schwigon.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
