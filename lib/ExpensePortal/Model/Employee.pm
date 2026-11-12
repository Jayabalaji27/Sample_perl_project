package ExpensePortal::Model::Employee;
use Mojo::Base -base, -signatures;

# Someone who can submit claims, and perhaps decide other people's.

has 'name';
has role => 'employee';

# An employee from a database row.
sub from_row ($class, $row) {
    return $class->new(%{$row});
}

# Managers and directors decide claims.
sub is_manager ($self) {
    return $self->role eq 'manager' || $self->is_director;
}

sub is_director ($self) {
    return $self->role eq 'director';
}

sub to_hash ($self) {
    return {name => $self->name, role => $self->role};
}

1;
