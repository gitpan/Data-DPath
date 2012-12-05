
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "DPath is not XPath!",
  "AUTHOR" => "Steffen Schwigon <ss5\@renormalist.net>",
  "BUILD_REQUIRES" => {
    "Test::Deep" => 0,
    "Test::More" => "0.88",
    "feature" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Data-DPath",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Data::DPath",
  "PREREQ_PM" => {
    "Class::XSAccessor" => 0,
    "Class::XSAccessor::Array" => 0,
    "Data::Dumper" => 0,
    "Iterator::Util" => 0,
    "List::MoreUtils" => 0,
    "List::Util" => 0,
    "POSIX" => 0,
    "Safe" => "2.30",
    "Scalar::Util" => 0,
    "Sub::Exporter" => 0,
    "Text::Balanced" => "2.02",
    "aliased" => 0,
    "constant" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.49",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



