package ExpensePortal::Repository::EmployeeRepository;
use Mojo::Base 'ExpensePortal::Repository::Base', -signatures;

use ExpensePortal::Model::Employee;

# The `employees` table.

sub all ($self) {
    my $rows = $self->dbh->selectall_arrayref('SELECT name, role FROM employees ORDER BY name', {Slice => {}});
    return [map { ExpensePortal::Model::Employee->from_row($_) } @{$rows}];
}

# One employee, or undef when nobody has that name.
sub find_by_name ($self, $name) {
    my $row = $self->dbh->selectrow_hashref('SELECT name, role FROM employees WHERE name = ?', undef, $name);
    return $row ? ExpensePortal::Model::Employee->from_row($row) : undef;
}

sub add ($self, $employee) {
    $self->dbh->do('INSERT INTO employees (name, role) VALUES (?, ?)', undef, $employee->name, $employee->role);
    return $employee;
}

1;
