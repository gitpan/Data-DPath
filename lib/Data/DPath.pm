package Data::DPath;

use strict;
use vars qw($VERSION $REVISION);

$VERSION = '0.00_01';

$Data::DPath::Namespaces = 0;  # = 1; in original XML::XPath
$Data::DPath::Debug = 0;  # set in test scripts

use Data::DPath::DataParser;
use Data::DPath::Parser;
use Data::DPath::Context;
use IO::File;
use Storable qw(nfreeze thaw);
use base qw(Class::Container);
use Params::Validate qw(:types);
use Data::Dumper;

__PACKAGE__->valid_params (
    path_parser => { isa => 'Data::DPath::Parser',     optional => 1, },
    data_parser => { isa => 'Data::DPath::DataParser', optional => 1, },
);

__PACKAGE__->contained_objects (
    path_parser => 'Data::DPath::Parser',
    data_parser => 'Data::DPath::DataParser',
);

# for testing
#use Data::Dumper;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my(%args);

    if ($#_ == 0) { # passed a scalar - let the data parser figure it out
        $args{'string'} = $_[0];
    }
    else {
        %args = (UNIVERSAL::isa($_[0], "HASH") ? %{$_[0]} : @_);
    }

    return $class -> SUPER::new(%args);
}

sub get_context { 
    my $self = shift;

    return $self -> {context} if defined $self -> {context};
    return Data::DPath::Context -> new(
        $self -> {data_parser} -> get_data
    );
}

sub set_context {
    my $self = shift;

    $self -> {context} = shift;
}

sub find {
    my $self = shift;
    my $path = shift;
    my $context = shift;
    die "No path to find" unless $path;

    $context = $self -> get_context unless defined $context;

    if(!defined $context) {
        # Still no context?   Need to parse...
        $context = $self -> {data_parser} -> parse;
        $self -> set_context($context);
#        warn "CONTEXT:\n", Data::Dumper->Dumpxs([$context], ['context']);
    }

    my $parsed_path = $self->{path_parser}->parse($path);

    return $parsed_path -> evaluate($context);
}

sub find {
    my($self, $path, $context) = @_;

    $context = $self -> get_context unless defined $context;

    my $expr = $self -> {path_parser} -> parse($path);

    return $expr -> evaluate($context);
}

sub findnodes {
    my($self, $path, $context) = @_;

    return $self -> find($path, $context);
}

1;

__END__

=head1 NAME

Data::DPath - Path based data manipulation

=head1 SYNOPSIS

 use Data::DPath;

 my $dp = Data::DPath -> new( apache => Apache::Request->new($r) );

 my $dataset = $dp -> find('//*[@isa="Apache::Upload"]'); # find all uploads

 foreach my $node ($dataset -> get_nodelist) {
     print "Found: ", $node -> data -> name,
              " as ", $node -> data -> filename, "\n";
 }

=head1 API

The API of Data::DPath is very similar to that of L<XML::XPath|XML::XPath>.

=head2 new()

=head2 dataset = find($path, [$context])

=head2 dataset = findnodes($path, [$context])

=head2 findnodes_as_string($path, [$context])

Returns the data found reproduces as XML using Data::XMLDumper.
The resulting XML may be used as the xml parameter to create a new 
Data::DPath object.

=head2 findvalue($path, [$context])

=head2 exists($path, [$context])

=head2 matches($node, $path, [$context])

=head2 getNodeText($path)

=head2 setNodeText($path, $value)

=head2 createNode($path)

=head1 Data Object Model

=head1 ACKNOWLEDGEMENTS

The Data::DPath package is based on XML::XPath.  I took the XML::XPath 
tarball and changed it into Data::DPath, for the most part.

=head1 AUTHOR

James G. Smith, <jsmith@cpan.org>
 
=head1 COPYRIGHT
 
Copyright (C) 2003   Texas A&M University.  All Rights Reserved
 
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

