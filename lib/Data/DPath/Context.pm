package Data::DPath::Context;

use Data::DPath::Node::Element;

our @ISA = qw(Data::DPath::Node::Element);

sub new {
    my $class = shift;
    my $data = shift;
    return $class -> SUPER::new(undef, \$data);
}

package Data::DPath::ContextImpl;

our @ISA = qw(Data::DPath::Node::ElementImpl);

1;
