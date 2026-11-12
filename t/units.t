use Mojo::Base -strict;

use DBI;
use File::Temp qw(tempdir);
use Test::More;

use ExpensePortal::Model::Claim;
use ExpensePortal::Model::Employee;
use ExpensePortal::Repository::ClaimRepository;
use ExpensePortal::Repository::EmployeeRepository;
use ExpensePortal::Repository::Schema;
use ExpensePortal::Service::ReportService;
use ExpensePortal::Util::Files qw(read_receipt save_receipt write_export);
use ExpensePortal::Util::Money qw(format_money round_cents);

# Money
is round_cents(120.456), 120.46, 'rounded to cents, half up';
is round_cents(0.005),   0.01,   'half a cent goes up';
is format_money(8),      '8.00', 'always two places';

# Models
my $claim = ExpensePortal::Model::Claim->new(employee => 'alice', amount => 12.5);
is $claim->category, 'other',     'a claim without a category is "other"';
is $claim->status,   'submitted', 'a new claim is submitted';
ok $claim->is_open, 'and open';
is_deeply $claim->validate, [], 'a good claim has no errors';
my $bad = ExpensePortal::Model::Claim->new(amount => 'lots');
is_deeply $bad->validate, ['employee is required', 'amount must be a positive number'], 'what is wrong with a bad one';
is_deeply $claim->to_hash, {id => undef, employee => 'alice', category => 'other', amount => 12.5, status => 'submitted'}, 'to_hash has every field';

my %person = (
    alice => ExpensePortal::Model::Employee->new(name => 'alice'),
    bob   => ExpensePortal::Model::Employee->new(name => 'bob', role => 'manager'),
    carol => ExpensePortal::Model::Employee->new(name => 'carol', role => 'director'),
);
ok !$person{alice}->is_manager, 'an employee is not a manager';
ok $person{bob}->is_manager,    'a manager is';
ok $person{carol}->is_manager,  'and so is a director';
ok !$person{bob}->is_director,  'a manager is not a director';

# Repositories, over a real database
my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', q{}, q{}, {RaiseError => 1, PrintError => 0});
ExpensePortal::Repository::Schema->deploy($dbh);
ExpensePortal::Repository::Schema->deploy($dbh);

my $employees = ExpensePortal::Repository::EmployeeRepository->new(dbh => $dbh);
is scalar @{$employees->all}, 3, 'a new database has its three people, once';
is $employees->find_by_name('bob')->role, 'manager', 'an employee by name';
is $employees->find_by_name('nobody'), undef, 'undef when nobody has that name';

my $claims = ExpensePortal::Repository::ClaimRepository->new(dbh => $dbh);
is $claims->add(ExpensePortal::Model::Claim->new(employee => 'alice', category => 'travel', amount => 80)),  1, 'the first claim\'s id';
is $claims->add(ExpensePortal::Model::Claim->new(employee => 'alice', category => 'meals',  amount => 12.5)), 2, 'the second';
is $claims->add(ExpensePortal::Model::Claim->new(employee => 'bob',   category => 'travel', amount => 40)),  3, 'and another employee\'s';

my $found = $claims->find_by_employee('alice');
is scalar @{$found}, 2, 'only that employee\'s claims';
isa_ok $found->[0], 'ExpensePortal::Model::Claim';
is $found->[0]->id, 2, 'newest first';
is_deeply $claims->find_by_employee('nobody'), [], 'no claims for a name nobody has';

is $claims->find_by_id(1)->category, 'travel', 'a claim by its id';
is $claims->find_by_id(99), undef, 'undef when there is no such claim';
$claims->set_status(1, 'approved');
is $claims->find_by_id(1)->status, 'approved', 'a status once set is stored';
is_deeply $claims->count_by_status('alice'), {approved => 1, submitted => 1}, 'claims counted by status';

ok !eval { ExpensePortal::Repository::ClaimRepository->new; 1 }, 'a repository without a database handle is refused';

# Rounding rules
my $reports = ExpensePortal::Service::ReportService->new(dbh => $dbh);
is $reports->round_amount(10.2, 'ceil'),  11, 'ceil rounds up';
is $reports->round_amount(10.8, 'floor'), 10, 'floor rounds down';
ok !eval { $reports->round_amount(10.2, 'nonsense'); 1 }, 'an unknown rule is refused';
like $@, qr/Unknown rounding rule/, 'saying so';
is_deeply $reports->totals_by_category('alice'), {travel => 80, meals => 13}, 'totals per category, rounded up';

# Files
my $dir = tempdir(CLEANUP => 1);
is save_receipt("$dir/7-taxi.txt", "Taxi\n9.00\n"), 10, 'save_receipt returns the characters stored';
is read_receipt("$dir/7-taxi.txt"), "Taxi\n9.00\n", 'read_receipt gives the whole text';
ok !eval { read_receipt("$dir/missing.txt"); 1 }, 'a missing receipt is an error';
like $@, qr/Cannot read the receipt/, 'saying which file';
is write_export("$dir/export.csv", ['id,amount', '1,12.50']), 2, 'write_export returns the lines written';
is read_receipt("$dir/export.csv"), "id,amount\n1,12.50\n", 'and writes each on its own line';

done_testing;
