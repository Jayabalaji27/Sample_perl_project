use Mojo::Base -strict;

use Test::More;

use lib 't/lib';
use TestApp qw(new_app as);

my ($t) = new_app();

# Who may call
$t->get_ok('/health')->status_is(200)->json_is('/status' => 'ok');
$t->get_ok('/api/claims')->status_is(401)->json_is('/error' => 'unauthorized');
$t->get_ok('/api/claims' => {Authorization => 'Bearer test-token'})->status_is(401, 'a token without a name is not enough');
$t->get_ok('/api/claims' => {Authorization => 'Bearer wrong', 'X-Employee' => 'alice'})->status_is(401);

# Submitting
$t->post_ok('/api/claims' => as('alice') => json => {category => 'travel', amount => 120.456})
    ->status_is(201)
    ->json_is('/id'       => 1)
    ->json_is('/employee' => 'alice')
    ->json_is('/category' => 'travel')
    ->json_is('/amount'   => 120.46)
    ->json_is('/status'   => 'submitted');

$t->post_ok('/api/claims' => as('alice') => json => {amount => 8})->status_is(201)->json_is('/category' => 'other');
$t->post_ok('/api/claims' => as('alice') => json => {category => 'travel', amount => -5})
    ->status_is(422)
    ->json_is('/errors/0' => 'amount must be a positive number');
$t->post_ok('/api/claims' => as('alice') => json => {category => 'yacht', amount => 5})
    ->status_is(422)
    ->json_is('/errors/0' => 'unknown category: yacht');

# Reading
$t->get_ok('/api/claims' => as('alice'))->status_is(200)->json_is('/claims/0/id' => 2)->json_is('/claims/1/id' => 1);
$t->get_ok('/api/claims' => as('bob'))->status_is(200)->json_is('/claims' => []);
$t->get_ok('/api/claims?employee=alice' => as('bob'))->status_is(200)->json_has('/claims/1');
$t->get_ok('/api/claims/1' => as('bob'))->status_is(200)->json_is('/amount' => 120.46);
$t->get_ok('/api/claims/99' => as('bob'))->status_is(404)->json_is('/error' => 'No such claim');

# Deciding
$t->post_ok('/api/claims/1/approve' => as('alice'))->status_is(409)->json_is('/error' => 'Nobody decides their own claim');
$t->post_ok('/api/claims/1/approve' => as('dave'))->status_is(409)->json_is('/error' => 'Only a manager can decide a claim');
$t->post_ok('/api/claims/1/approve' => as('bob'))->status_is(200)->json_is('/status' => 'approved');
$t->post_ok('/api/claims/1/approve' => as('bob'))->status_is(409)->json_is('/error' => 'Claim 1 is already approved');
$t->post_ok('/api/claims/2/reject' => as('bob'))->status_is(200)->json_is('/status' => 'rejected');
$t->post_ok('/api/claims/99/approve' => as('bob'))->status_is(404);

# Over the limit, a director decides
$t->post_ok('/api/claims' => as('alice') => json => {category => 'equipment', amount => 900})->status_is(201)->json_is('/id' => 3);
$t->post_ok('/api/claims/3/approve' => as('bob'))->status_is(409)->json_is('/error' => 'A claim over 500 needs a director');
$t->post_ok('/api/claims/3/approve' => as('carol'))->status_is(200)->json_is('/status' => 'approved');

# Employees
$t->get_ok('/api/employees' => as('alice'))->status_is(200)->json_is('/employees/0/name' => 'alice')->json_is('/employees/2/role' => 'director');
$t->get_ok('/api/employees/alice' => as('bob'))
    ->status_is(200)
    ->json_is('/employee/role'   => 'employee')
    ->json_is('/claims/approved' => 2)
    ->json_is('/claims/rejected' => 1);
$t->get_ok('/api/employees/nobody' => as('bob'))->status_is(404);

done_testing;
