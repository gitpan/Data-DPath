package Data::DPath::Boolean;

use Data::DPath::Number;
use Data::DPath::Literal;
use strict;

use overload
		'""' => \&value,
		'<=>' => \&cmp;

sub True {
	my $class = shift;
	my $val = 1;
	bless \$val, $class;
}

sub False {
	my $class = shift;
	my $val = 0;
	bless \$val, $class;
}

sub value {
	my $self = shift;
	$$self;
}

sub cmp {
	my $self = shift;
	my ($other, $swap) = @_;
	if ($swap) {
		return $other <=> $$self;
	}
	return $$self <=> $other;
}

sub to_number { Data::DPath::Number->new($_[0]->value); }
sub to_boolean { $_[0]; }
sub to_literal { Data::DPath::Literal->new($_[0]->value ? "true" : "false"); }

sub string_value { return $_[0]->to_literal->value; }

1;
__END__

=head1 NAME

Data::DPath::Boolean - Boolean true/false values

=head1 DESCRIPTION

Data::DPath::Boolean objects implement simple boolean true/false objects.

=head1 API

=head2 Data::DPath::Boolean->True

Creates a new Boolean object with a true value.

=head2 Data::DPath::Boolean->False

Creates a new Boolean object with a false value.

=head2 value()

Returns true or false.

=head2 to_literal()

Returns the string "true" or "false".

=cut
