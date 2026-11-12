package ExpensePortal::Model::Claim;
use Mojo::Base -base, -signatures;

# One expense claim, as a row of the `claims` table.

has [qw(id employee amount)];
has category => 'other';
has status   => 'submitted';

my %KNOWN_CATEGORY = map { $_ => 1 } qw(travel meals lodging equipment other);

# A claim from a database row.
sub from_row ($class, $row) {
    return $class->new(%{$row});
}

# A claim nobody has approved or rejected yet.
sub is_open ($self) {
    return $self->status eq 'submitted';
}

# What is wrong with the claim: an empty list when nothing is.
sub validate ($self) {
    my @errors;
    push @errors, 'employee is required' if !defined $self->employee || $self->employee eq q{};
    push @errors, 'amount must be a positive number'
        if !defined $self->amount || $self->amount !~ /\A\d+(?:\.\d+)?\z/ || $self->amount <= 0;
    push @errors, 'unknown category: ' . $self->category if !$KNOWN_CATEGORY{$self->category};
    return \@errors;
}

sub to_hash ($self) {
    return {
        id       => $self->id,
        employee => $self->employee,
        category => $self->category,
        amount   => $self->amount + 0,
        status   => $self->status,
    };
}

1;
