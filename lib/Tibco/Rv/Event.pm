package Tibco::Rv::Event;


use vars qw/ $VERSION /;
$VERSION = '0.03';


use Tibco::Rv::Msg;


sub new
{
   my ( $proto, $queue, $callback ) = @_;
   my ( $class ) = ref( $proto ) || $proto;
   my ( $self ) = bless { queue => $queue, id => undef }, $class;

   $self->{callback} = defined $callback ? $callback : sub { print "@_\n" };
   $self->{internal_nomsg_callback} = sub { $self->onEvent( ) };
   $self->{internal_msg_callback} =
      sub { $self->onEvent( Tibco::Rv::Msg->_adopt( shift ) ) };

   return $self;
}


sub queue { return shift->{queue} }
sub callback { return shift->{callback} }


sub onEvent
{
   my ( $self, @args ) = @_;
   $self->{callback}->( @args );
}


# callback not supported
sub DESTROY
{
   my ( $self ) = @_;
   return unless ( exists $self->{id} );

   my ( $status ) = Tibco::Rv::Event_DestroyEx( $self->{id} );
   delete $self->{id};
   Tibco::Rv::die( $status ) unless ( $status == Tibco::Rv::OK );
}


1;
