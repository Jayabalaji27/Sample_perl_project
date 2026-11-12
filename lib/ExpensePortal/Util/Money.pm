package ExpensePortal::Util::Money;
use strict;
use warnings;

use Exporter 'import';
use POSIX ();

our @EXPORT_OK = qw(format_money round_cents);

# Amounts of money: two decimal places, rounded half up.

sub round_cents {
    my ($amount) = @_;
    return POSIX::floor($amount * 100 + 0.5) / 100;
}

sub format_money {
    my ($amount) = @_;
    return sprintf '%.2f', round_cents($amount);
}

1;
