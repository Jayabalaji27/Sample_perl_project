use Mojo::Base -strict;

use Mojo::Util qw(encode);
use Test::More;

use lib 't/lib';
use TestApp qw(new_app as);

my ($t) = new_app();

$t->post_ok('/api/claims' => as('alice') => json => {category => 'travel', amount => 23.5})->status_is(201)->json_is('/id' => 1);

# Storing
$t->put_ok('/api/claims/1/receipt?name=taxi.txt' => as('alice') => "Taxi to the airport\n23.50\n")
    ->status_is(201)
    ->json_is('/claim' => 1)
    ->json_is('/name'  => 'taxi.txt')
    ->json_is('/bytes' => 26);
$t->put_ok('/api/claims/1/receipt' => as('alice') => 'no name')->status_is(400)->json_is('/error' => 'name is required');
$t->put_ok('/api/claims/99/receipt?name=taxi.txt' => as('alice') => 'no claim')->status_is(404);

# Reading
$t->get_ok('/api/claims/1/receipt?name=taxi.txt' => as('bob'))
    ->status_is(200)
    ->json_is('/claim' => 1)
    ->json_is('/text'  => "Taxi to the airport\n23.50\n");
$t->get_ok('/api/claims/1/receipt?name=missing.txt' => as('bob'))->status_is(404)->json_is('/error' => 'No such receipt');
$t->get_ok('/api/claims/1/receipt' => as('bob'))->status_is(400);

# Text beyond ASCII comes back as it went in
my $text = "Caf\x{e9} cr\x{e8}me 4,50 \x{20ac}\n";
$t->put_ok('/api/claims/1/receipt?name=cafe.txt' => as('alice') => encode('UTF-8', $text))->status_is(201)->json_is('/bytes' => length $text);
$t->get_ok('/api/claims/1/receipt?name=cafe.txt' => as('alice'))->status_is(200)->json_is('/text' => $text);

done_testing;
