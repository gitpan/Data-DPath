package Data::DPath::Context;

use strict;
use warnings;

use Data::Dumper;
use aliased 'Data::DPath::Point';
use List::MoreUtils 'uniq';
use Scalar::Util 'reftype';
use Data::DPath::Filters;

# print "use $]\n" if $] >= 5.010; # allow new-school Perl inside filter expressions
# eval "use $]" if $] >= 5.010; # allow new-school Perl inside filter expressions

use Class::XSAccessor::Array
    chained     => 1,
    constructor => 'new',
    accessors   => {
                    current_points  => 0,
                    give_references => 1,
                   };

use constant { HASH     => 'HASH',
               ARRAY    => 'ARRAY',
               SCALAR   => 'SCALAR',
               ROOT     => 'ROOT',
               ANYWHERE => 'ANYWHERE',
               KEY      => 'KEY',
               ANYSTEP  => 'ANYSTEP',
               NOSTEP   => 'NOSTEP',
               PARENT   => 'PARENT',
           };

# only finds "inner" values; if you need the outer start value
# then just wrap it into one more level of array brackets.
sub _any
{
        my ($out, $in, $lookahead_key) = @_;

        no warnings 'uninitialized';
        #print "    in: ", Dumper($in);
        #sleep 3;

        $in = defined $in ? $in : [];
        return @$out unless @$in;

        my @newin;
        my @newout;
        my $ref;
        my $reftype;

        foreach my $point (@$in) {
                my @values;
                my $ref = $point->ref;

                # speed optimization: first try faster ref, then reftype
                if (ref($$ref) eq HASH or reftype($$ref) eq HASH) {
                        @values =
                            grep {
                                    # speed optimization: only consider a key if lookahead looks promising
                                    not defined $lookahead_key
                                    or $_->{key} eq $lookahead_key
                                    or ($ref = ref($_->{val}))         eq HASH
                                    or $ref                            eq ARRAY
                                    # XXX: it's unclear why just testing ref is good enough
                                    # or ($reftype = reftype($_->{val})) eq HASH
                                    # or $reftype                        eq ARRAY
                            } map { { val => $$ref->{$_}, key => $_ } }
                                keys %{$$ref};
                }
                elsif (ref($$ref) eq ARRAY or reftype($$ref) eq ARRAY) {
                        @values = map { { val => $_ } } @{$$ref}
                }
                else {
                        next
                }

                foreach (@values)
                {
                        my $key = $_->{key};
                        my $val = $_->{val};
                        my $newpoint = Point->new->ref(\$val)->parent($point);
                        $newpoint->attrs({ key => $key }) if $key;
                        push @newout, $newpoint;
                        push @newin, Point->new->ref(\$val)->parent($point);
                }
        }
        push @$out, @newout;
        return _any ($out, \@newin, $lookahead_key);
}

sub all {
        my ($self) = @_;

        no strict 'refs';
        no warnings 'uninitialized';

        return
            map { $self->give_references ? $_ : $$_ }
                uniq
                    map {
                         defined $_ ? $_->ref : ()
                        } @{$self->current_points};
}

# filter current results by array index
sub _filter_points_index {
        my ($self, $index, $points) = @_;

        return $points ? [$points->[$index]] : [];
}

# filter current results by condition
sub _filter_points_eval
{
        my ($self, $filter, $points) = @_;

        return [] unless @$points;
        return $points unless defined $filter;

        #print STDERR "_filter_points_eval: $filter | ".Dumper([ map { $_->ref } @$points ]);
        my $new_points;
        my $res;
        {
                package Data::DPath::Filters;

                local our $idx = 0;
                $new_points = [
                               grep {
                                       local our $p = $_;
                                       local $_;
                                       my $pref = $p->ref;
                                       if ( defined $pref ) {
                                               $_ = $$pref;
                                               # 'uninitialized' values are the norm
                                               no warnings 'uninitialized';
                                               $res = eval $filter;
                                               print STDERR ($@, "\n") if $@;
                                       } else {
                                               $res = 0;
                                       }
                                       $idx++;
                                       $res;
                               } @$points
                              ];
        }
        return $new_points;
}

sub _filter_points {
        my ($self, $step, $points) = @_;

        no strict 'refs';
        no warnings 'uninitialized';

        return [] unless @$points;

        my $filter = $step->filter;
        return $points unless defined $filter;

        $filter =~ s/^\[\s*(.*?)\s*\]$/$1/; # strip brackets and whitespace

        if ($filter =~ /^-?\d+$/)
        {
                # print "INT Filter: $filter <-- ".Dumper(\(map { $_ ? $_->ref : () } @$points));
                return $self->_filter_points_index($filter, $points); # simple array index
        }
        elsif ($filter =~ /\S/)
        {
                #print "EVAL Filter: $filter, ".Dumper(\(map {$_->ref} @$points));
                return $self->_filter_points_eval($filter, $points); # full condition
        }
        else
        {
                return $points;
        }
}

