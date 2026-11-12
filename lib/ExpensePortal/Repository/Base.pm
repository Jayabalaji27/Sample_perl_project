package ExpensePortal::Repository::Base;
use Mojo::Base -base, -signatures;

# What every repository has: the DBI handle it reads and writes through.

has 'dbh';

sub new ($class, @args) {
    my $self = $class->SUPER::new(@args);
    die "A repository needs a database handle\n" if !$self->dbh;
    return $self;
}

1;
