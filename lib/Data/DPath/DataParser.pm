package Data::DPath::DataParser;

use base Class::Container;
use Params::Validate qw(:types);
use Carp qw(croak carp);
use Storable ();

__PACKAGE__->valid_params (
    filename    => { type => SCALAR,                   optional => 1, },
    xml         => { type => SCALAR,                   optional => 1, },
    ioref       => { type => GLOB,                     optional => 1, },
    context     => { isa => 'Data::DPath::Node',       optional => 1, },
    hash        => { type => HASHREF,                  optional => 1, },
    apache      => { isa => 'Apache::Request',         optional => 1, },
    cgi         => { isa => 'CGI',                     optional => 1, },
    storable    => { isa => SCALAR,                    optional => 1, },
    xml_dumper_preference => { isa => SCALAR,          optional => 1, },
    separator   => { type => SCALAR,  default => '.', },
);

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self = $class -> SUPER::new(@_);

    # figure out XML dumper preference
    $self -> {_has_xml_dumper} = 1 if $ISA{'XML/Dumper.pm'};
    $self -> {_has_data_dumpxml} = 1 if $ISA{'Data/DumpXML.pm'};

    $self->{xml_dumper_preference} ||= 
         $self -> {_has_data_dumpxml} ? 'Data::DumpXML' :
         $self -> {_has_xml_dumper}   ? 'XML::Dumper' :
                                        undef ;

    return $self;
}

sub parse {  # allows delayed parsing
    my $self = shift;

    unless(defined $self -> {_data}) {
        # parse all the applicable data sources and merge them
        my $method;
        foreach my $src (sort keys %$self) { # sort so order is well-defined
            next if $src =~ m{^_};
            next unless defined $self -> {$src};
            next unless $method = $self -> can("data_from_$src");
            $self -> _merge_hash($self -> $method);
        }
    }
    return $self -> {_data};
}

sub set_separator {
    my $self = shift;
    my $s = $self -> {separator};
    $self -> {separator} = shift if @_;
    return $s;
}

sub get_separator { shift -> {separator}; }

sub get_data {
    my $self = shift;

    my($data, $context);

    return unless defined wantarray;

    if(@_) {
        if(UNIVERSAL::isa($_[0], 'HASH')) {
            ($data, $context) = @_;
        }
    }
    else {
        $data = $self -> parse;
    }

    if(wantarray) {
        return ($data, $context);
    }
    else {
        return $data;
    }
}

sub data_from_context {
    my $self = shift;

    return { } unless defined $self -> {context};

    return $self -> {context} -> get_data;
}

sub get_context {
    my $self = shift;

    if(@_) {
        my($data, $context) = $self -> get_data;

        # TODO: allow context spec
        return ; #something
    }
    else {
        return $self -> {context};
    }
}

sub data_from_storable {
    my $self = shift;

    return { } unless defined $self -> {storable};

    my $hash;

    eval { $hash = Storable::thaw($self -> {storable}); 1; }
        or croak "Unable to thaw storable data: $@";

    return $hash;
}

sub get_storable {
    my $self = shift;

    if(@_) {
        my $data = shift || $self -> {_data};

        # TODO: allow context spec

        return Storable::nfreeze($data);
    }
    else {
        return $self -> {storable};
    }
}

sub data_from_xml {
    my $self = shift;

    return { } unless defined $self -> {xml};

    if( $self -> {xml} =~ m{^\s*<\s*([^>]*:)?data\b} ) {
        eval { require Data::DumpXML::Parser; 1; }
            or croak "Unable to load Data::DumpXML::Parser module";
        my $p = Data::DumpXML::Parser->new;
        return $p -> parsestring($self -> {xml});
    }

    if( $self -> {xml} =~ m{^\s*<\s*([^>]*:)?perldata\b} ) {
        eval { require XML::Dumper; 1; }
            or croak "Unable to load XML::Dumper module";

        my $p = new XML::Dumper;
        return $p -> xml2pl($self -> {xml});
    }

    croak "Unknown XML schema";
}

sub get_xml {
    my $self = shift;

    if(@_) {
        my $data = shift || $self -> {_data};

        for($self -> {xml_dumper_preference}) {
            /^XML::Dumper$/ && do {
                eval { require XML::Dumper; 1; }
                    or croak "Unable to load XML::Dumper module";
                return XML::Dumper -> new -> pl2xml($data);
            };
            /^Data::DumpXML$/ && do {
                eval { require Data::DumpXML; 1; }
                    or croak "Unable to load Data::DumpXML module";
                return Data::DumpXML::dump_xml($data);
            };
            croak "Unable to use $_ to dump XML";
        }
    }
    else {
        return $self -> {xml};
    }
}