sub search
{
        my ($self, $path) = @_;

        no strict 'refs';
        no warnings 'uninitialized';

        my $current_points = $self->current_points;
        my $steps = $path->_steps;
        for (my $i = 0; $i < @$steps; $i++) {
                my $step = $steps->[$i];
                my $lookahead = $steps->[$i+1];
                my $new_points = [];
                # print STDERR "+++ step.kind: ", Dumper($step);
                if ($step->kind eq ROOT)
                {
                        # the root node
                        # (only makes sense at first step, but currently not asserted)
                        my $step_points = $self->_filter_points($step, $current_points);
                        push @$new_points, @$step_points;
                }
                elsif ($step->kind eq ANYWHERE)
                {
                        # speed optimization: only useful points added
                        my $lookahead_key;
                        if (defined $lookahead and $lookahead->kind eq KEY) {
                                $lookahead_key = $lookahead->part;
                        }

                        # '//'
                        # all hash/array nodes of a data structure
                        foreach my $point (@$current_points) {
                                my $step_points = [_any([], [ $point ], $lookahead_key), $point];
                                push @$new_points, @{$self->_filter_points($step, $step_points)};
                        }
                }
                elsif ($step->kind eq KEY)
                {
                        # the value of a key
                        # print STDERR " * current_points: ", Dumper($current_points);
                        foreach my $point (@$current_points) {
                                no warnings 'uninitialized';
                                next unless defined $point;
                                my $pref = $point->ref;
                                # print STDERR "point: ", Dumper($point);
                                # print STDERR "point.ref: ", Dumper($point->ref);
                                # print STDERR "deref point.ref: ", Dumper(${$point->ref});
                                # print STDERR "reftype deref point.ref: ", Dumper(ref ${$point->ref});
                                next unless (defined $point && (
                                                                # speed optimization:
                                                                # first try faster ref, then reftype
                                                                ref($$pref)     eq HASH or
                                                                reftype($$pref) eq HASH
                                                               ));
                                # take point as hash, skip undefs
                                my $attrs = { key => $step->part };
                                my $step_points = [ map {
                                                         Point
                                                         ->new
                                                         ->ref(\$_)
                                                         ->parent($point)
                                                         ->attrs($attrs)
                                                        } ( $$pref->{$step->part} || () ) ];
                                push @$new_points, @{$self->_filter_points($step, $step_points)};
                        }
                }
                elsif ($step->kind eq ANYSTEP)
                {
                        # '*'
                        # all leaves of a data tree
                        foreach my $point (@$current_points) {
                                # take point as array
                                my $pref = $point->ref;
                                my $ref = $$pref;
                                my $step_points = [];
                                # speed optimization: first try faster ref, then reftype
                                if (ref($ref) eq HASH or reftype($ref) eq HASH)
                                {
                                        $step_points = [ map {
                                                              my $v     = $ref->{$_};
                                                              my $attrs = { key => $_ };
                                                              Point->new->ref(\$v)->parent($point)->attrs($attrs)
                                                             } keys %$ref ];
                                }
                                elsif (ref($ref) eq ARRAY or reftype($ref) eq ARRAY)
                                {
                                        $step_points = [ map {
                                                              Point->new->ref(\$_)->parent($point)
                                                             } @$ref ];
                                }
                                else
                                {
                                        if (ref($pref) eq SCALAR or reftype($pref) eq SCALAR) {
                                                # TODO: without map, it's just one value
                                                $step_points = [ map {
                                                                      Point->new->ref(\$_)->parent($point)
                                                                     } $ref ];
                                        }
                                }
                                push @$new_points, @{ $self->_filter_points($step, $step_points) };
                        }
                }
                elsif ($step->kind eq NOSTEP)
                {
                        # '.'
                        # no step (neither up nor down), just allow filtering
                        foreach my $point (@{$current_points}) {
                                my $step_points = [$point];
                                push @$new_points, @{ $self->_filter_points($step, $step_points) };
                        }
                }
                elsif ($step->kind eq PARENT)
                {
                        # '..'
                        # the parent
                        foreach my $point (@{$current_points}) {
                                my $step_points = [$point->parent];
                                push @$new_points, @{ $self->_filter_points($step, $step_points) };
                        }
                }
                $current_points = $new_points;
        }
        $self->current_points( $current_points );
        return $self;
}

sub match {
        my ($self, $path) = @_;

        $self->search($path)->all;
}

1;

__END__

=head1 NAME

Data::DPath::Context - Abstraction for a current context that enables incremental searches.

=head1 API METHODS

=head2 new ( %args )

Constructor; creates instance.

Args:

=over 4

=item give_references

Default 0. If set to true value then results are references to the
matched points in the data structure.

=back

=head2 all

Returns all values covered by current context.

If C<give_references> is set to true value then results are references
to the matched points in the data structure.

=head2 search( $path )

Return new context with path relative to current context.

=head2 match( $path )

Same as C<< search($path)->all() >>;

=head1 UTILITY SUBS/METHODS

=head2 _filter_points

Evaluates the filter condition in brackets. It differenciates between
simple integers, which are taken as array index, and all other
conditions, which are taken as evaled perl expression in a grep like
expression onto the set of points found by current step.

=head2 current_points

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
