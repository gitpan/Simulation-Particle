
# See the POD documentation at the end of this
# document for detailed copyright information.
# (c) 2002 Steffen Mueller, all rights reserved.

package Simulation::Particle;

use 5.006;
use strict;
use warnings;

use Carp;

use Data::Dumper;

use vars qw/$VERSION/;
$VERSION = '0.02';


# constructor new
# 
# Does not require any arguments. All arguments
# directly modify the object as key/value pairs.
# returns freshly created simulator object.

sub new {
   my $proto = shift;
   my $class = ref $proto || $proto;

   # Make a new object with default values.
   my $self = {
     forces => [], # All forces (callbacks) will be stored here.
     p      => [], # All particles (hashrefs) will be stored here.
     p_attr => {
                 x => 0,
                 y => 0,
                 z => 0,
                 vx => 0,
                 vy => 0,
                 vz => 0,
                 m => 1,
                 id => '',
               },
     @_
   };

   bless $self => $class;
}


# method set_particle_default
#
# Takes a hash reference whichis then used as is for
# particle default attributes such as position, velocity, mass,
# unique ID, or whatever properties you fancy.

sub set_particle_default {
   my $self = shift;
   my $hashref = shift;

   ref $hashref eq 'HASH'
     or croak "Must pass hash reference to set_particle_default().";

   $self->{p_attr} = $hashref;
   return 1;
}

# method add_particle
# 
# Takes key/value pairs of particle attributes.
# Attributes default to whatever has been set using
# set_particle_default.
# A new particle represented by the attributes is then
# created in the simulation and its particle number is
# returned.

sub add_particle {
   my $self = shift;

   my $particle = {
      %{$self->{p_attr}},
      @_
   };

   my $particle_no = $self->_make_particle();

   $self->{p}[$particle_no] = $particle;

   return $particle_no;
}


# private method _make_particle
#
# Returns a currently unused particle number or
# appends an empty particle to the particle list.

sub _make_particle {
   my $self = shift;
   my $count = 0;
   foreach (@{$self->{p}}) {
      return $count unless ref $_;
      $count++;
   }

   push @{ $self->{p} }, undef;
   return $count;
}


# method clear_particles
# 
# Removes all particles from the simulation.

sub clear_particles {
   my $self = shift;
   $self->{p} = [];
   return 1;
}


# method remove_particle
#
# Removes a specific particle from the simulation.
# Takes the particle number as argument.
# Returns 1 on success, 0 otherwise.

sub remove_particle {
   my $self = shift;
   my $particle_no = shift;

   return 0 if $particle_no < 0 || $particle_no > $#{$self->{p}};

   $self->{p}[$particle_no] = undef;

   return 1;
}


# method add_force
#
# Adds a new force to the simulation.
# Takes a subroutine reference (the force) as argument,
# appends it to the list of forces and returns the force it
# just appended.

sub add_force {
   my $self = shift;
   my $force = shift;

   push @{$self->{forces}}, $force;
   return $force;
}


# method iterate_step
#
# Applies all forces (excerted by every particle) to all particles.
# That means this is of complexity no_particles*no_particles*forces.
# Takes a list of additional parameters as argument that will be
# passed to every force subroutine.

sub iterate_step {
   my $self = shift;
   my @params = @_;

   my $new_state = [];

   my $p_no = 0;
   foreach my $p (@{ $self->{p} }) {
      my $new_p = { %$p };

      foreach my $force (@{$self->{forces}}) {
         my $exc_no = 0;
         foreach my $excerter (@{$self->{p}}) {
            $exc_no++, next if $exc_no == $p_no;
            $force->($new_p, $excerter, \@params);
            $exc_no++;
         }

      }
      push @$new_state, $new_p;
      $p_no++;
   }

   $self->{p} = $new_state;

   return 1;
}


# method dump_state
# 
# Returns a Data::Dumper dump of the state of all particles.

sub dump_state {
   my $self = shift;
   return Dumper($self->{p});
}

1;


__END__

=pod

=head1 NAME

Simulation::Particle - Simulate particle dynamics

=head1 VERSION

Current version is 0.02.

