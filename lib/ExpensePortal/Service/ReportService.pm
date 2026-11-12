package ExpensePortal::Service::ReportService;
use Mojo::Base 'ExpensePortal::Service::Base', -signatures;
use Role::Tiny::With;

use POSIX ();

use ExpensePortal::Util::Files qw(write_export);
use ExpensePortal::Util::Money qw(format_money);

with 'ExpensePortal::Role::Auditable';

# Totals and exports built from an employee's claims.

has export_dir => 'data/exports';

# An amount rounded by the finance policy's rule: "ceil" or "floor".
sub round_amount ($self, $amount, $rule) {
    my $rounded = eval "POSIX::$rule(\$amount)";
    die "Unknown rounding rule: $rule\n" if $@ || !defined $rounded;
    return $rounded;
}

# The total claimed per category, each rounded by `rule`.
sub totals_by_category ($self, $employee, $rule = 'ceil') {
    my %total;
    $total{$_->category} += $_->amount for @{$self->claims->find_by_employee($employee)};
    return {map { $_ => $self->round_amount($total{$_}, $rule) } sort keys %total};
}

# How many lines an export file has, as the system counts them.
sub export_line_count ($self, $file) {
    my $dir    = $self->export_dir;
    my $output = `wc -l $dir/$file`;
    my ($count) = $output =~ /^\s*(\d+)/;
    return $count // 0;
}

# Writes an employee's claims as a CSV file and returns its line count.
sub export_claims ($self, $employee, $file) {
    my @lines = ('id,employee,category,amount,status');
    for my $claim (@{$self->claims->find_by_employee($employee)}) {
        push @lines, join q{,}, $claim->id, $claim->employee, $claim->category, format_money($claim->amount), $claim->status;
    }

    write_export($self->export_dir . "/$file", \@lines);
    $self->audit(exported => $employee);
    return $self->export_line_count($file);
}

1;
