$^W = 0;

use Tibco::Rv;

print "1..1\n";


my ( $rv ) = new Tibco::Rv;
print "ok 1\n" if ( defined $rv );
