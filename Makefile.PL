use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Simulation::Particle',
    'VERSION_FROM'	=> 'lib/Simulation/Particle.pm', # finds $VERSION
    'PREREQ_PM'		=> {
      Test::More      => 0.44,
      Data::Dumper    => 2.0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Simulation/Particle.pm', # retrieve abstract from module
       AUTHOR     => 'Steffen Mueller <simpart-module@steffen-mueller.net>') : ()),
);