sub data_from_apache {
    my $self = shift;

    return { } unless defined $self -> {apache};

    my $hash = { };

    my $table = $self -> {apache} -> parms;

    $hash = $self -> expand_hash($table);

    for(my $upload = $self -> {apache} -> upload; $upload; $upload = $upload -> next) {
        my @bits = split($self -> get_separator, $upload -> name);
        my $ctx = $hash;
        while(@bits > 1) {
            my $bit = shift @bits;
            $ctx -> {$bit} ||= { };
            $ctx = $ctx -> {$bit};
        }
        $ctx -> {$bits[0]} = $upload;
    }

    return $hash;
}

sub get_apache {
    my $self = shift;

    if(@_) {
        # need to flatten_hash($data) at some point
    }
    else {
        return $self -> {apache};
    }
}

sub data_from_cgi {
    my $self = shift;

    return { } unless defined $self -> {cgi};

    my $cgi_hash = $self -> {cgi} -> Vars;
    # now process packed multi-values
    foreach my $k (keys %$cgi_hash) {
        my @values = split(/\x0/, $cgi_hash->{$k});
        if(@values > 1) {
            $cgi_hash -> {$k} = \@values;
        }
        else {
            $cgi_hash -> {$k} = $values[0];
        }
    }

    return $self -> expand_hash($cgi_hash);
}

sub get_cgi {
    my $self = shift;

    eval { require CGI; 1; }
        or croak "Unable to load CGI module";

    if(@_) {
        my $data = shift || $self -> {_data};

        # TODO: allow context spec

        return CGI -> new( $self -> flatten_hash($data) );
    }
    else {
        return $self -> {cgi};
    }
}

sub data_from_hash {
    my $self = shift;

    return { } unless defined $self -> {hash};

    return $self -> {hash};
}

sub get_hash {
    my $self = shift;

    if(@_) {
        my $data = shift || $self -> {_data};

        # TODO: allow context spec

        return Storable::dclone($data);
    }
    else {
        return Storable::dclone($self -> {hash});
    }
}

sub data_from_ioref { # read string and try to figure it out
    my $self = shift;

    return { } unless defined $self -> {ioref};

    local($/);
    my $ioref = $self -> {ioref};

    my $string = <$ioref>;

    return $self -> data_from_string($string);
}

sub get_ioref {
    my $self = shift;

    if(@_) {
        my $data = shift || $self -> {_data};

        # return IO::String of XML data
    }
    else {
        return $self -> {ioref};
    }
}

sub data_from_string {
    my $self = shift;

    return { } if !@_ && !defined $self -> {string};

    my $data = @_ ? shift : $self -> {string};

    
}

###
### helper methods
###

