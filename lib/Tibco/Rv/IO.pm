package Tibco::Rv::IO;
use base qw/ Tibco::Rv::Event /;


use vars qw/ $VERSION /;
$VERSION = '1.01';


use constant READ => 1;
use constant WRITE => 2;
use constant EXCEPTION => 4;


sub new
{
   my ( $proto ) = shift;
   my ( %params ) = ( queue => $Tibco::Rv::Queue::DEFAULT, socketId => undef,
      ioType => undef, callback => sub { print "IO event occurred\n" } );
   my ( %args ) = @_;
   map { Tibco::Rv::die( Tibco::Rv::INVALID_ARG )
      unless ( exists $params{$_} ) } keys %args;
   %params = ( %params, %args );
   my ( $self ) = $proto->SUPER::new(
      queue => $params{queue}, callback => $params{callback} );

   @$self{ qw/ socketId ioType / } = @params{ qw/ socketId ioType / };

   my ( $status ) = Tibco::Rv::Event_CreateIO( $self->{id}, $self->{queue}{id},
      $self->{internal_nomsg_callback}, $self->{socketId}, $self->{ioType} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );

   return $self;
}


sub socketId { return shift->{socketId} }
sub ioType { return shift->{ioType} }


1;


=pod

=head1 NAME

Tibco::Rv::IO - Tibco IO event object

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head1 METHODS

=head1 OVERRIDING EVENT CALLBACK

=head1 AUTHOR

Paul Sturm E<lt>I<sturm@branewave.com>E<gt>

=cut
