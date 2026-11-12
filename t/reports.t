use Mojo::Base -strict;

use Test::More;

use lib 't/lib';
use TestApp qw(new_app as);

my ($t, $dir) = new_app();

$t->post_ok('/api/claims' => as('alice') => json => $_)->status_is(201)
    for {category => 'travel', amount => 10.2}, {category => 'travel', amount => 5.1}, {category => 'meals', amount => 8};
$t->post_ok('/api/claims' => as('bob') => json => {category => 'travel', amount => 99})->status_is(201);

# Totals
$t->get_ok('/api/reports/totals' => as('alice'))
    ->status_is(200)
    ->json_is('/employee' => 'alice')
    ->json_is('/totals'   => {travel => 16, meals => 8}, 'rounded up by default');
$t->get_ok('/api/reports/totals?rounding=floor' => as('alice'))->status_is(200)->json_is('/totals' => {travel => 15, meals => 8});
$t->get_ok('/api/reports/totals?employee=bob' => as('alice'))->status_is(200)->json_is('/totals' => {travel => 99});
$t->get_ok('/api/reports/totals?employee=nobody' => as('alice'))->status_is(200)->json_is('/totals' => {});
$t->get_ok('/api/reports/totals?rounding=nonsense' => as('alice'))->status_is(400)->json_is('/error' => 'Unknown rounding rule');

# Export
$t->post_ok('/api/reports/export' => as('alice'))
    ->status_is(200)
    ->json_is('/file'  => 'claims-alice.csv')
    ->json_is('/lines' => 4, 'a header and three claims');

open(my $fh, '<:encoding(UTF-8)', "$dir/exports/claims-alice.csv") or die "Cannot read the export: $!\n";
my @lines = <$fh>;
close $fh;
is $lines[0], "id,employee,category,amount,status\n", 'the header';
is $lines[1], "3,alice,meals,8.00,submitted\n",       'the newest claim first, with its amount to two places';
is scalar @lines, 4, 'one line for each claim';

done_testing;
