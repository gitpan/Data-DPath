package Data::DPath::Ops;

##
## some of this is copied from XML::Filter::Dispatcher::Ops
##  thanks to Barrie Slaymaker
##

use Carp qw( cluck confess );  ## NOT croak: this module must die "...\n".

use strict;

use vars ( 
    '$dispatcher',        ## The X::F::D that we're doing the parse for.
                          ## TODO: figure out where $dispatcher is defined
);

###############################################################################
##
## Boolean Singletons
##

## These are not used internally; 1 and 0 are.  These are used when passing
## boolean values in / out to Perl code, so they may be differentiated from
## numeric ones.
sub true()  { \"true"  }
sub false() { \"false" }

###############################################################################
##
## Helpers
##
sub _looks_numeric($)  { $_[0] =~ /^[ \t\r\n]*-?(?:\d+(?:\.\d+)?|\.\d+)[ \t\r\n]*$/ }

sub _looks_literal($)  { $_[0] =~ /^(?:'[^']*'|"[^"]*")(?!\n)\Z/       }

sub _indentomatic() { 1 }  ## Turning this off shaves a little parse time.
                           ## I leave it on for more readable error
                           ## messages, and it's key for debugging since
                           ## is so much more readable; in fact, messed
                           ## up indenting can indicate serious problems

sub _indent { Carp::confess "undef" unless defined $_[0]; $_[0] =~ s/^/  /mg; }

sub _is_rel_path($) {
    my $path = shift;

    return 0
        if $path->isa( "Data::DPath::PathTest" )
            && $path->isa( "Data::DPath::data_node" )                  ## /... paths
            && ! $path->isa( "Data::DPath::union" ); ## (a|b), union called this already.

    return 1;
}

###############################################################################
##
## Parse tree node base class
##
## This is used for all of the pieces of location paths axis tests, name
## and type tests, predicates.  It is also used by a few functions
## that act on the result of a location path (which is effectively a
## node set with just the current node in it).
##

sub new {
    my $class = shift;

    return bless [ @_ ],  $class;
}

sub op_type { ( my $type = ref shift ) =~ s/.*:// ; $type }

sub is_constant {
    my $self = shift;
    return ! grep ! $_->is_constant, @$self;
}

## fixup is called on a freshly parsed op tree just before it's
## compiled to do optimization and other conversions.
sub fixup {
    my $self = shift;
    my ( $context ) = @_;

    for ( @$self ) {
        if ( defined && UNIVERSAL::isa( $_, "Data::DPath::Op" ) ) {
            if ( ! $context->{BelowRoot}
                && ( $_->isa( "Data::DPath::Axis::child" )
                    || $_->isa( "Data::DPath::Axis::attribute" )
                    || $_->isa( "Data::DPath::Axis::start_element" )
                    || $_->isa( "Data::DPath::Axis::end_element" )
                    || $_->isa( "Data::DPath::Axis::end" )
                )
            ) {
                ## The miniature version of XPath used in
                ## XSLT's <template match=""> match expressions
                ## seems to me to behave like // was prepended if
                ## the expression begins with a child:: or
                ## attribute:: axis (or their abbreviations: no
                ## axis => child:: and @ => attribute::).
                my $op = Data::DPath::Axis::descendant_or_self->new;
                $op->set_next( $_ );
                $_ = $op;
                $op = Data::DPath::data_node->new;
                $op->set_next( $_ );
                $_ = $op;
            }

            ## This statement is why the descendant-or-self:: insertion
            ## is done in Op::fixup instead of Rule::fixup.  We want
            ## this transform to percolate down to the first op of each
            ## branch of these "grouping" ops.
            local $context->{BelowRoot} = 1
                unless $_->isa( "Data::DPath::Parens" )
                    || $_->isa( "Data::DPath::union" )
                    || $_->isa( "Data::DPath::Action" )
                    || $_->isa( "Data::DPath::Rule" );

            $_->fixup( @_ );
        }
    }

    return $self;
}

###############################################################################
##
## Numeric and String literals
##

@Data::DPath::NumericConstant::ISA = qw( Data::DPath::Op );
sub Data::DPath::NumericConstant::result_type   { "number" }
sub Data::DPath::NumericConstant::is_constant   { 1 }
sub Data::DPath::NumericConstant::as_immed_code { shift->[0] }

@Data::DPath::StringConstant::ISA = qw( Data::DPath::Op );
sub Data::DPath::StringConstant::result_type   { "string" }
sub Data::DPath::StringConstant::is_constant   { 1 }
sub Data::DPath::StringConstant::as_immed_code { 
    my $s = shift->[0];
    $s =~ s/([\\'])/\\$1/g;
    return join $s, "'", "'";
}

################################################################################
##
## Compile-time constant folding
##
## By tracking what values and expressions are constant, we can use
## eval "" to evaluate things at compile time.
##
sub _eval_at_compile_time {
    my ( $type, $code, $context ) = @_;

    return $code unless $context->{FoldConstants};

    my $out_code = eval $code;
    die "$@ in DPath compile-time execution of ($type) \"$code\"\n"
        if $@;

    ## Perl's bool ops ret. "" for F
    $out_code = "0"
        if $type eq "boolean" && !length $out_code;
    $out_code = $$out_code if ref $out_code;
    if ( $type eq "string" ) {
        $out_code =~ s/([\\'])/\\$1/g;
        $out_code = "'$out_code'";
    }

    #warn "compiled `$code` to `$out_code`";
    return $out_code;
}

###############################################################################
##
## PathTest base class
##
## This is used for all of the pieces of location paths axis tests, name
## and type tests, predicates.  It is also used by a few functions
## that act on the result of a location path (which is effectively a
## node set with just the current node in it).
##
@Data::DPath::PathTest::ISA = qw( Data::DPath::Op );

## TODO: factor some/all of this in to possible_event_types().
## That could die with an error if there are no possible event types.
## Hmmm, may also need to undo the oddness that a [] PossibleEventTypes
## means "any" (that's according to a comment, need to verify that
## the comment does not lie).

sub Data::DPath::PathTest::check_context {
    my $self = shift;
    my ( $context ) = @_;

    my $hash_name = ref( $self ) . "::AllowedAfterAxis";

    no strict "refs";
    die "'", $self->op_type, "' not allowed after '$context->{Axis}'\n"
        if keys %{$hash_name}
            && exists ${$hash_name}{$context->{Axis}};

    ## useful_event_contexts are the events that are useful for a path
    ## test to be applied to.  If the context does not have one of these
    ## in it's PossibleEventTypes, then it's a useless (never-match)
    ## expression.  For now, we die().  TODO: warn, but allow the
    ## warning to be silenced.

    if ( $self->can( "useful_event_contexts" )
        && defined $context->{PossibleEventTypes}
        && @{$context->{PossibleEventTypes}} ## empty list = "any".
    ) {
        my %possibles = map {
            ( $_ => undef );
        } @{$context->{PossibleEventTypes}};

        my @not_useful; my @useful;

        for ( $self->useful_event_contexts ) {
            exists $possibles{$_}
                ? push @useful, $_
                : push @not_useful, $_;
        }

#warn $context->{PossiblesSetBy}->op_type, "/", $self->op_type, " NOT USEFUL: ", join( ",", @not_useful ), "  (useful: ", join( ",", @useful ), ")\n" if @not_useful;
        die 
            $context->{PossiblesSetBy}->op_type,
            " (which can result in ",
            @{$context->{PossibleEventTypes}}
                ? join( ", ", @{$context->{PossibleEventTypes}} ) . (
                    @{$context->{PossibleEventTypes}} > 1
                        ? " event contexts"
                        : " event context"
                )
                : "any event context",
            ") followed by ",
            $self->op_type,
            " (which only match ",
            join( ", ", $self->useful_event_contexts ),
            " event types)",
            " can never match\n"
            unless @useful;
    }
}

sub Data::DPath::PathTest::new { shift->Data::DPath::Op::new( @_, undef ) }

sub Data::DPath::PathTest::is_constant { 0 }

sub Data::DPath::PathTest::result_type { "nodeset" }

sub _next() { -1 }

sub Data::DPath::PathTest::set_next {
    my $self = shift;
Carp::confess "undef!" unless defined $_[0];
    if ( $self->[_next] ) {
        # Unions cause this method to be called multiple times
        # and we never want to have a loop.
        return if $self          == $_[0];
        return if $self->[_next] == $_[0];
Carp::confess "_next ($self->[_next]) can't set_next" unless $self->[_next]->can( "set_next" );
        $self->[_next]->set_next( @_ );
    }
    else {
        $self->[_next] = shift;
    }
}

## child:: and descendant-or-self:: axes need to curry to child nodes.
## These tests are the appropriate tests for child nodes.
my %child_curry_tests = qw( start_element 1 comment 1 processing_instruction 1 characters 1 );

## No need for DataSubs in this array; we never curry to a data node event
## because data node events never occur inside other nodes.
my @all_curry_tests = qw( start_element comment processing_instruction characters attribute namespace );

## TODO: Detect when an axis tries to queue a curried test on to a particular
## FooSubs, and that test is incompatible with the axis.  Not sure how
## important that is, but I wanted to note it here for later thought.

sub Data::DPath::PathTest::curry_tests {
    ## we assume that there will *always* be a node test after an axis.
    ## This is a property of the grammar.
    my $self = shift;
    my $next = $self->[_next];
    Carp::confess "$self does not have a next" unless defined $next;
    return $next->curry_tests;
}



1;

__END__
