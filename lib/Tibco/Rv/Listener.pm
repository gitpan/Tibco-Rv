package Tibco::Rv::Listener;
use base qw/ Tibco::Rv::Event /;


use vars qw/ $VERSION /;
$VERSION = '1.00';


sub new
{
   my ( $proto ) = shift;
   my ( %params ) = ( queue => $Tibco::Rv::Queue::DEFAULT,
      transport => $Tibco::Rv::Transport::PROCESS, subject => '',
      callback => sub { print "Listener received: @_\n" } );
   my ( %args ) = @_;
   map { Tibco::Rv::die( Tibco::Rv::INVALID_ARG )
      unless ( exists $params{$_} ) } keys %args;
   %params = ( %params, %args );
   my ( $self ) = $proto->SUPER::new(
      queue => $params{queue}, callback => $params{callback} );

   @$self{ qw/ transport subject / } = @params{ qw/ transport subject / };

   my ( $status ) = Tibco::Rv::Event_CreateListener( $self->{id},
      $self->{queue}{id}, $self->{internal_msg_callback},
      $self->{transport}{id}, $self->{subject} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );

   return $self;
}


sub transport { return shift->{transport} }
sub subject { return shift->{subject} }


1;


=pod

=head1 NAME

Tibco::Rv::Listener - Tibco Listener event object

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head1 METHODS

=head1 AUTHOR

Paul Sturm E<lt>I<sturm@branewave.com>E<gt>

=cut
