use Test;

use Data::DPath::Parser;
use Data::DPath::Context;

plan tests => 1;

skip(q{axis_descendent isn't expected to work yet.});

__END__

my $parser = Data::DPath::Parser -> new();

use Data::Dumper;

my $parsed;
$Data::DPath::Debug = 0;

$parsed = $parser -> parse('/this//foo');

my $res = $parsed -> evaluate(Data::DPath::Context -> new({ this => { that => { foo => 'bar' } } }));
my $stringref = ($res -> get_nodelist)[0];
if(ref $stringref) {
    $stringref = $stringref -> get_data;
}

ok (ref($stringref) && $$stringref eq 'bar');




$parsed = $parser -> parse('/this//foo');

my $res = $parsed -> evaluate(Data::DPath::Context -> new({ this => { that => { the => { other => { foo => 'bar' } } } } }));
my $stringref = ($res -> get_nodelist)[0];
if(ref $stringref) {
    $stringref = $stringref -> get_data;
}

ok (ref($stringref) && $$stringref eq 'bar');
