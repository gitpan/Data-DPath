use Test;

use Data::DPath;

plan tests => 6;

my $dp = Data::DPath -> new( hash => {
    this => {
      foo => 'bar'
    }
} );
  
my $dataset = $dp -> find('/this/foo');

ok( scalar($dataset -> get_nodelist) == 1 );

foreach my $node ($dataset -> get_nodelist) {
    my $stringref = $node -> get_data;
    ok (ref($stringref) && $$stringref eq 'bar');
}

 
$dataset = $dp -> find('/that/foo', Data::DPath::Context -> new({ that => { foo => 'bar' } }));

ok( scalar($dataset -> get_nodelist) == 1 );

foreach my $node ($dataset -> get_nodelist) {
    my $stringref = $node -> get_data;
    ok (ref($stringref) && $$stringref eq 'bar');
}

$dataset = $dp -> find(
    '/this/that/the/other/foo', 
    Data::DPath::Context -> new({ this => { that => { the => { other => { foo => 'bar' } } } } })
);

ok( scalar($dataset -> get_nodelist) == 1 );

foreach my $node ($dataset -> get_nodelist) {
    my $stringref = $node -> get_data;
    ok (ref($stringref) && $$stringref eq 'bar');
}
