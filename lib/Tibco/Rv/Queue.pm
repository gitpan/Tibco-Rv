package Tibco::Rv::Queue;


use vars qw/ $VERSION $DEFAULT /;
$VERSION = '1.01';


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
   my ( $proto ) = shift;
   my ( %args ) = @_;
   map { Tibco::Rv::die( Tibco::Rv::INVALID_ARG )
      unless ( exists $defaults{$_} ) } keys %args;
   my ( %params ) = ( %defaults, %args );
   my ( $class ) = ref( $proto ) || $proto;
   my ( $self ) = $class->_new;

   my ( $status ) = Tibco::Rv::Queue_Create( $self->{id} );
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );

   $self->limitPolicy( @params{ qw/ policy maxEvents discardAmount / } )
      if ( $params{policy} != DISCARD_NONE or $params{maxEvents} != 0
         or $params{discardAmount} != 0 );
   $self->name( $params{name} ) if ( $params{name} ne 'tibrvQueue' );
   $self->priority( $params{priority} ) if ( $params{priority} != 1 );
   $self->hook( $params{hook} ) if ( defined $params{hook} );

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
   my ( $self, %args ) = @_;
   return new Tibco::Rv::Listener( queue => $self, %args );
}


sub createTimer
{
   my ( $self, %args ) = @_;
   return new Tibco::Rv::Timer( queue => $self, %args );
}


sub createIO
{
   my ( $self, %args ) = @_;
   return new Tibco::Rv::IO( queue => $self, %args );
}


sub createDispatcher
{
   my ( $self, %args ) = @_;
   return new Tibco::Rv::Dispatcher( dispatchable => $self, %args );
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
   return new Tibco::Rv::Status( status => $status );
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


=pod

=head1 NAME

Tibco::Rv::Queue - Tibco Queue event-managing object

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head1 METHODS

=head1 CONSTANTS

=head1 DEFAULT QUEUE

=head1 AUTHOR

Paul Sturm E<lt>I<sturm@branewave.com>E<gt>

=cut
