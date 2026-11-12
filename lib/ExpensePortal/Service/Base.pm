package ExpensePortal::Service::Base;
use Mojo::Base -base, -signatures;

use ExpensePortal::Repository::ClaimRepository;
use ExpensePortal::Repository::EmployeeRepository;

# What every service has: the database handle, and the repositories over it.

has 'dbh';
has claims    => sub ($self) { return ExpensePortal::Repository::ClaimRepository->new(dbh => $self->dbh) };
has employees => sub ($self) { return ExpensePortal::Repository::EmployeeRepository->new(dbh => $self->dbh) };

sub new ($class, @args) {
    my $self = $class->SUPER::new(@args);
    die "A service needs a database handle\n" if !$self->dbh;
    return $self;
}

1;
