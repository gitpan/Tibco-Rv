package Tibco::Rv::Dispatcher;


use vars qw/ $VERSION /;
$VERSION = '0.99';


my ( %defaults );
BEGIN
{
   %defaults = ( dispatchable => undef, idleTimeout => Tibco::Rv::WAIT_FOREVER,
      name => '' );
}


sub new
{
   my ( $proto, $dispatchable, $idleTimeout ) = @_;
   my ( $class ) = ref( $proto ) || $proto;
   my ( $self ) = $class->_new;

   $self->{dispatchable} = $dispatchable;
   $self->{idleTimeout} = $idleTimeout if ( defined $idleTimeout );

   my ( $status ) = Tibco::Rv::Dispatcher_Create( $self->{id},
      $dispatchable->{id}, $self->{idleTimeout} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );

   return $self;
}


sub _new
{
   my ( $class, $id ) = @_;
   return bless { id => $id, %defaults }, $class;
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
