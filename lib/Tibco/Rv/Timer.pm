package Tibco::Rv::Timer;
use base qw/ Tibco::Rv::Event /;


use vars qw/ $VERSION /;
$VERSION = '1.00';


sub new
{
   my ( $proto ) = shift;
   my ( %params ) = ( queue => $Tibco::Rv::Queue::DEFAULT, interval => 1,
      callback => sub { print "Timer fired\n" } );
   my ( %args ) = @_;
   map { Tibco::Rv::die( Tibco::Rv::INVALID_ARG )
      unless ( exists $params{$_} ) } keys %args;
   %params = ( %params, %args );
   my ( $self ) = $proto->SUPER::new(
      queue => $params{queue}, callback => $params{callback} );

   $self->{interval} = $params{interval};

   my ( $status ) = Tibco::Rv::Event_CreateTimer( $self->{id},
      $self->{queue}{id}, $self->{internal_nomsg_callback},
      $self->{interval} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );

   return $self;
}


sub interval
{
   my ( $self ) = shift;
   return @_ ? $self->resetTimerInterval( @_ ) : $self->{interval};
}


sub resetTimerInterval
{
   my ( $self, $interval ) = @_;
   my ( $status ) =
      Tibco::Rv::tibrvEvent_ResetTimerInterval( $self->{id}, $interval );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $self->{interval} = $interval;
}


1;


=pod

=head1 NAME

Tibco::Rv::Timer - Tibco Timer event object

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head1 METHODS

=head1 AUTHOR

Paul Sturm E<lt>I<sturm@branewave.com>E<gt>

=cut
