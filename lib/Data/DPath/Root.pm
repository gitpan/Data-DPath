package Data::DPath::Root;
use strict;
use Data::DPath::DataParser;
use Data::DPath::NodeSet;

sub new {
	my $class = shift;
	my $self; # actually don't need anything here - just a placeholder
	bless \$self, $class;
}

sub as_string {
	# do nothing
}

sub as_xml {
    return "<Root/>\n";
}

sub evaluate {
	my $self = shift;
	my $nodeset = shift;
	
        #warn "Eval Root: ", $self -> as_string, "\n";
	
	# must only ever occur on 1 node
        #warn "nodeset size: ", $nodeset -> size, "\n";
	die "Can't go to root on > 1 node!" unless $nodeset->size == 1;
	
	my $newset = Data::DPath::NodeSet->new();
        #warn "Nodeset: $nodeset\nGet Node(1): ", $nodeset->get_node(1), "\n";
        #warn "newset: ", Data::Dumper -> Dump([$newset]);
	$newset->push($nodeset->get_node(1)->getRootNode());
    #warn "Evaluate Expr returning: ", Data::Dumper -> Dump([$newset]);
	return $newset;
}

1;
