use ExtUtils::MakeMaker;

#my $have_yapp = eval { require Parse::Yapp ;          1 };
#my $have_gvpy = eval { require GraphViz::Parse::Yapp; 1 };
my $have_xmldumper = eval { require XML::Dumper;      1 }; # root element: <perldata/>
my $have_dumperxml = eval { require Data::DumpXML;    1 }; # root element: <data/>

#warn <<'NO_HAVE_END' unless $have_yapp && $have_gvpy;
#
#Only if you plan on altering Data::DPath::Parser
#============================================================
#
#NO_HAVE_END
#
#warn <<'NO_HAVE_END' unless $have_yapp ;
#You'll need to install Parse::Yapp to rebuild
#Data::DPath::Parser from dpath.yp.  To do this,
#install Parse::Yapp and redo "perl Makefile.PL".  
#This will add a rule to the Makefile to rebuild 
#Grammar.pm from dpath.yp.
#
#NO_HAVE_END
#
#warn <<'NO_HAVE_END' unless $have_gvpy ;
#Optionally, you may want to graph the grammar.  Install
#GraphViz::Parse::Yapp and redo "perl Makefile.PL".  Then
#do a "make dpath.png" to build a (large!) dpath.png file,
#or "make dpath.dot" to make a file you can play with using 
#dotty.
#
#NO_HAVE_END

warn <<'NO_HAVE_END' unless $have_xmldumper || $have_dumperxml;

Only if you plan on working with XML-formatted data
============================================================

You'll need to install one of XML::Dumper or Data::DumpXML 
to use XML-formatted data when creating a Data::DPath object.

NO_HAVE_END

WriteMakefile(
    NAME          => 'Data::DPath',
    VERSION_FROM  => 'lib/Data/DPath.pm',
#    EXE_FILES     => [qw( bin/ddpath_dump )],

    PREREQ_PM => {
    },
);

__END__

#sub MY::libscan {
#    package MY;
#    my $self = shift;
#    my ( $path ) = @_;
#    return '' if /\.sw[a-z]$/;
#    return '' unless length $self->SUPER::libscan( $path );
#    return $path;
#}


# Note the literal tabes herein
#sub MY::postamble { return $have_yapp ? <<'POSTAMBLE_END' : '' }
#lib/Data/DPath/Parser.pm : dpath.yp
#	yapp -m Data::DPath::Parser \
#		-o lib/Data/DPath/Parser.pm \
#		-s \
#		dpath.yp
#
#dpath.output: dpath.yp
#	yapp -v dpath.yp
#
#dpath.png: dpath.output
#	$(PERL) -MGraphViz::Parse::Yapp \
#		-e 'binmode STDOUT; print GraphViz::Parse::Yapp->new( "dpath.output" )->as_png' \
#		> dpath.png
#
#dpath.dot: dpath.output
#	$(PERL) -MGraphViz::Parse::Yapp \
#		-e 'binmode STDOUT; print GraphViz::Parse::Yapp->new( "dpath.output" )->as_dot' \
#		> dpath.dot
#
#POSTAMBLE_END

