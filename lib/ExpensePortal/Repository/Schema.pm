package ExpensePortal::Repository::Schema;
use Mojo::Base -strict, -signatures;

# The tables, and the three people every new database starts with.

my @TABLES = (
    'CREATE TABLE IF NOT EXISTS employees (name TEXT PRIMARY KEY, role TEXT NOT NULL)',
    'CREATE TABLE IF NOT EXISTS claims ('
        . 'id INTEGER PRIMARY KEY AUTOINCREMENT, employee TEXT NOT NULL, category TEXT NOT NULL, '
        . 'amount REAL NOT NULL, status TEXT NOT NULL)',
);

my @STARTING_EMPLOYEES = (['alice', 'employee'], ['bob', 'manager'], ['carol', 'director']);

# Creates what is missing. Safe to call on a database that already has it all.
sub deploy ($class, $dbh) {
    $dbh->do($_) for @TABLES;

    my ($count) = $dbh->selectrow_array('SELECT COUNT(*) FROM employees');
    if (!$count) {
        $dbh->do('INSERT INTO employees (name, role) VALUES (?, ?)', undef, @{$_}) for @STARTING_EMPLOYEES;
    }
    return $dbh;
}

1;
