package Tibco::Rv::Dispatcher;


use vars qw/ $VERSION /;
$VERSION = '1.00';


sub new
{
   my ( %proto ) = shift;
   my ( %params ) = ( name => undef, dispatchable => undef,
      idleTimeout => Tibco::Rv::WAIT_FOREVER );
   my ( %args ) = @_;
   map { Tibco::Rv::die( Tibco::Rv::INVALID_ARG )
      unless ( exists $params{$_} ) } keys %args;
   %params = ( %params, %args );
   my ( $class ) = ref( $proto ) || $proto;
   my ( $self ) = bless { id => undef, %params }, $class;

   my ( $status ) = Tibco::Rv::Dispatcher_Create( $self->{id},
      $dispatchable->{id}, $self->{idleTimeout} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   $self->name( $params{name} ) if ( defined $params{name} );

   return $self;
}


sub dispatchable { return shift->{dispatchable} }
sub idleTimeout { return shift->{idleTimeout} }


sub name
{
   my ( $self ) = shift;
   return @_ ? $self->_setName( @_ ) : $self->{name};
}

sub _setName
{
   my ( $self, $name ) = @_;
   my ( $status ) =
      Tibco::Rv::tibrvDispatcher_SetName( $self->{id}, $name );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $self->{name} = $name;
}


# blah -- tibrvDispatcher_Destroy gets called automatically when
# idleTimeout times out, or you can call it manually!
# how would the idleTimeout inform this object?  Listening on
# DISPATCHER.THREAD_EXITED?
sub DESTROY
{
   my ( $self ) = @_;
   return unless ( exists $self->{id} );

   my ( $status ) = Tibco::Rv::tibrvDispatcher_Destroy( $self->{id} );
   delete $self->{id};
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


1;


=pod

=head1 NAME

Tibco::Rv::Dispatcher - Tibco Queue dispatching thread

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head1 METHODS

=head1 AUTHOR

Paul Sturm E<lt>I<sturm@branewave.com>E<gt>

=cut
