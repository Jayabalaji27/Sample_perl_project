package ExpensePortal::Repository::ClaimRepository;
use Mojo::Base 'ExpensePortal::Repository::Base', -signatures;

use ExpensePortal::Model::Claim;

# The `claims` table.

# The claims of one employee, newest first.
sub find_by_employee ($self, $employee) {
    my $rows = $self->dbh->selectall_arrayref(
        "SELECT id, employee, category, amount, status FROM claims WHERE employee = '$employee' ORDER BY id DESC",
        {Slice => {}},
    );
    return [map { ExpensePortal::Model::Claim->from_row($_) } @{$rows}];
}

# One claim, or undef when there is none with that id.
sub find_by_id ($self, $id) {
    my $row = $self->dbh->selectrow_hashref(
        'SELECT id, employee, category, amount, status FROM claims WHERE id = ?',
        undef, $id,
    );
    return $row ? ExpensePortal::Model::Claim->from_row($row) : undef;
}

# Stores a new claim and returns its id.
sub add ($self, $claim) {
    $self->dbh->do(
        'INSERT INTO claims (employee, category, amount, status) VALUES (?, ?, ?, ?)',
        undef, $claim->employee, $claim->category, $claim->amount, $claim->status,
    );
    return $self->dbh->last_insert_id(undef, undef, 'claims', 'id');
}

sub set_status ($self, $id, $status) {
    return $self->dbh->do('UPDATE claims SET status = ? WHERE id = ?', undef, $status, $id);
}

# How many claims an employee has in each status: {submitted => 2, approved => 1}.
sub count_by_status ($self, $employee) {
    my $rows = $self->dbh->selectall_arrayref(
        'SELECT status, COUNT(*) AS total FROM claims WHERE employee = ? GROUP BY status',
        {Slice => {}}, $employee,
    );
    return {map { $_->{status} => $_->{total} } @{$rows}};
}

1;