=head1 SYNOPSIS

  # Taken from the tests.
  # This is missing some code and constants and
  # is therefore not runnable per se.
  
  use Simulation::Particle;
  
  # This'll be the inner solar system.
  my $sim = Simulation::Particle->new();
  
  # Uncommented example code following!
  # This is gravity!
  $sim->add_force(
     sub {
        my $p = shift;
        my $excerter = shift;
        my $params = shift;
        my $time_diff = $params->[0];
  
        my $dist = sqrt(
                    ( AU * ($p->{x} - $excerter->{x}) )**2 +
                    ( AU * ($p->{y} - $excerter->{y}) )**2 +
                    ( AU * ($p->{z} - $excerter->{z}) )**2
                   );
        my $acc = ( $dist==0 ? 0 :
                    G * $excerter->{m} * MEARTH / $dist**2 );
        $acc = [
                 map { $acc * AU * ($excerter->{$_} - $p->{$_}) }
                     qw/x y z/
               ];
  
        $p->{x}  += $p->{vx} * $time_diff +
                    $acc->[0]*0.5*$time_diff**2/AU;
        $p->{y}  += $p->{vy} * $time_diff +
                    $acc->[1]*0.5*$time_diff**2/AU;
        $p->{z}  += $p->{vz} * $time_diff +
                    $acc->[2]*0.5*$time_diff**2/AU;
  
        $p->{vx} += $acc->[0]*$time_diff/AU;
        $p->{vy} += $acc->[1]*$time_diff/AU;
        $p->{vz} += $acc->[2]*$time_diff/AU;
     },
  );
  
  $sim->add_particle(
    x  => -0.001541580, y  => -0.005157481, z  => -0.002146907,
    vx => 0.000008555,  vy => 0.000000341,  vz => -0.000000084,
    m  => 333054.25,    n  => 'sun',
  );
  
  $sim->add_particle(
    x  => 0.352233521,  y  => -0.117718043, z  => -0.098961836,
    vx => 0.004046276,  vy => 0.024697922,  vz => 0.0127737,
    m  => 0.05525787,   n  => 'mercury',
  );
  
  
  # [...]
  
  my $iterations = 1000;
  foreach (1..$iterations) {
     $sim->iterate_step(1);
  }
  
  my $state = $sim->dump_state();
  
  # Now do something with it. You could, for example,
  # use GNUPlot or the Math::Project3D module to create
  # 3D graphs of the data.

=head1 DESCRIPTION

Simulation::Particle is a facility to simulate movements of
a small number of particles under a small number of forces
that every particle excerts on the others. Complexity increases
with particles X particles X forces, so that is why the
number of particles should be low.

In the context of this module, a particle is no more or less
than a set of attributes like position, velocity, mass, and
charge. The example code and test cases that come with the
distribution simulate the inner solar system showing that
when your scale is large enough, planets and stars may
well be approximated as particles. (As a matter of fact,
in the case of gravity, if the planet's shape was a sphere,
the force of gravity outside the planet would always be
its mass times the mass of the body it excerts the force on
times the gravitational constant divided by the distance
squared.)

Simulation of microscopic particles is a bit more difficult
due to floating point arithmetics on extremely small values.
You will need to choose your constant factors wisely.

=head2 Forces

As you might have gleamed from the synopsis, you will have to
write subroutines that represent forces which the particles
of the simulation excert on one another. You may specify
(theoretically) any number of forces.

The force subroutines are passed three parameters. First is the
particle that should be modified according to the effect of the force.
Second is the particle that excerts the force, and the third
argument will be an array reference of parameters passed to the
iterate_step method at run time.

Yes, unfortunately in this version, forces actually have to modify
the particles themselves. Their return value is currently
ignored, but in future versions of this module, forces might be
required to return a vector indicating the magnitude and direction
of the force.

Additionally, external force fields are currently not implemented.

=head2 Methods

=over 4

=item new

new() is the constructor for a fresh simulation.
It does not require any arguments. All arguments
directly modify the object as key/value pairs.
Returns newly created simulator object.

=item add_particle

This method takes key/value pairs of particle attributes.
Attributes default to whatever has been set using
set_particle_default.
A new particle represented by the attributes is then
created in the simulation and its particle number is
returned.

=item remove_particle

This method removes a specific particle from the simulation.
It takes the particle number as argument and returns
1 on success, 0 otherwise.

=item clear_particles

This method removes all particles from the simulation.

=item set_particle_default

Takes a hash reference as argument which is then used
for particle default attributes such as position, velocity, mass,
unique ID, or whatever properties you fancy.

You should not change the defaults after adding particles.
You knew that doesn't make sense, did you?

=item add_force

This method adds a new force to the simulation.
It takes a subroutine reference (the force) as argument,
appends it to the list of forces and returns the force it
just appended.

=item iterate_step

This method applies all forces (excerted by every particle) to all particles.
That means this is of complexity no_particles*no_particles*forces.
Takes a list of additional parameters as argument that will be
passed to every force subroutine. (This could, for example, be
the duration of the iteration so the forces know how to calculate
the effects on the particles (F=m*a if you neglect relativistic
effects).

=item dump_state

This method returns a Data::Dumper dump of the state of all particles.

=back

=head1 AUTHOR

Steffen Mueller, mail at steffen-mueller dot net

=head1 COPYRIGHT

Copyright (c) 2002 Steffen Mueller. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>, L<Math::Project3D>, L<Math::Project3D::Plot>

=cut
