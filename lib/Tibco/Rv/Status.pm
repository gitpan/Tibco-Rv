package Tibco::Rv::Status;


use vars qw/ $VERSION /;
$VERSION = '0.03';


use overload '""' => 'toString', '0+' => 'toNum', fallback => 1;


sub new
{
   my ( $proto, $status ) = @_;
   my ( $class ) = ref( $proto ) || $proto;
   my ( $self ) = bless { status => $status }, $class;
   return $self;
}


sub toString { return Tibco::Rv::tibrvStatus_GetText( shift->{status} ) }
sub toNum { return shift->{status} }


1;
