package Data::DPath::LocationPath;
use Data::DPath::Root;
use strict;

sub new {
	my $class = shift;
	my $self = [];
	bless $self, $class;
}

sub as_string {
	my $self = shift;
	my $string;
	for (my $i = 0; $i < @$self; $i++) {
		$string .= $self->[$i]->as_string;
		$string .= "/" if $self->[$i+1];
	}
	return $string;
}

sub as_xml {
    my $self = shift;
    my $string = "<LocationPath>\n";
    
    for (my $i = 0; $i < @$self; $i++) {
        $string .= $self->[$i]->as_xml;
    }
    
    $string .= "</LocationPath>\n";
    return $string;
}

sub set_root {
	my $self = shift;
	unshift @$self, Data::DPath::Root->new();
}

sub evaluate {
	my $self = shift;
	# context _MUST_ be a single node
	my $context = shift;
        #warn "Eval LocationPath: ", $self -> as_string, "\n";
	die "No context" unless $context;
	
	# I _think_ this is how it should work :)
	
	my $nodeset = Data::DPath::NodeSet->new();
	$nodeset->push($context);
	
	foreach my $step (@$self) {
		# For each step
		# evaluate the step with the nodeset
		my $pos = 1;
		$nodeset = $step->evaluate($nodeset);
	}
	
    #warn "Evaluate LocationPath returning: ", Data::Dumper -> Dump([$nodeset]);
	return $nodeset;
}

1;