sub flatten_hash {
    my($self, $hash) = @_;

    my $ret = { };

    foreach my $k ( keys %$hash ) {
        if(ref($hash -> {$k}) =~ m{[a-z].*\(}) { # don't flatten objects
            $ret -> {$k} = $hash -> {$k};
        }
        elsif(UNIVERSAL::isa($hash->{$k}, 'HASH')) {
            my $thash = $self -> flatten_hash($hash -> {$k});
            @{$ret}{map { join($self -> get_separator, $k, $_) } keys %$thash} = values %$thash;
        }
        else { # don't flatten scalars, globrefs, or arrays
            $ret->{$k} = $hash -> {$k};
        }
    }

    return $ret;
}

sub expand_hash {
    my($self, $hash) = @_;

    my $ret = { };

    while(my($k, $v) = each %$hash) {
        my @bits = split($self -> get_separator, $k);
        my $ctx = $ret;
        while(@bits > 1) {
            my $bit = shift @bits;
            $ctx -> {$bit} ||= { };
            $ctx = $ctx -> {$bit};
        }
        if(defined $ctx -> {$bits[0]}) {
            $ctx -> {$bits[0]} = [ $ctx -> {$bits[0]} ] unless UNIVERSAL::isa($ctx -> {$bits[0]}, 'ARRAY');
            push @{$ctx -> {$bits[0]}}, $v;
        }
        else {
            $ctx -> {$bits[0]} = $v;
        }
    }

    return $ret;
}

sub _merge_hash {
    my $self = shift;

    my $target;
    if(@_ > 1) {
        $target = shift;
    }
    else {
        $target = ($self -> {_data} ||= { });
    }

    my $data = shift;

    foreach my $k (keys %$data) {
        if(ref($data -> {$k}) =~ m{[a-z].*\(}) {  # need to use a real function :/
            # should be able to handle tied hashes and arrays
            $target -> {$k} = $data -> {$k};
        }
        elsif(UNIVERSAL::isa($data -> {$k}, 'HASH')) {
            $target -> {$k} = { } 
                unless UNIVERSAL::isa($target -> {$k}, 'HASH') 
                    && !blessed($target -> {$k});

            $self -> _merge_hash($target -> {$k}, $data -> {$k});
        }
        elsif(defined $target -> {$k}) {
            $target -> {$k} = [ $target -> {$k} ] unless UNIVERSAL::isa($target -> {$k}, 'ARRAY');
            if(UNIVERSAL::isa($data -> {$k}, 'ARRAY')) {
                push @{$target -> {$k}}, @{Storable::dclone($data -> {$k})};
            }
            else {
                push @{$target -> {$k}}, ref($data -> {$k}) ? Storable::dclone($data -> {$k}) : $data -> {$k};
            }
        }
        else {
            $target -> {$k} = ref($data -> {$k}) ? Storable::dclone($data -> {$k}) : $data -> {$k};
        }
    }
}

1;

__END__

=head1 NAME

Data::DPath::DataParser - data parser for Data::DPath

=head1 SYNOPSIS

 use Data::DPath::DataParser;

 my $data = new Data::DPath::DataParser
                apache => $r,
                separator => '/',
            ;

 my $data = new Data::DPath::DataParser
                cgi => $cgi,
            ;
 my $cgi = $data -> get_cgi;

=head1 DESCRIPTION

Data::DPath::DataParser manages data extraction from various sources 
into a common hash tree that is then used by L<Data::DPath|Data::DPath>.

The following data sources are supported.

=over 4

=item apache

This is an L<Apache::Request|Apache::Request> object.  Data::DPath::DataParser 
will extract all parameters and file upload objects.  Parameter names 
will be split on the separator.  Names with multiple parts are placed 
in nested hashes.  For example, data associated with the name C<foo.bar> 
will be placed in C<$data -E<gt> {foo} -E<gt> {bar}> if C<.> is the separator.

=item cgi

This is a L<CGI|CGI> object.

=item context

=item filename

=item hash

This should be a regular Perl hash reference.  The contents will not 
be modified by Data::DPath.

=item ioref

This is a IO::File object from which a string may be read.  The string 
should be an XML string or the result of freezing a hash by 
L<Storable|Storable>.

=item storable

This is a string that has been frozen by L<Storable|Storable>.

=item xml

This is an XML string.  If the root element is <data/>, then it is 
parsed with the L<Data::DumpXML|Data::DumpXML> module.  Otherwise, it 
is parsed with the L<XML::Dumper|XML::Dumper> module.

=back 4

In addition to the data sources, the following parameters may be specified.

=over 4

=item separator

This is the separator used to break parameter names into shorter 
sequences to create nested hashes.  The default value is the period (C<.>).
It may be changed at any time with the C<set_separator> method.  It 
may be retrieved with the C<get_separator> method.

=item xml_dumper_preference

This should be one of the module names listed below.
The default depends on which modules are already loaded when the 
Data::DPath::DataParser object is created.  Preference is given to 
L<Data::DumpXML|Data::DumpXML> if both are loaded.

=over 4

=item L<Data::DumpXML|Data::DumpXML>

=item L<XML::Dumper|XML::Dumper>

=back 4

=back 4

=head1 ADDING SOURCES

To add a data source, use the following template.

 package My::DataParser;

 use base Data::DPath::DataParser;
 use Params::Validate qw(:types);

 # Some_Type should be whatever type is expected by data_from_foo
 __PACKAGE__->valid_params (
     foo    => { type => Some_Type, optional => 1, },
 ); 

 sub data_from_foo {
     my $self = shift;
    
     return { } unless defined $self -> {foo};
    
     # return a hash representing the data in $self -> {foo}
 }

 sub get_foo {
     my $self = shift;

     if(@_) {   
         my $data = shift || $self -> {_data};
 
         # return whatever can be fed back in to get $data
         # using the `foo' parameter in the data_from_foo
         # method above.
         return Foo -> new( $self -> flatten_hash($data) );
     }
     else {
         return $self -> {foo};
     }
 }

 1;

 __END__
