package Tibco::Rv::Queue;


use vars qw/ $VERSION $DEFAULT /;
$VERSION = '0.03';


use constant DEFAULT_QUEUE => 1;

use constant DISCARD_NONE => 0;
use constant DISCARD_NEW => 1;
use constant DISCARD_FIRST => 2;
use constant DISCARD_LIST => 3;

use constant DEFAULT_POLICY => 0;
use constant DEFAULT_PRIORITY => 1;


use Tibco::Rv::Listener;
use Tibco::Rv::Timer;
use Tibco::Rv::IO;
use Tibco::Rv::Dispatcher;


my ( @limitProperties, %defaults );
BEGIN
{
   @limitProperties = qw/ policy maxEvents discardAmount /;
   %defaults = ( policy => DISCARD_NONE, maxEvents => 0, discardAmount => 0,
      name => 'tibrvQueue', priority => 1, hook => undef );
}


sub new
{
   my ( $proto ) = @_;
   my ( $class ) = ref( $proto ) || $proto;
   my ( $self ) = $class->_new;

   my ( $status ) = Tibco::Rv::Queue_Create( $self->{id} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );

   return $self;
}


sub _new
{
   my ( $class, $id ) = @_;
   return bless { id => $id, %defaults }, $class;
}


sub _adopt
{
   my ( $proto, $id ) = @_;

   my ( $class ) = ref( $proto );
   return $proto->_new( $id ) unless ( $class );

   $proto->DESTROY; 
   @$proto{ 'id', keys %defaults } = ( $id, values %defaults );
}


sub createListener
{
   my ( $self, $transport, $subject, $callback ) = @_;
   return new Tibco::Rv::Listener( $self, $transport, $subject, $callback );
}


sub createTimer
{
   my ( $self, $interval, $callback ) = @_;
   return new Tibco::Rv::Timer( $self, $interval, $callback );
}


sub createIO
{
   my ( $self, $socketId, $ioType, $callback ) = @_;
   return new Tibco::Rv::IO( $self, $socketId, $ioType, $callback );
}


sub createDispatcher
{
   my ( $self, $idleTimeout ) = @_;
   return new Tibco::Rv::Dispatcher( $self, $idleTimeout );
}


sub dispatch
{
   my ( $self ) = @_;
   return $self->timedDispatch( Tibco::Rv::WAIT_FOREVER );
}


sub poll
{
   my ( $self ) = @_;
   return $self->timedDispatch( Tibco::Rv::NO_WAIT );
}


sub timedDispatch
{
   my ( $self, $timeout ) = @_;
   my ( $status ) =
      Tibco::Rv::tibrvQueue_TimedDispatch( $self->{id}, $timeout );
   Tibco::Rv::die( $status )
      unless ( $status == Tibco::Rv::OK or $status == Tibco::Rv::TIMEOUT );
   return new Tibco::Rv::Status( $status );
}


sub count
{
   my ( $self ) = @_;
   my ( $count );
   my ( $status ) = Tibco::Rv::Queue_GetCount( $self->{id}, $count );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $count;
}


sub limitPolicy
{
   my ( $self ) = shift;
   return @_ ? $self->_setLimitPolicy( @_ ) : @$self{ @limitProperties };
}


sub _setLimitPolicy
{
   my ( $self, %policy );
   ( $self, @policy{ @limitProperties } ) = @_;
   my ( $status ) = Tibco::Rv::tibrvQueue_SetLimitPolicy( $self->{id},
      @policy{ @limitProperties } );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return @$self{ @limitProperties } = @policy{ @limitProperties };
}


sub name
{
   my ( $self ) = shift;
   return @_ ? $self->_setName( @_ ) : $self->{name};
}


sub _setName
{
   my ( $self, $name ) = @_;
   my ( $status ) = Tibco::Rv::tibrvQueue_SetName( $self->{id}, $name );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $self->{name} = $name;
}


sub priority
{
   my ( $self ) = shift;
   return @_ ? $self->_setPriority( @_ ) : $self->{priority};
}


sub _setPriority
{
   my ( $self, $priority ) = @_;
   my ( $status ) = Tibco::Rv::tibrvQueue_SetPriority( $self->{id}, $priority );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $self->{priority} = $priority;
}


sub hook
{
   my ( $self ) = shift;
   return @_ ? $self->_setHook( @_ ) : $self->{hook};
}


sub _setHook
{
   my ( $self, $hook ) = @_;
   $self->{hook} = $hook;
   my ( $status ) = Tibco::Rv::Queue_SetHook( $self->{id}, $self->{hook} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
   return $self->{hook};
}


sub DESTROY
{
   my ( $self, $callback ) = @_;
   return unless ( exists $self->{id} );

   my ( $status ) = Tibco::Rv::Queue_DestroyEx( $self->{id}, $callback );
   delete @$self{ keys %$self };
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


BEGIN { $DEFAULT = Tibco::Rv::Queue->_adopt( DEFAULT_QUEUE ) }


1;
